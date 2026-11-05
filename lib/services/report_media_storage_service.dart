import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Report-only adapter. The API verifies the Firebase ID token before accessing
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

  Uri _url(String path) {
    if (!_reportPath.hasMatch(path)) {
      throw ArgumentError('Đường dẫn báo cáo không hợp lệ.');
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
      throw StateError('Bạn không có quyền truy cập báo cáo này.');
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
      throw StateError('Dịch vụ PDF trả HTTP ${response.statusCode}.');
    }
  }

  @override
  Future<String> uploadFile(
    String path,
    List<int> bytes, {
    String? contentType,
    void Function(double progress)? onProgress,
  }) => _send('PUT', path, (request) async {
    if (bytes.isEmpty || bytes.length > _maxBytes) {
      throw ArgumentError('Kích thước PDF phải từ 1 byte đến 10 MB.');
    }
    request.headers.contentType = ContentType('application', 'pdf');
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
    return _url(path).toString();
  });

  @override
  Future<List<int>> downloadFile(String path) =>
      _send('GET', path, (request) async {
        final response = await request.close();
        _expect(response, HttpStatus.ok);
        if (response.headers.contentType?.mimeType != 'application/pdf') {
          throw StateError('Máy chủ không trả về PDF.');
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > _maxBytes) {
            throw StateError('PDF vượt giới hạn tải xuống 10 MB.');
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
