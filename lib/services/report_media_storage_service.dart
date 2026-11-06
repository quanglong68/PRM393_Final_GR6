import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/note_attachment.dart';
import 'storage_service.dart';

/// Cloudinary adapter for study reports and note attachments. The API verifies the Firebase ID token before accessing
/// private Cloudinary assets. Student credentials never reach Cloudinary.
class ReportMediaStorageService implements StorageService {
  ReportMediaStorageService(this.baseUri, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance {
    final loopback = baseUri.host == '127.0.0.1';
    final secure = baseUri.scheme == 'https';
    if (baseUri.host.isEmpty ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery ||
        baseUri.hasFragment ||
        (!secure && !(kDebugMode && loopback && baseUri.scheme == 'http'))) {
      throw ArgumentError('REPORT_MEDIA_URL phải dùng HTTPS.');
    }
  }

  final Uri baseUri;
  final FirebaseAuth _auth;
  static const _maxBytes = 10 * 1024 * 1024;
  static final _reportPath = RegExp(
    r'^reports/[A-Za-z0-9_-]{1,128}/study_report_\d{13}\.pdf$',
  );

  static final _notePath = RegExp(
    r'^notes/[A-Za-z0-9_-]{1,128}/cloudinary/note_\d{16}\.[a-z]+$',
  );

  String _contentType(String path) {
    if (_reportPath.hasMatch(path)) return 'application/pdf';
    if (_notePath.hasMatch(path)) {
      final type = NoteAttachment.contentTypeFor(path);
      if (type != null) return type;
    }
    throw ArgumentError('Đường dẫn tệp không hợp lệ.');
  }

  Uri _url(String path) {
    if (!RegExp(r'^advisor/[A-Za-z0-9_-]{1,128}$').hasMatch(path)) {
      _contentType(path);
    }
    return baseUri.replace(
      pathSegments: [
        ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
        'api',
        ...path.split('/'),
      ],
    );
  }

  Future<T> _send<T>(
    String method,
    String path,
    Future<T> Function(HttpClientRequest request) exchange,
  ) async {
    final url = _url(path);
    final user = _auth.currentUser;
    if (user == null || path.split('/')[1] != user.uid) {
      throw StateError('Bạn không có quyền truy cập tệp này.');
    }
    final token = await user.getIdToken().timeout(const Duration(seconds: 15));
    if (token == null || _auth.currentUser?.uid != user.uid) {
      throw StateError('Phiên đăng nhập đã thay đổi.');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.openUrl(method, url);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final result = await exchange(request)
          .timeout(const Duration(seconds: 50));
      if (_auth.currentUser?.uid != user.uid) {
        throw StateError('Phiên đăng nhập đã thay đổi.');
      }
      return result;
    } finally {
      client.close(force: true);
    }
  }

  void _expect(HttpClientResponse response, int status) {
    if (response.statusCode != status) {
      throw StateError('Dịch vụ tệp trả HTTP ${response.statusCode}.');
    }
  }

  Future<String> askAdvisor(
    String uid,
    String question,
    String level,
    String catalog,
  ) => _send('POST', 'advisor/$uid', (request) async {
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({'question': question, 'level': level, 'catalog': catalog}),
    );
    final response = await request.close();
    if (response.statusCode == 503 || response.statusCode == 429) {
      throw AdvisorRequestException(
        response.statusCode == 503
            ? 'Máy chủ demo chưa cấu hình Gemini.'
            : 'Gemini đang giới hạn lượt hỏi. Vui lòng thử lại sau.',
      );
    }
    _expect(response, HttpStatus.ok);
    final data = jsonDecode(await utf8.decoder.bind(response).join());
    if (data case {'answer': final String answer}
        when answer.trim().isNotEmpty) {
      return answer.trim();
    }
    throw StateError('Gemini trả về câu trả lời trống.');
  });

  @override
  Future<String> uploadFile(
    String path,
    List<int> bytes, {
    String? contentType,
    bool createDownloadUrl = true,
    void Function(double progress)? onProgress,
  }) => _send('PUT', path, (request) async {
    final maxSize = _reportPath.hasMatch(path) ? _maxBytes : _maxBytes - 1;
    if (bytes.isEmpty || bytes.length > maxSize) {
      throw ArgumentError('Kích thước tệp không hợp lệ.');
    }
    final expectedType = _contentType(path);
    if (contentType != null && contentType != expectedType) {
      throw ArgumentError('Định dạng tệp không khớp.');
    }
    request.headers.contentType = ContentType.parse(expectedType);
    request.contentLength = bytes.length;
    request.bufferOutput = false;
    final chunkSize = 64 * 1024;
    for (var start = 0; start < bytes.length; start += chunkSize) {
      final end = (start + chunkSize).clamp(0, bytes.length);
      request.add(bytes.sublist(start, end));
      await request.flush();
      onProgress?.call(end / bytes.length * .95);
    }
    final response = await request.close();
    _expect(response, HttpStatus.created);
    await response.drain<void>();
    onProgress?.call(1);
    return createDownloadUrl ? _url(path).toString() : path;
  });

  @override
  Future<List<int>> downloadFile(String path) =>
      _send('GET', path, (request) async {
        final response = await request.close();
        _expect(response, HttpStatus.ok);
        if (response.headers.contentType?.mimeType != _contentType(path)) {
          throw StateError('Máy chủ trả về sai định dạng tệp.');
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > _maxBytes) {
            throw StateError('Tệp vượt giới hạn tải xuống 10 MB.');
          }
          bytes.addAll(chunk);
        }
        return bytes;
      });

  @override
  Future<void> deleteFile(String path) =>
      _send('DELETE', path, (request) async {
        final response = await request.close();
        _expect(response, HttpStatus.noContent);
        await response.drain<void>();
      });

  @override
  Future<String> getDownloadUrl(String path) async => _url(path).toString();
}

class AdvisorRequestException implements Exception {
  const AdvisorRequestException(this.message);

  final String message;
}
