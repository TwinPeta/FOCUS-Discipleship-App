import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_snack.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../core/widgets/states/error_view.dart';
import '../../../core/widgets/states/skeleton.dart';
import '../../pathways/presentation/widgets/pathway_progress_bar.dart';
import '../domain/learning_models.dart';
import 'learning_providers.dart';
import '../../../core/theme/app_gradients.dart';

/// Screen 35: Quiz (`/quiz/:id`). With `review: true` it replays the last
/// attempt read-only ("Review my answers").
class QuizScreen extends ConsumerWidget {
  const QuizScreen({
    super.key,
    required this.id,
    required this.origin,
    this.review = false,
  });

  final String id;
  final LearningOrigin origin;
  final bool review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizAsync = ref.watch(quizProvider(id));
    final attempt = review
        ? ref.watch(lastQuizAttemptProvider(id))
        : const AsyncData<QuizAttempt?>(null);
    if (quizAsync.isLoading || attempt.isLoading) {
      return Scaffold(backgroundColor: AppColors.page, body: const Skeleton());
    }
    final quiz = quizAsync.valueOrNull;
    if (quiz == null) {
      return ErrorScreen(onRetry: () => ref.invalidate(quizProvider(id)));
    }
    return _QuizView(
      quiz: quiz,
      origin: origin,
      reviewAnswers: review ? attempt.valueOrNull?.answers : null,
    );
  }
}

class _QuizView extends ConsumerStatefulWidget {
  const _QuizView({
    required this.quiz,
    required this.origin,
    this.reviewAnswers,
  });

  final Quiz quiz;
  final LearningOrigin origin;

  /// Non-null in review mode.
  final List<int>? reviewAnswers;

  @override
  ConsumerState<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends ConsumerState<_QuizView> {
  int _index = 0;
  int? _selected;
  bool _checked = false;
  bool _submitting = false;
  late final List<int> _answers = List.filled(widget.quiz.questions.length, -1);

  bool get _review => widget.reviewAnswers != null;
  bool get _last => _index == widget.quiz.questions.length - 1;
  bool get _inProgress => !_review && (_index > 0 || _selected != null);

  int? get _shownSelection =>
      _review ? widget.reviewAnswers!.elementAtOrNull(_index) : _selected;
  bool get _revealed => _review || _checked;

  /// A real backend scores the quiz and never sends the right answers, so
  /// there is nothing to reveal after each question: go straight on.
  bool get _answersHidden =>
      widget.quiz.questions.any((q) => q.correctIndex < 0);

  void _check() {
    if (_selected == null) return;
    setState(() {
      _checked = true;
      _answers[_index] = _selected!;
    });
    if (_answersHidden) unawaited(_next());
  }

  Future<void> _next() async {
    if (_review) {
      if (_last) {
        _leave();
      } else {
        setState(() => _index++);
      }
      return;
    }
    if (!_last) {
      setState(() {
        _index++;
        _selected = null;
        _checked = false;
      });
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(learningActionsProvider)
          .submitQuiz(
            widget.quiz,
            _answers,
            pathwayId: widget.origin.pathwayId,
          );
      if (!mounted) return;
      final query = GoRouterState.of(context).uri.query;
      context.pushReplacement(
        '/quiz/${widget.quiz.item.id}/result${query.isEmpty ? '' : '?$query'}',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        showErrorSnack(context);
      }
    }
  }

  void _leave() =>
      context.canPop() ? context.pop() : context.go('/communities');

  Future<void> _confirmLeave() async {
    if (!_inProgress) return _leave();
    final leave = await showConfirmDialog(
      context,
      title: 'Leave the quiz?',
      message: 'Your progress in this quiz will be lost.',
      confirmLabel: 'Leave',
      cancelLabel: 'Keep going',
      destructive: true,
    );
    if (leave && mounted) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final question = quiz.questions[_index];
    final total = quiz.questions.length;
    return PopScope(
      canPop: !_inProgress,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadii.headerBottom),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      semanticLabel: 'Back',
                      onPressed: _confirmLeave,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _review ? '${quiz.item.title} · Review' : quiz.item.title,
                      style: AppTextStyles.amberHeaderTitle.copyWith(
                        fontSize: 24,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Question ${_index + 1} of $total',
                      style: AppTextStyles.amberHeaderSubtitle,
                    ),
                    const SizedBox(height: 10),
                    PathwayProgressBar(progress: (_index + 1) / total),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        question.prompt,
                        style: AppTextStyles.sectionHeading.copyWith(
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < question.options.length; i++)
                      _OptionRow(
                        label: question.options[i],
                        selected: _shownSelection == i,
                        state: !_revealed
                            ? _OptionState.open
                            : _answersHidden
                            ? _OptionState.neutral
                            : i == question.correctIndex
                            ? _OptionState.correct
                            : _shownSelection == i
                            ? _OptionState.wrong
                            : _OptionState.neutral,
                        onTap: _revealed
                            ? null
                            : () => setState(() => _selected = i),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                color: AppColors.white,
                child: AppPrimaryButton(
                  label: !_revealed
                      ? (_answersHidden
                            ? (_last ? 'See my result' : 'Next question')
                            : 'Check answer')
                      : _last
                      ? (_review ? 'Done' : 'See my result')
                      : 'Next question',
                  isLoading: _submitting,
                  onPressed: !_revealed
                      ? (_selected == null ? null : _check)
                      : _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _OptionState { open, correct, wrong, neutral }

/// Radio row. After checking: ink border + check icon for the right
/// answer, ink border + cross for a wrong pick (shape and words, not
/// red/green).
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.state,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final highlighted =
        state == _OptionState.correct ||
        state == _OptionState.wrong ||
        (state == _OptionState.open && selected);
    final (icon, suffix) = switch (state) {
      _OptionState.correct => (Icons.check_circle_rounded, 'Correct answer'),
      _OptionState.wrong => (Icons.cancel_rounded, 'Your answer, incorrect'),
      _ => (
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        selected ? 'Selected' : '',
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: onTap != null,
        selected: selected,
        label: suffix.isEmpty ? label : '$label. $suffix',
        excludeSemantics: true,
        child: Material(
          color: selected || state == _OptionState.correct
              ? AppColors.honey
              : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.tile),
            side: highlighted
                ? BorderSide(color: AppColors.ink, width: 2)
                : BorderSide(color: AppColors.inputBorder, width: 1.5),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.tile),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: AppColors.ink),
                  const SizedBox(width: 10),
                  Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
                  if (state == _OptionState.correct ||
                      state == _OptionState.wrong)
                    Text(
                      state == _OptionState.correct ? 'Correct' : 'Incorrect',
                      style: AppTextStyles.chip,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
