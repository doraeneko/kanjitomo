import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../review/study_scope.dart';
import 'quiz_session_screen.dart';
import '../../widgets/help_info_button.dart';

/// Entry screen for the multiple-choice quiz: shows the current scope
/// summary, lets the user pick how many questions to attempt, and starts
/// the quiz. No SRS effect — purely a self-test.
class QuizStartScreen extends StatefulWidget {
  final AppDependencies deps;

  const QuizStartScreen({super.key, required this.deps});

  @override
  State<QuizStartScreen> createState() => _QuizStartScreenState();
}

class _QuizStartScreenState extends State<QuizStartScreen> {
  int _questionCount = 10;
  static const _questionCounts = [5, 10, 15, 20];

  String _describeScope(AppLocalizations l, StudyScope scope) {
    if (scope.isEmpty) return l.reviewStartNothingSelected;
    return l.learningKanjiCount(scope.characters.length);
  }

  void _startQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizSessionScreen(
          deps: widget.deps,
          questionCount: _questionCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.quizStartTitle),
        actions: [HelpInfoButton(helpText: l.helpQuiz)],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<StudyScope>(
          valueListenable: widget.deps.studyScope.scope,
          builder: (context, scope, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.reviewStartCurrentSelection,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(_describeScope(l, scope)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l.quizStartQuestionCount,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _questionCounts.map((count) {
                      return ChoiceChip(
                        label: Text('$count'),
                        selected: _questionCount == count,
                        onSelected: (_) =>
                            setState(() => _questionCount = count),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: scope.isEmpty ? null : _startQuiz,
                      child: Text(l.quizStartButton),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
