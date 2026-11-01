import 'package:prm323_lab3/services/storage_service.dart';

/// Test double for [StorageService] — records uploads, supports failures,
/// and exercises the progress callback like the real Firebase upload does.
class FakeStorageService implements StorageService {
  final List<Map<String, dynamic>> uploads = [];

  bool shouldFailUpload = false;
  String? downloadUrlToReturn;

  /// Progress fractions to emit before completion (default: mid + done).
  List<double> progressSteps = const [0.5, 1.0];

  @override
  Future<String> uploadFile(
    String path,
    List<int> bytes, {
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    if (shouldFailUpload) {
      throw Exception('Simulated storage upload failure');
    }
    uploads.add({
      'path': path,
      'size': bytes.length,
      'contentType': contentType,
    });
    for (final p in progressSteps) {
      onProgress?.call(p);
    }
    return downloadUrlToReturn ?? 'https://fake.storage/$path';
  }

  @override
  Future<List<int>> downloadFile(String path) async => const [];

  @override
  Future<void> deleteFile(String path) async {}

  @override
  Future<String> getDownloadUrl(String path) async =>
      downloadUrlToReturn ?? 'https://fake.storage/$path';
}
