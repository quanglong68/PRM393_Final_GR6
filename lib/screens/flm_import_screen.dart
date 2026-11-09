import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/note_draft.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_components.dart';

class FlmImportScreen extends StatefulWidget {
  const FlmImportScreen({super.key});

  @override
  State<FlmImportScreen> createState() => _FlmImportScreenState();
}

class _FlmImportScreenState extends State<FlmImportScreen> {
  static final _catalog = Uri.https(
    'flm.fpt.edu.vn',
    '/gui/role/guest/ListCurriculum',
    {'educationLevel': 'fptu'},
  );
  static const _readSyllabus = r'''
(() => {
  if (location.origin !== 'https://flm.fpt.edu.vn') return null;
  const sections = {
    gvLO: 'Chuẩn đầu ra', gvMaterial: 'Tài liệu học tập',
    gvAssessment: 'Đánh giá', gvCQ: 'Câu hỏi định hướng',
    gvSchedule: 'Lịch học theo buổi'
  };
  const clean = node => node.innerText.replace(/\s+/g, ' ').trim();
  const overview = [];
  let course = '';
  let name = '';
  for (const row of document.querySelectorAll('tr')) {
    if (row.cells.length !== 2 || Object.hasOwn(sections, row.closest('table')?.id)) continue;
    const label = clean(row.cells[0]).replace(/:$/, '').toLowerCase();
    const value = clean(row.cells[1]);
    if (!value) continue;
    if (/^(subject|course) code$|^mã môn/.test(label)) course = value;
    if (/^(subject|course|syllabus) name$|^tên môn/.test(label)) name = value;
    if (/^(credits?|description|prerequisite)|^số tín chỉ|^mô tả/.test(label)) {
      overview.push('- **' + clean(row.cells[0]) + '** ' + value);
    }
  }
  const lines = [];
  for (const [id, title] of Object.entries(sections)) {
    const table = document.getElementById(id);
    if (!table?.rows) continue;
    const headers = Array.from(table.rows).find(row =>
      Array.from(row.cells).some(cell => cell.tagName === 'TH'));
    const labels = headers ? Array.from(headers.cells, clean) : [];
    const entries = [];
    for (const row of table.rows) {
      if (row === headers || row.cells.length < 2) continue;
      const fields = Array.from(row.cells, clean).flatMap((value, i) => value
        ? [(labels[i] ? '**' + labels[i] + '** ' : '') + value]
        : []);
      if (fields.length > 1) entries.push('- ' + fields.join(' · '));
    }
    if (entries.length) lines.push('## ' + title + '\n\n' + entries.join('\n'));
  }
  if (!lines.length) return null;
  const id = new URL(location.href).searchParams.get('sylID');
  const source = location.origin + location.pathname +
    (id && /^\d+$/.test(id) ? '?sylID=' + id : '');
  const content = [
    '[Nguồn syllabus trên FLM](' + source + ')',
    ...(overview.length ? ['## Tổng quan\n\n' + overview.join('\n')] : []),
    ...lines,
    // Như file vault Obsidian: chừa sẵn chỗ ghi chú riêng ở cuối syllabus.
    '---',
    '## Ghi chú cá nhân'].join('\n\n');
  return JSON.stringify({course, name, content});
})()
''';

  late final WebViewController _web;
  int _progress = 0;
  bool _reading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              Uri.tryParse(request.url)?.scheme == 'https'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onPageStarted: (_) {
            if (mounted) setState(() => _error = null);
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() => _error = 'Không tải được FLM. Hãy thử mở lại.');
            }
          },
        ),
      )
      ..loadRequest(_catalog);
  }

  Future<void> _import() async {
    setState(() {
      _reading = true;
      _error = null;
    });
    try {
      final result = await _web.runJavaScriptReturningResult(_readSyllabus);
      Object? data = jsonDecode(result.toString());
      if (data is String) data = jsonDecode(data);
      if (!mounted) return;
      if (data is! Map<String, dynamic>) {
        setState(
          () => _error = 'Mở trang chi tiết syllabus của một môn trước.',
        );
        return;
      }
      final course = (data['course'] as String).trim();
      final name = (data['name'] as String).trim();
      final content = data['content'] as String;
      if (utf8.encode(content).length > 400 * 1024) {
        setState(() => _error = 'Syllabus vượt dung lượng của một ghi chú.');
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        '/note-editor',
        arguments: NoteDraft(
          title: name.isNotEmpty
              ? name
              : course.isNotEmpty
              ? 'Syllabus $course'
              : 'Syllabus FLM',
          courseCode: course,
          content: content,
          fromFlm: true,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không đọc được syllabus trên trang hiện tại.');
      }
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: CustomAppBar(
      title: 'Nhập syllabus FLM',
      onBack: () => Navigator.of(context).pop(),
      actions: [
        IconButton(
          tooltip: 'Trang FLM trước',
          icon: const Icon(Icons.chevron_left),
          onPressed: () async {
            if (await _web.canGoBack()) await _web.goBack();
          },
        ),
        IconButton(
          tooltip: 'Mở lại danh mục FLM',
          icon: const Icon(Icons.refresh),
          onPressed: () => _web.loadRequest(_catalog),
        ),
      ],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Text(
            'Chọn môn và mở syllabus. Xác minh khách trên FLM nếu được yêu cầu.',
          ),
        ),
        if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
        Expanded(child: WebViewWidget(controller: _web)),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              if (_error != null) Text(_error!),
              FilledButton.icon(
                onPressed: _reading || _progress < 100 ? null : _import,
                icon: const Icon(Icons.download_for_offline_outlined),
                label: const Text('Nhập thành ghi chú'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
