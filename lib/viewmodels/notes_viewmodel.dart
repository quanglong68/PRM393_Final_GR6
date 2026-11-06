import 'dart:async';

import '../models/app_state.dart';
import '../models/note_attachment.dart';
import '../models/note_model.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'base_viewmodel.dart';

class NotesViewModel extends BaseViewModel<List<NoteModel>> {
  NotesViewModel({
    this.authService,
    this.firestoreService,
    this.storageService,
    this.mediaStorageService,
    this.analyticsService,
  }) {
    loadData();
    // Identity switch = note list rebuild — logout never leaves the previous
    // user's notes visible (Lab 3 §5.2). See TasksViewModel for the same rule.
    _authSub = authService?.authStateChanges.listen((_) {
      if (currentUserId != _loadedUid) {
        _searchQuery = "";
        _isSaving = false;
        clearLastError();
        loadData();
      }
    });
  }

  final AuthService? authService;
  final FirestoreService? firestoreService;
  final StorageService? storageService;
  final StorageService? mediaStorageService;
  final AnalyticsService? analyticsService;
  StreamSubscription<bool>? _authSub;
  int _loadVersion = 0;
  String? _loadedUid;

  /// Authenticated UID, or null when no identity is available. Used for all
  /// user-owned reads/writes; never falls back to a persona ID or constant.
  String? get currentUserId {
    final uid = authService?.currentUserId;
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  List<NoteModel> _allNotes = [];
  String _searchQuery = '';

  String get searchQuery => _searchQuery;
  List<NoteModel> get allNotes => List.unmodifiable(_allNotes);

  List<NoteModel> get filteredNotes {
    if (_searchQuery.isEmpty) return List.unmodifiable(_allNotes);
    final q = _searchQuery.toLowerCase();
    return _allNotes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q) ||
          n.courseCode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<void> loadData() async {
    if (isDisposed) return;
    final version = ++_loadVersion;
    final uid = currentUserId;
    setState(const AsyncViewState.loading());

    try {
      final firestore = firestoreService;
      _loadedUid = uid;
      if (firestore == null || uid == null) {
        // No backend / no identity: empty state — never seeded mock notes.
        _allNotes = [];
        setState(const AsyncViewState.empty());
        return;
      }
      final docs = await firestore.getNotes(uid);
      if (isDisposed || version != _loadVersion || uid != currentUserId) return;
      _allNotes = docs.map(NoteModel.fromMap).toList();

      if (_allNotes.isEmpty) {
        setState(const AsyncViewState.empty());
      } else {
        setState(AsyncViewState.data(filteredNotes));
      }
    } catch (e) {
      if (isDisposed || version != _loadVersion || uid != currentUserId) return;
      setState(AsyncViewState.error('Không thể tải danh sách ghi chú: $e'));
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    setState(AsyncViewState.data(filteredNotes));
  }

  NoteModel? findNoteById(String noteId) {
    try {
      return _allNotes.firstWhere((n) => n.id == noteId);
    } catch (_) {
      return null;
    }
  }

  /// Returns the owner-scoped object path after Storage accepts the file.
  Future<String?> uploadAttachment({
    required String fileName,
    required List<int> bytes,
    void Function(double progress)? onProgress,
  }) async {
    final storage = mediaStorageService ?? storageService;
    final uid = currentUserId;
    if (storage == null || uid == null) {
      setLastError('Hãy đăng nhập và kết nối Cloud Storage để tải tệp lên.');
      return null;
    }
    final error = NoteAttachment.validationError(fileName, bytes.length);
    if (error != null) {
      setLastError(error);
      return null;
    }

    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final extension = fileName.split('.').last.toLowerCase();
    final path = mediaStorageService == null
        ? 'notes/$uid/${stamp}_$safeName'
        : 'notes/$uid/cloudinary/note_$stamp.$extension';
    try {
      await storage.uploadFile(
        path,
        bytes,
        contentType: NoteAttachment.contentTypeFor(fileName),
        createDownloadUrl: false,
        onProgress: onProgress,
      );
      if (isDisposed || uid != currentUserId) return null;
      clearLastError();
      return path;
    } catch (_) {
      if (!isDisposed && uid == currentUserId) {
        setLastError(
          'Tải tệp lên thất bại. Kiểm tra Cloud Storage và thử lại.',
        );
      }
      return null;
    }
  }

  Future<List<int>> downloadAttachment(String path) async {
    final uid = currentUserId;
    if (uid == null || !path.startsWith('notes/$uid/')) {
      throw StateError('Bạn không có quyền tải tệp này.');
    }
    final storage = path.startsWith('notes/$uid/cloudinary/')
        ? mediaStorageService
        : storageService;
    if (storage == null) {
      throw StateError('Dịch vụ tải tệp chưa được cấu hình.');
    }
    final bytes = await storage.downloadFile(path);
    if (isDisposed || uid != currentUserId || bytes.isEmpty) {
      throw StateError('Không thể đọc tệp đính kèm.');
    }
    return bytes;
  }

  Future<bool> removeObsoleteAttachment(String path) async {
    final uid = currentUserId;
    if (uid == null || !path.startsWith('notes/$uid/')) return false;
    final storage = path.startsWith('notes/$uid/cloudinary/')
        ? mediaStorageService
        : storageService;
    if (storage == null) return false;
    try {
      await storage.deleteFile(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Saves a note and persists it. Returns true on success; on failure the
  /// optimistic local change is reverted, [lastError] is set, and false is
  /// returned so the editor never shows success for a failed save.
  Future<bool> saveNote({
    String? id,
    required String title,
    required String content,
    required String courseCode,
    String? attachmentUrl,
    String? attachmentPath,
    String? attachmentName,
    (String?, String?)? attachmentBefore,
    bool preserveAttachment = false,
    List<String> tags = const [],
  }) async {
    if (_isSaving) return false;
    final uid = currentUserId;
    if (firestoreService != null && uid == null) {
      setLastError('Bạn chưa đăng nhập — không thể lưu ghi chú.');
      return false;
    }

    final isNew = id == null || id.isEmpty;
    final noteId = isNew ? 'note_${DateTime.now().millisecondsSinceEpoch}' : id;

    final note = NoteModel(
      id: noteId,
      title: title,
      content: content,
      courseCode: courseCode,
      updatedAt: 'Vừa xong',
      attachmentUrl: attachmentUrl,
      attachmentPath: attachmentPath,
      attachmentName: attachmentName,
      tags: tags,
    );

    // Capture the previous state so a failed write can be reverted exactly.
    final oldIndex = isNew ? -1 : _allNotes.indexWhere((n) => n.id == id);
    final oldNote = oldIndex != -1 ? _allNotes[oldIndex] : null;

    if (isNew) {
      _allNotes.insert(0, note);
    } else if (oldIndex != -1) {
      _allNotes[oldIndex] = note;
    } else {
      _allNotes.insert(0, note);
    }
    setState(AsyncViewState.data(filteredNotes));

    var attachmentRemoved = true;
    final firestore = firestoreService;
    if (firestore != null) {
      _isSaving = true;
      notifyListeners();
      try {
        await firestore.saveNote(
          {...note.toMap(), 'userId': uid!},
          attachmentBefore: attachmentBefore,
          preserveAttachment: preserveAttachment,
        );
        final oldPath = attachmentBefore?.$1;
        if (oldPath != null && oldPath != attachmentPath) {
          attachmentRemoved = await removeObsoleteAttachment(oldPath);
        }
      } catch (e) {
        if (isDisposed || uid != currentUserId) return false;
        if (isNew) {
          _allNotes.removeWhere((n) => n.id == noteId);
        } else if (oldNote != null) {
          final restoreIndex = _allNotes.indexWhere((n) => n.id == noteId);
          if (restoreIndex != -1) _allNotes[restoreIndex] = oldNote;
        } else {
          _allNotes.removeWhere((n) => n.id == noteId);
        }
        setState(AsyncViewState.data(filteredNotes));
        setLastError(
          attachmentBefore == null
              ? 'Không thể lưu ghi chú. Kiểm tra kết nối và thử lại.'
              : 'Không thể cập nhật tệp. Kiểm tra kết nối và mở lại ghi chú.',
        );
        return false;
      } finally {
        if (uid == currentUserId) {
          _isSaving = false;
          notifyListeners();
        }
      }
    }
    if (isDisposed || uid != currentUserId) return false;
    if (attachmentRemoved) {
      clearLastError();
    } else {
      setLastError(
        'Đã lưu ghi chú, nhưng chưa xóa được tệp cũ khỏi kho lưu trữ.',
      );
    }

    analyticsService?.logNoteCreate(contentLength: content.length);
    return true;
  }

  /// Deletes a note through the service. On failure the item is restored to
  /// the list, [lastError] is set, and false is returned so the UI never
  /// reports a delete that did not happen.
  Future<bool> deleteNote(String noteId) async {
    final uid = currentUserId;
    if (firestoreService != null && uid == null) {
      setLastError('Bạn chưa đăng nhập — không thể xóa ghi chú.');
      return false;
    }

    final index = _allNotes.indexWhere((n) => n.id == noteId);
    if (index == -1) return false;
    final removed = _allNotes[index];
    _allNotes.removeAt(index);
    setState(AsyncViewState.data(filteredNotes));

    final firestore = firestoreService;
    if (firestore != null) {
      try {
        await firestore.deleteNote(uid!, noteId);
      } catch (e) {
        if (isDisposed || uid != currentUserId) return false;
        if (!_allNotes.any((n) => n.id == noteId)) {
          _allNotes.insert(index.clamp(0, _allNotes.length), removed);
        }
        setState(AsyncViewState.data(filteredNotes));
        setLastError('Không thể xóa ghi chú. Kiểm tra kết nối và thử lại.');
        return false;
      }
    }
    if (isDisposed || uid != currentUserId) return false;
    clearLastError();
    return true;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
