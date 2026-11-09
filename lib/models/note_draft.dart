class NoteDraft {
  const NoteDraft({
    this.title = '',
    this.courseCode = '',
    this.content = '',
    this.fromFlm = false,
    this.pickAttachment = false,
  });

  final String title;
  final String courseCode;
  final String content;
  final bool fromFlm;
  final bool pickAttachment;
}
