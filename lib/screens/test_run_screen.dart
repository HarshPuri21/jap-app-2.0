import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sentence.dart';
import '../models/kanji_question.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/option_button.dart';
import 'test_results_screen.dart';

/// One graded question in a test run, in a shape that works for either a
/// Sentence or a KanjiQuestion so the UI code below doesn't need to branch
/// everywhere.
class _TestItem {
  final String prompt; // jp sentence text OR the kanji character
  final bool isKanji;
  final String difficulty;
  final List<String> options;
  final String answer;

  _TestItem.fromSentence(Sentence s)
      : prompt = s.jp,
        isKanji = false,
        difficulty = s.difficulty,
        options = s.options,
        answer = s.answer;

  _TestItem.fromKanji(KanjiQuestion k)
      : prompt = k.kanji,
        isKanji = true,
        difficulty = k.difficulty,
        options = k.options,
        answer = k.answer;
}

class TestRunScreen extends StatefulWidget {
  final String qtype; // sentences | kanji | mixed
  final String difficulty;
  final int count;

  const TestRunScreen({
    super.key,
    required this.qtype,
    required this.difficulty,
    required this.count,
  });

  @override
  State<TestRunScreen> createState() => _TestRunScreenState();
}

class _TestRunScreenState extends State<TestRunScreen> {
  late List<_TestItem> _items;
  int _index = 0;
  String? _selected;
  int _score = 0;
  final List<bool> _correctness = [];

  @override
  void initState() {
    super.initState();
    _items = _buildItems();
  }

  List<_TestItem> _buildItems() {
    switch (widget.qtype) {
      case 'kanji':
        return DataService.instance
            .drawKanji(widget.difficulty, widget.count)
            .map((k) => _TestItem.fromKanji(k))
            .toList();
      case 'mixed':
        final raw =
            DataService.instance.drawMixed(widget.difficulty, widget.count);
        return raw
            .map((q) => q is Sentence
                ? _TestItem.fromSentence(q)
                : _TestItem.fromKanji(q as KanjiQuestion))
            .toList();
      case 'sentences':
      default:
        return DataService.instance
            .drawSentences(widget.difficulty, widget.count)
            .map((s) => _TestItem.fromSentence(s))
            .toList();
    }
  }

  _TestItem get _current => _items[_index];
  bool get _isLast => _index == _items.length - 1;

  void _choose(String option) {
    if (_selected != null) return;
    final correct = option == _current.answer;
    setState(() {
      _selected = option;
      _correctness.add(correct);
      if (correct) _score += 1;
    });
    context.read<SettingsService>().recordAnswer(correct: correct);
  }

  void _advance() {
    if (_isLast) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TestResultsScreen(
            score: _score,
            total: _items.length,
          ),
        ),
      );
      return;
    }
    setState(() {
      _index += 1;
      _selected = null;
    });
  }

  OptionState _stateFor(String option) {
    if (_selected == null) return OptionState.idle;
    if (option == _current.answer) return OptionState.selectedCorrect;
    if (option == _selected) return OptionState.selectedWrong;
    return OptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No questions available for this combination.',
                    style: TextStyle(color: AppColors.fg),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final item = _current;
    final progress = (_index + (_selected != null ? 1 : 0)) / _items.length;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1).toDouble(),
                    minHeight: 6,
                    backgroundColor: AppColors.bgCard,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DifficultyBadge(difficulty: item.difficulty),
                          Text(
                            'Question ${_index + 1} / ${_items.length}',
                            style: const TextStyle(
                                color: AppColors.fgMuted, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 26),
                        alignment: Alignment.center,
                        child: Text(
                          item.prompt,
                          textAlign: TextAlign.center,
                          style: AppTheme.jp(
                            item.isKanji ? 88 : 28,
                            weight: FontWeight.w700,
                          ).copyWith(
                            color:
                                item.isKanji ? AppColors.accent : AppColors.fg,
                          ),
                        ),
                      ),
                      ...item.options.map(
                        (opt) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OptionButton(
                            text: opt,
                            state: _stateFor(opt),
                            onTap: () => _choose(opt),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selected == null ? null : _advance,
                    child: Text(_isLast ? 'Finish' : 'Next →'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.fg),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Test',
              style: TextStyle(
                color: AppColors.fg,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'Score: $_score/${_correctness.length}',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
