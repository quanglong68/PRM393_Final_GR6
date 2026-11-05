import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/firestore_service.dart';
import '../services/remote_config_service.dart';
import '../services/report_export_service.dart';
import '../services/sync_reload_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../viewmodels/roadmap_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';

class SyncVaultScreen extends StatefulWidget {
  const SyncVaultScreen({super.key});

  @override
  State<SyncVaultScreen> createState() => _SyncVaultScreenState();
}

class _SyncVaultScreenState extends State<SyncVaultScreen> {
  bool _isTestingFirestore = false;
  String? _firestoreTestResult;
  bool _isTestingCrashlytics = false;
  String? _crashlyticsResult;
  bool _isSyncing = false;
  String? _syncResult;

  // ── PDF export state (Lab 3 §6.5) ──
  bool _isExporting = false;
  bool _isDownloadingReport = false;
  double _exportProgress = 0.0;
  ReportExportResult? _exportResult;
  String? _exportError;
  Uint8List? _localPdfBytes;
  String? _localPdfName;
  bool _isLocalExport = false;

  Future<void> _testFirestore(FirestoreService firestore, String? uid) async {
    setState(() {
      _isTestingFirestore = true;
      _firestoreTestResult = null;
    });

    if (uid == null || uid.isEmpty) {
      // Never write under a fabricated identity when unauthenticated.
      setState(() {
        _firestoreTestResult =
            'Chưa đăng nhập — không thể chạy test đọc/ghi Firestore.';
      });
      _isTestingFirestore = false;
      return;
    }

    try {
      final testTask = {
        'title': 'Test Sync Roundtrip ${DateTime.now().second}',
        'courseCode': 'PRM323',
        'dueDate': '15/12/2024',
        'userId': uid,
      };
      await firestore.addTask(testTask);
      final tasks = await firestore.getTasks(uid);

      setState(() {
        _firestoreTestResult =
            'Thành công! Firestore đã đọc/ghi ${tasks.length} mục.';
      });
    } catch (e) {
      setState(() {
        _firestoreTestResult = 'Lỗi test Firestore: $e';
      });
    } finally {
      setState(() => _isTestingFirestore = false);
    }
  }

  Future<void> _testCrashlytics(CrashlyticsService crashlytics) async {
    setState(() {
      _isTestingCrashlytics = true;
      _crashlyticsResult = null;
    });

    try {
      await crashlytics.enableCollection();
      await crashlytics.log(
        'Người dùng kích hoạt test Crashlytics từ Firebase Demo Area',
      );
      await crashlytics.recordError(
        Exception('Non-fatal test exception từ FPTU Second Brain Demo Area'),
        StackTrace.current,
        reason: 'Firebase Demo Area manual test trigger',
      );

      setState(() {
        _crashlyticsResult =
            'Đã gửi non-fatal tới SDK. Kiểm tra kết quả trên Dashboard.';
      });
    } catch (e) {
      setState(() {
        _crashlyticsResult = 'Lỗi Crashlytics: $e';
      });
    } finally {
      setState(() => _isTestingCrashlytics = false);
    }
  }

  Future<void> _confirmTestCrash(CrashlyticsService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gây crash thử nghiệm?'),
        content: const Text(
          'Ứng dụng sẽ đóng. Mở lại app để gửi báo cáo Crashlytics. Hãy lưu nội dung đang soạn trước.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gây test crash'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await service.setCustomKey('test_action', 'manual_crash');
      await service.testCrash();
    } catch (e) {
      if (mounted) {
        setState(() => _crashlyticsResult = 'Không thể gây test crash: $e');
      }
    }
  }

