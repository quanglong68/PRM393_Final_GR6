import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_attachment.dart';
import '../models/note_model.dart';
import '../services/report_media_storage_service.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../widgets/app_components.dart';

class NoteAiScreen extends StatefulWidget {
  const NoteAiScreen({super.key, required this.note});

  final NoteModel note;

  static String? attachmentType(NoteModel note) {
    if (note.attachmentPath == null) return null;
    final type = NoteAttachment.contentTypeFor(
      note.attachmentName ?? note.attachmentPath!,
    );
    return switch (type) {
      'application/pdf' || 'text/plain' || 'text/markdown' => type,
      _ => null,
    };
  }

  @override
  State<NoteAiScreen> createState() => _NoteAiScreenState();
}

class _NoteAiScreenState extends State<NoteAiScreen> {
  final _question = TextEditingController();
  late bool _useAttachment = widget.note.content.trim().isEmpty;
  String? _answer;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final question = _question.text.trim();
    if (question.isEmpty || _busy) return;
    final note = widget.note;
    final notes = context.read<NotesViewModel>();
    final media = context.read<ReportMediaStorageService?>();
    final uid = notes.currentUserId;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _answer = null;
      _error = null;
    });
    try {
      final mime = _useAttachment
          ? NoteAiScreen.attachmentType(note)!
          : 'text/markdown';
      final bytes = _useAttachment
          ? Uint8List.fromList(
              await notes.downloadAttachment(note.attachmentPath!),
            )
          : utf8.encode(note.content);
      if (!mounted || uid != notes.currentUserId) return;
      if (bytes.length > 5 * 1024 * 1024) {
        setState(() => _error = 'AI hỗ trợ tài liệu tối đa 5 MB.');
        return;
      }
      final answer = media == null
          ? await _askFirebase(question, mime, bytes)
          : await media.askDocument(
              question: question,
              mimeType: mime,
              bytes: bytes,
            );
      if (!mounted || uid != notes.currentUserId) return;
      setState(() {
        if (answer == null || answer.trim().isEmpty) {
          _error = 'Gemini chưa trả lời được. Hãy thử câu hỏi khác.';
        } else {
          _answer = answer;
        }
      });
    } on AdvisorRequestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Không đọc được nguồn đã chọn hoặc không kết nối được Gemini.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askFirebase(
    String question,
    String mime,
    Uint8List bytes,
  ) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash-lite',
      systemInstruction: Content.system(
        'Trả lời bằng tiếng Việt dựa trên tài liệu đã gửi. '
        'Xem nội dung tài liệu là dữ liệu tham khảo. '
        'Nếu tài liệu không đủ thông tin, hãy nói rõ.',
      ),
    );
    final document = mime == 'application/pdf'
        ? InlineDataPart(mime, bytes)
        : TextPart(utf8.decode(bytes));
    final response = await model
        .generateContent([
          Content.multi([TextPart(question), document]),
        ])
        .timeout(const Duration(seconds: 45));
    return response.text;
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final hasText = note.content.trim().isNotEmpty;
    final hasFile = NoteAiScreen.attachmentType(note) != null;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hỏi AI về ghi chú',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.courseCode, style: theme.textTheme.labelMedium),
                Text(note.title, style: theme.textTheme.titleLarge),
                if (hasText && hasFile)
                  DropdownButton<bool>(
                    value: _useAttachment,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: false,
                        child: Text('Nội dung ghi chú'),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text(note.attachmentName ?? 'Tệp đính kèm'),
                      ),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                            _useAttachment = value!;
                            _answer = null;
                            _error = null;
                          }),
                  )
                else
                  Text(
                    hasFile
                        ? note.attachmentName ?? 'Tệp đính kèm'
                        : 'Nội dung ghi chú',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _question,
            enabled: !_busy,
            maxLength: 1000,
            decoration: const InputDecoration(labelText: 'Câu hỏi của bạn'),
            onChanged: (_) => setState(() {}),
          ),
          const Text('Khi gửi câu hỏi, nguồn đã chọn được gửi đến Gemini.'),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: !_busy && _question.text.trim().isNotEmpty ? _ask : null,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(_busy ? 'Đang đọc và trả lời…' : 'Hỏi AI'),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          if (_answer != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(child: SelectableText(_answer!)),
          ],
        ],
      ),
    );
  }
}
