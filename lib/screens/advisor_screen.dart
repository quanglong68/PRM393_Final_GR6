import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/advisor_viewmodel.dart';
import '../widgets/app_components.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _contextLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contextLoaded) return;
    _contextLoaded = true;
    final course = ModalRoute.of(context)?.settings.arguments;
    if (course is String && course.isNotEmpty) {
      _inputController.text = 'Tư vấn môn $course';
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Share consent (rubric §6.4): shown before the first question. Returns
  /// false when the user declines — the question is then not sent at all.
  Future<bool> _askConsent() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chia sẻ dữ liệu hỏi đáp'),
        content: const Text(
          'Câu hỏi của bạn và cấp tư vấn đang chọn (môn học / kỳ học / '
          'chương trình / điểm số) sẽ được dùng để tạo câu trả lời và ghi một '
          'sự kiện ẩn danh vào Firebase Analytics.\n\n'
          'Không gửi: tên, email, mã số sinh viên, bảng điểm thật hay nội dung '
          'ghi chú cá nhân. Câu trả lời hiện được tổng hợp từ bộ quy tắc học vụ '
          'trong app, không phải từ mô hình AI trực tuyến.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không gửi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý và gửi'),
          ),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<void> _sendMessage(AdvisorViewModel vm, String text) async {
    if (text.trim().isEmpty) return;

    if (!vm.hasConsent) {
      final ok = await _askConsent();
      if (!ok) return;
      vm.grantConsent();
    }

    vm.askQuestion(text.trim(), level: vm.selectedLevel);
    _inputController.clear();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final advisorVm = context.watch<AdvisorViewModel>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cố vấn học tập',
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Dữ liệu học tập',
            onPressed: () => Navigator.pushNamed(context, '/academic-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Mô phỏng GPA',
            onPressed: () {
              advisorVm.logStrategyOpened();
              Navigator.pushNamed(context, '/strategy-sim');
            },
          ),
        ],
      ),
      body: !advisorVm.isAiEnabled
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.construction_outlined,
                      size: 64,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Tính năng đang bảo trì',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Tính năng Cố vấn học tập tạm thời ngừng phục vụ theo cấu hình từ xa (Firebase Remote Config).',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Top Banner: Link to GPA Simulation
                Container(
                  color: AppColors.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Expanded(
                        child: Text(
                          'Mốc Sinh viên Giỏi: GPA tích lũy ≥ 8.0',
                          style: TextStyle(
                            fontSize: AppFontSize.label,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/strategy-sim'),
                        child: const Text('Mô phỏng →'),
                      ),
                    ],
                  ),
                ),

                // Consultation level selector (rubric §6.4 — 4 levels)
                Semantics(
                  label: 'Chọn cấp tư vấn',
                  container: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        for (final level in AdvisorLevel.values)
                          ChoiceChip(
                            label: Text(level.label),
                            selected: advisorVm.selectedLevel == level,
                            onSelected: advisorVm.isLoading
                                ? null
                                : (_) => advisorVm.selectLevel(level),
                          ),
                      ],
                    ),
                  ),
                ),

                // Chat Messages List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: advisorVm.messages.length,
                    itemBuilder: (context, index) {
                      final msg = advisorVm.messages[index];
                      final isUser = msg.sender == 'user';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.school,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: isUser
                                      ? null
                                      : Border.all(color: AppColors.outline),
                                ),
                                child: Text(
                                  msg.text,
                                  style: TextStyle(
                                    color: isUser
                                        ? AppColors.onPrimary
                                        : AppColors.onSurface,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Loading Indicator if AI is thinking
                if (advisorVm.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Đang tổng hợp câu trả lời...',
                          style: TextStyle(fontSize: AppFontSize.label),
                        ),
                      ],
                    ),
                  ),

                // Error branch (D3): retry the last question instead of
                // silently swallowing the failure.
                if (advisorVm.errorMessage != null && !advisorVm.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            advisorVm.errorMessage!,
                            style: const TextStyle(
                              fontSize: AppFontSize.label,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: advisorVm.retryLastQuestion,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),

                // Quick Prompt Chips
                Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          label: const Text('Chiến lược SWP391?'),
                          onPressed: () =>
                              _sendMessage(advisorVm, 'Chiến lược SWP391?'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ActionChip(
                          label: const Text('Duy trì điểm cao PRM323?'),
                          onPressed: () => _sendMessage(
                            advisorVm,
                            'Duy trì điểm cao PRM323?',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ActionChip(
                          label: const Text('Mục tiêu GPA Giỏi?'),
                          onPressed: () => _sendMessage(
                            advisorVm,
                            'Làm sao để đạt GPA Giỏi (>= 8.0)?',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Text Input Bar
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.outline)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: const InputDecoration(
                            hintText: 'Hỏi về dữ liệu học tập của bạn...',
                            isDense: true,
                          ),
                          onSubmitted: (val) => _sendMessage(advisorVm, val),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton.filled(
                        icon: const Icon(Icons.send_rounded),
                        tooltip: 'Gửi câu hỏi',
                        onPressed: () =>
                            _sendMessage(advisorVm, _inputController.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