  Future<void> _triggerManualSync(AnalyticsService analytics) async {
    setState(() {
      _isSyncing = true;
      _syncResult = null;
    });

    try {
      final uid = context.read<AuthViewModel>().currentUserId;
      if (uid == null || uid.isEmpty) {
        throw StateError('Chưa đăng nhập — không thể đồng bộ.');
      }

      final result = await const SyncReloadService().reload(
        roadmap: context.read<RoadmapViewModel>(),
        tasks: context.read<TasksViewModel>(),
        notes: context.read<NotesViewModel>(),
      );
      if (!result.succeeded) {
        throw StateError(result.errorMessage!);
      }

      await analytics.logSyncTriggered(triggerType: 'manual_button');

      if (!mounted) return;
      setState(() {
        _syncResult =
            'Đã tải lại dữ liệu Cloud Firestore lúc '
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncResult = 'Đồng bộ thất bại: $e';
      });
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // ──────────────────────── PDF Export & Upload (Lab 3 §6.5) ────────────────────────

  /// Share-consent dialog shown BEFORE any file leaves the device.
  /// The user must explicitly allow the upload; cancelling aborts everything.
  Future<bool> _askExportConsent({
    required int taskCount,
    required int noteCount,
    required int courseCount,
    bool uploadToCloud = true,
    required String storageProvider,
  }) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.ios_share),
        title: Text(
          uploadToCloud ? 'Chia sẻ báo cáo học tập?' : 'Tạo PDF trên thiết bị?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              uploadToCloud
                  ? 'Ứng dụng sẽ tạo PDF từ dữ liệu đang hiển thị và tải lên $storageProvider (đường dẫn reports/{uid}/…).'
                  : 'Ứng dụng sẽ tạo PDF trên thiết bị. Bạn tự chọn ứng dụng nhận file trong menu chia sẻ hệ thống.',
              style: const TextStyle(fontSize: AppFontSize.dense),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Nội dung: $courseCount môn học, $taskCount việc cần làm, '
              '$noteCount ghi chú. Không kèm email/họ tên/SĐT.',
              style: const TextStyle(
                fontSize: AppFontSize.label,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              uploadToCloud
                  ? 'Metadata báo cáo được lưu dưới tài khoản của bạn.'
                  : 'Chỉ chia sẻ khi bạn chọn nơi nhận. Luồng này không upload Firebase Storage.',
              style: const TextStyle(
                fontSize: AppFontSize.label,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, size: 18),
            label: Text(uploadToCloud ? 'Đồng ý xuất & tải' : 'Đồng ý tạo PDF'),
          ),
        ],
      ),
    );
    return agreed ?? false;
  }

  Future<void> _exportAndUploadReport(
    ReportExportService exporter,
    String? uid, {
    bool localOnly = false,
  }) async {
    if (_isExporting || _isDownloadingReport) return;
    if (uid == null || uid.isEmpty) {
      setState(
        () => _exportError = 'Chưa đăng nhập — không thể xuất báo cáo cá nhân.',
      );
      return;
    }

    // Snapshot the SAME data currently displayed (guide v5 §6.5). Each screen
    // keeps its own VM alive, so refresh them first, then read the lists.
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportResult = null;
      _exportError = null;
      _localPdfBytes = null;
      _localPdfName = null;
      _isLocalExport = localOnly;
    });

    List<CourseModel> courses;
    List<TaskModel> tasks;
    List<NoteModel> notes;
    try {
      final roadmapVm = context.read<RoadmapViewModel>();
      final tasksVm = context.read<TasksViewModel>();
      final notesVm = context.read<NotesViewModel>();
      final reload = await const SyncReloadService().reload(
        roadmap: roadmapVm,
        tasks: tasksVm,
        notes: notesVm,
      );
      if (!reload.succeeded) throw StateError(reload.errorMessage!);
      if (!mounted) return;
      if (context.read<AuthViewModel>().currentUserId != uid) {
        throw StateError("Phiên đăng nhập đã thay đổi.");
      }
      courses = roadmapVm.allCourses;
      tasks = tasksVm.allTasks;
      notes = notesVm.allNotes;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _exportError = 'Không tải được dữ liệu để xuất: $e';
      });
      return;
    }

    if (!mounted) return;
    if (!await _askExportConsent(
      courseCount: courses.length,
      taskCount: tasks.length,
      noteCount: notes.length,
      uploadToCloud: !localOnly,
      storageProvider: exporter.storageProvider,
    )) {
      if (mounted) setState(() => _isExporting = false);
      return; // consent is mandatory before any upload
    }

    if (!mounted) return;
    if (context.read<AuthViewModel>().currentUserId != uid) {
      setState(() {
        _isExporting = false;
        _exportError = "Phiên đăng nhập đã thay đổi. Vui lòng xuất lại.";
      });
      return;
    }
    try {
      if (localOnly) {
        final generatedAt = DateTime.now();
        final bytes = await exporter.generateLocalStudyReport(
          userId: uid,
          courses: courses,
          tasks: tasks,
          notes: notes,
          generatedAt: generatedAt,
        );
        if (!mounted || context.read<AuthViewModel>().currentUserId != uid) {
          return;
        }
        setState(() {
          _localPdfBytes = bytes;
          _localPdfName =
              'study_report_${generatedAt.millisecondsSinceEpoch}.pdf';
        });
        try {
          await context.read<AnalyticsService>().logEvent(
            'export_report_local',
            parameters: {
              'file_size_kb': (bytes.length / 1024).ceil(),
              'course_count': courses.length,
              'task_count': tasks.length,
              'note_count': notes.length,
            },
          );
        } catch (_) {
          // A diagnostics failure must not discard the generated PDF.
        }
        return;
      }
      final result = await exporter.exportStudyReport(
        userId: uid,
        courses: courses,
        tasks: tasks,
        notes: notes,
        onProgress: (p) {
          if (mounted) setState(() => _exportProgress = p);
        },
      );
      if (mounted) setState(() => _exportResult = result);
    } catch (e) {
      if (mounted) setState(() => _exportError = 'Xuất báo cáo thất bại: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Opens the OS print/share sheet with the just-generated PDF in memory.
  Future<void> _openLastReport() async {
    final bytes = _exportResult?.pdfBytes ?? _localPdfBytes;
    if (bytes == null) return;
    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: _exportResult?.storagePath.split('/').last ?? _localPdfName!,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _exportError =
              'Không mở được menu chia sẻ PDF. Vui lòng thử lại.',
        );
      }
    }
  }

  Future<void> _downloadLastReport(ReportExportService exporter) async {
    final report = _exportResult;
    final uid = context.read<AuthViewModel>().currentUserId;
    if (report == null || uid == null || _isDownloadingReport || _isExporting) {
      return;
    }
    setState(() {
      _isDownloadingReport = true;
      _exportError = null;
    });
    try {
      final bytes = await exporter.downloadStudyReport(report.storagePath);
      if (!mounted || context.read<AuthViewModel>().currentUserId != uid) {
        return;
      }
      await Printing.sharePdf(
        bytes: bytes,
        filename: report.storagePath.split('/').last,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _exportError = 'Không mở được bản PDF từ cloud.');
      }
    } finally {
      if (mounted) setState(() => _isDownloadingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final remoteConfig = context.watch<RemoteConfigService>();
    final firestore = context.watch<FirestoreService>();
    final crashlytics = context.watch<CrashlyticsService>();
    final analytics = context.watch<AnalyticsService>();
    final reportExporter = context.read<ReportExportService>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Sync Vault & Cài đặt',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // User Profile Card — live sign-in identity only (no persona data)
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    (authVm.currentUserEmail ?? '?').characters.first
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: AppFontSize.displayMedium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authVm.isAuthenticated
                            ? (authVm.currentUserEmail?.split('@').first ??
                                  'Người dùng')
                            : 'Chưa đăng nhập',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.hairline),
                      Text(
                        authVm.currentUserEmail ??
                            'Vui lòng đăng nhập bằng tài khoản Google',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.hairline),
                      const Text(
                        'Dữ liệu đồng bộ theo UID Firebase của bạn',
                        style: TextStyle(
                          fontSize: AppFontSize.label,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Offline Vault Sync Status Card
          Text(
            'Trạng thái Vault & Đồng bộ',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.cloud_done_outlined,
                    color: AppColors.success,
                  ),
                  title: Text('Đồng bộ Cloud Firestore'),
                  subtitle: Text(
                    'Offline persistence: Hoạt động (Unlimited cache)',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.folder_shared_outlined,
                    color: AppColors.secondary,
                  ),
                  title: Text('Cloud Storage Vault'),
                  subtitle: Text('Đường dẫn: notes/{uid}/... (Max 10MB)'),
                ),
                if (_syncResult != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _syncResult!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Kích hoạt đồng bộ Vault ngay',
                  icon: Icons.sync,
                  isLoading: _isSyncing,
                  isExpanded: true,
                  onPressed: () => _triggerManualSync(analytics),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Firebase Demo Area (Lab 3 Requirement)
          Text(
            'Firebase Demo Area (PRM323 Lab 3)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Khu vực kiểm thử tính năng của đề bài Lab 3: Remote Config, Crashlytics, Firestore read/write.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Remote Config Parameters Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Firebase Remote Config',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Tải lại config',
                      onPressed: () async {
                        await remoteConfig.fetchAndActivate();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              remoteConfig.lastFetchError ??
                                  'Đã tải cấu hình hiện hành từ Firebase.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.xs),
                _buildConfigRow(
                  'maintenance_mode',
                  remoteConfig.isMaintenanceMode.toString(),
                ),
                _buildConfigRow(
                  'feature_ai_advisor_enabled',
                  remoteConfig.isAiAdvisorEnabled.toString(),
                ),
                _buildConfigRow('min_app_version', remoteConfig.minAppVersion),
                _buildConfigRow(
                  'vault_sync_interval_mins',
                  '${remoteConfig.vaultSyncIntervalMins} phút',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Crashlytics Test Trigger
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firebase Crashlytics Test',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                const Text(
                  'Ghi nhận non-fatal exception và breadcrumb log lên dashboard Crashlytics mà không làm crash ứng dụng.',
                  style: TextStyle(
                    fontSize: AppFontSize.label,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (_crashlyticsResult != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _crashlyticsResult!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: AppFontSize.label,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _isTestingCrashlytics
                      ? null
                      : () => _testCrashlytics(crashlytics),
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text('Ghi nhận Test Exception vào Crashlytics'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _confirmTestCrash(crashlytics),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Gây test crash (đóng ứng dụng)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Firestore Read/Write Roundtrip Test
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Firestore Read/Write Test',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                const Text(
                  'Kiểm tra đọc và ghi dữ liệu mẫu qua FirestoreService (áp dụng Offline Persistence).',
                  style: TextStyle(
                    fontSize: AppFontSize.label,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (_firestoreTestResult != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _firestoreTestResult!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: AppFontSize.label,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _isTestingFirestore
                      ? null
                      : () => _testFirestore(firestore, authVm.currentUserId),
                  icon: const Icon(Icons.cloud_sync_outlined),
                  label: const Text('Chạy Test Đọc/Ghi Firestore'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // PDF Export & Upload (Lab 3 Requirement §6.5)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export & Upload PDF',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Tạo PDF từ lộ trình, việc cần làm và ghi chú. '
                  'Bạn có thể chia sẻ từ thiết bị hoặc chọn tải lên '
                  '${reportExporter.storageProvider} cùng metadata Firestore.',
                  style: const TextStyle(
                    fontSize: AppFontSize.label,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (_isExporting) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: LinearProgressIndicator(
                      value: _exportProgress > 0 ? _exportProgress : null,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _exportProgress > 0
                        ? 'Đang tải lên… ${(_exportProgress * 100).toStringAsFixed(0)}%'
                        : 'Đang tạo PDF…',
                    style: const TextStyle(fontSize: AppFontSize.label),
                  ),
                ],
                if (_exportError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          _exportError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: AppFontSize.label,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isExporting
                            ? null
                            : () => _exportAndUploadReport(
                                reportExporter,
                                authVm.currentUserId,
                              ),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ],
                if (_exportResult != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Hoàn tất! Kích thước ${(_exportResult!.bytes / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: AppFontSize.label,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  SelectableText(
                    _exportResult!.downloadUrl,
                    style: const TextStyle(fontSize: AppFontSize.caption),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Đường dẫn: ${_exportResult!.storagePath}',
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                AppOutlinedButton(
                  label: _isExporting && _isLocalExport
                      ? 'Đang tạo PDF…'
                      : 'Tạo PDF trên thiết bị',
                  icon: Icons.picture_as_pdf_outlined,
                  isExpanded: true,
                  onPressed: _isExporting
                      ? null
                      : () => _exportAndUploadReport(
                          reportExporter,
                          authVm.currentUserId,
                          localOnly: true,
                        ),
                ),
                if (_localPdfBytes != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Đã tạo PDF trên thiết bị (${(_localPdfBytes!.length / 1024).toStringAsFixed(1)} KB). Chưa upload cloud.',
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  label: _exportResult == null
                      ? reportExporter.storageProvider ==
                                'Firebase Cloud Storage'
                            ? 'Xuất & Tải PDF lên Cloud Storage'
                            : 'Xuất & Tải PDF lên ${reportExporter.storageProvider}'
                      : 'Xuất báo cáo mới',
                  icon: Icons.picture_as_pdf_outlined,
                  isLoading: _isExporting && !_isLocalExport,
                  isExpanded: true,
                  onPressed: _isExporting
                      ? null
                      : () => _exportAndUploadReport(
                          reportExporter,
                          authVm.currentUserId,
                        ),
                ),
                if (_exportResult != null)
                  TextButton.icon(
                    onPressed: _isDownloadingReport || _isExporting
                        ? null
                        : () => _downloadLastReport(reportExporter),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(
                      _isDownloadingReport
                          ? 'Đang tải PDF…'
                          : 'Tải lại PDF từ cloud',
                    ),
                  ),
                if (_exportResult != null || _localPdfBytes != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isExporting || _isDownloadingReport
                              ? null
                              : _openLastReport,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Mở / Chia sẻ file'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String key, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          key,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: AppFontSize.label,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.micro,
            vertical: AppSpacing.hairline,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.caption,
            ),
          ),
        ),
      ],
    ),
  );
}
