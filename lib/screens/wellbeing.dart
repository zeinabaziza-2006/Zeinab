import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/khatwa_store.dart';
import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/strings.dart';

/// Daily wellbeing check.
///
/// Living with diabetes is tiring, and a person who is worn down stops checking
/// their feet. This screen is short on purpose: a mood scale, a few words, and
/// one optional note.
class WellbeingPage extends StatefulWidget {
  final String language;

  const WellbeingPage({super.key, required this.language});

  @override
  State<WellbeingPage> createState() => _WellbeingPageState();
}

class _WellbeingPageState extends State<WellbeingPage> {
  final TextEditingController noteController = TextEditingController();
  final Set<String> selected = {};
  int? mood; // 0 lowest .. 4 highest

  String get lang => appLanguage.value;

  static const feelings = [
    'well.tired',
    'well.pain',
    'well.worried',
    'well.motivated',
    'well.calm',
    'well.alone',
  ];

  List<Map<String, dynamic>> get history {
    final entries = KhatwaStore.instance.entriesOfType('wellbeing').toList();
    entries.sort((a, b) => '${b['date']}'.compareTo('${a['date']}'));
    return entries;
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Color _moodColor(int value) {
    if (value <= 1) return K.danger;
    if (value == 2) return K.warn;
    return K.ok;
  }

  Future<void> _save() async {
    if (mood == null) {
      kToast(context, S.t(lang, 'well.pickMood'), error: true);
      return;
    }

    await KhatwaStore.instance.addEntry({
      'type': 'wellbeing',
      'date': DateTime.now().toIso8601String(),
      'mood': mood,
      'emotionKeys': selected.toList(),
      'emotions': selected.map((key) => S.t('English', key)).join(', '),
      'note': noteController.text.trim(),
    });

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    noteController.clear();
    setState(() {
      mood = null;
      selected.clear();
    });
    kToast(context, S.t(lang, 'well.saved'));
  }

  @override
  Widget build(BuildContext context) {
    final past = history;

    return KPage(
      title: S.t(lang, 'tool.wellbeing'),
      subtitle: S.t(lang, 'well.subtitle'),
      actions: const [LanguageButton()],
      bottom: FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.favorite_outline_rounded, size: 19),
        label: Text(S.t(lang, 'common.save')),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.t(lang, 'well.question'), style: K.h2),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < 5; i++) ...[
                      Expanded(
                        child: _MoodButton(
                          level: i,
                          selected: mood == i,
                          color: _moodColor(i),
                          label: S.t(lang, 'well.mood$i'),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => mood = i);
                          },
                        ),
                      ),
                      if (i != 4) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KSectionLabel(S.t(lang, 'well.feelings')),
          KCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in feelings)
                  _Chip(
                    label: S.t(lang, key),
                    selected: selected.contains(key),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (!selected.remove(key)) selected.add(key);
                      });
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KCard(
            child: KField(
              label: '${S.t(lang, 'well.note')} (${S.t(lang, 'q.optional')})',
              controller: noteController,
              maxLines: 3,
            ),
          ),
          if (past.isNotEmpty) ...[
            const SizedBox(height: 18),
            KSectionLabel(S.t(lang, 'well.recent')),
            KCard(
              child: Column(
                children: [
                  for (final entry in past.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _historyRow(entry),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          KBanner(text: S.t(lang, 'well.support'), icon: Icons.volunteer_activism_outlined),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _historyRow(Map<String, dynamic> entry) {
    final value = entry['mood'] is int ? entry['mood'] as int : 2;
    final date = DateTime.tryParse('${entry['date']}') ?? DateTime.now();
    final keys = entry['emotionKeys'];
    final labels = keys is List
        ? keys.map((key) => S.t(lang, '$key')).join(' · ')
        : '';

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _moodColor(value) == K.ok
                ? K.okSoft
                : (_moodColor(value) == K.warn ? K.warnSoft : K.dangerSoft),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_moodIcon(value), size: 18, color: _moodColor(value)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.t(lang, 'well.mood$value'), style: K.bodyStrong),
              if (labels.isNotEmpty)
                Text(labels, style: K.small, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Text(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
          style: K.small,
        ),
      ],
    );
  }

  static IconData _moodIcon(int level) {
    switch (level) {
      case 0:
        return Icons.sentiment_very_dissatisfied_rounded;
      case 1:
        return Icons.sentiment_dissatisfied_rounded;
      case 2:
        return Icons.sentiment_neutral_rounded;
      case 3:
        return Icons.sentiment_satisfied_rounded;
      default:
        return Icons.sentiment_very_satisfied_rounded;
    }
  }
}

class _MoodButton extends StatelessWidget {
  final int level;
  final bool selected;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _MoodButton({
    required this.level,
    required this.selected,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 54,
            decoration: BoxDecoration(
              color: selected
                  ? (color == K.ok ? K.okSoft : (color == K.warn ? K.warnSoft : K.dangerSoft))
                  : K.paper,
              borderRadius: BorderRadius.circular(K.r14),
              border: Border.all(
                color: selected ? color : K.line,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Icon(
              _WellbeingPageState._moodIcon(level),
              color: selected ? color : K.muted,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: selected ? K.ink : K.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? K.primarySoft : K.card,
          border: Border.all(color: selected ? K.primary : K.line, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 15, color: K.primaryDark),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? K.primaryDark : K.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
