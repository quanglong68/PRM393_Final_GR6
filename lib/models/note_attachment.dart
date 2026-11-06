abstract final class NoteAttachment {
  static const maxBytesExclusive = 10 * 1024 * 1024;
  static const supportedFormats = 'PDF, Markdown, DOCX, TXT, PNG, JPG';

  static const _contentTypes = {
    'pdf': 'application/pdf',
    'md': 'text/markdown',
    'markdown': 'text/markdown',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'txt': 'text/plain',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
  };

  static String? contentTypeFor(String fileName) =>
      _contentTypes[fileName.split('.').last.toLowerCase()];

  static String safeFileName(String fileName) =>
      fileName.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();

  static String? validationError(String fileName, int? size) {
    if (size != null && size <= 0) return 'Tệp rỗng — không thể tải lên.';
    if (size != null && size >= maxBytesExclusive) {
      return 'Tệp phải nhỏ hơn 10 MB.';
    }
    if (!fileName.contains('.') || contentTypeFor(fileName) == null) {
      return 'Chỉ hỗ trợ $supportedFormats.';
    }
    return null;
  }
}
