import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/risk_profile.dart';
import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/strings.dart';

/// Four questions, one IWGDF risk category, one screening frequency.
class RiskProfilePage extends StatefulWidget {
  final String language;

  const RiskProfilePage({super.key, required this.language});

  @override
  State<RiskProfilePage> createState() => _RiskProfilePageState();
}

class _RiskProfilePageState extends State<RiskProfilePage> {
  bool? neuropathy;
  bool? arterial;
  bool? deformity;
  bool? history;

  String get lang => appLanguage.value;

  @override
  void initState() {
    super.initState();
    final existing = RiskProfile.latest();
    if (existing != null) {
      neuropathy = existing.neuropathy;
      arterial = existing.arterial;
      deformity = existing.deformity;
      history = existing.history;
    }
  }

  bool get complete =>
      neuropathy != null && arterial != null && deformity != null && history != null;

  RiskProfile get draft => RiskProfile(
        neuropathy: neuropathy ?? false,
        arterial: arterial ?? false,
        deformity: deformity ?? false,
        history: history ?? false,
        date: DateTime.now().toIso8601String(),
      );

  Future<void> _save() async {
    await RiskProfile.save(draft);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    kToast(context, S.t(lang, 'doctor.saved'));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final category = complete ? draft.category : null;

    return KPage(
      title: S.t(lang, 'risk.title'),
      subtitle: S.t(lang, 'risk.subtitle'),
      actions: const [LanguageButton()],
      bottom: FilledButton.icon(
        onPressed: complete ? _save : null,
        icon: const Icon(Icons.save_outlined, size: 18),
        label: Text(S.t(lang, 'common.save')),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          KBanner(text: S.t(lang, 'risk.intro'), icon: Icons.assignment_outlined),
          const SizedBox(height: 16),
          KCard(
            child: Column(
              children: [
                _question('risk.q1', neuropathy, (v) => setState(() => neuropathy = v)),
                const Divider(height: 24, color: K.line),
                _question('risk.q2', arterial, (v) => setState(() => arterial = v)),
                const Divider(height: 24, color: K.line),
                _question('risk.q3', deformity, (v) => setState(() => deformity = v)),
                const Divider(height: 24, color: K.line),
                _question('risk.q4', history, (v) => setState(() => history = v)),
              ],
            ),
          ),
          if (category != null) ...[
            const SizedBox(height: 18),
            KSectionLabel(S.t(lang, 'risk.result')),
            RiskCard(category: category, lang: lang),
          ],
          const SizedBox(height: 16),
          KBanner(
            text: S.t(lang, 'risk.note'),
            icon: Icons.info_outline_rounded,
            color: K.inkSoft,
            background: K.paper,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _question(String key, bool? value, ValueChanged<bool> onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(S.t(lang, key), style: K.bodyStrong)),
        const SizedBox(width: 10),
        _Toggle(
          label: S.t(lang, 'q.no'),
          selected: value == false,
          color: K.ok,
          background: K.okSoft,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: 6),
        _Toggle(
          label: S.t(lang, 'q.yes'),
          selected: value == true,
          color: K.warn,
          background: K.warnSoft,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

/// Shown on the risk screen and on the patient home.
class RiskCard extends StatelessWidget {
  final int category;
  final String lang;
  final bool compact;

  const RiskCard({
    super.key,
    required this.category,
    required this.lang,
    this.compact = false,
  });

  static Color colorFor(int category) {
    switch (category) {
      case 0:
        return K.ok;
      case 1:
        return K.warn;
      case 2:
        return K.accent;
      default:
        return K.danger;
    }
  }

  static Color softFor(int category) {
    switch (category) {
      case 0:
        return K.okSoft;
      case 1:
        return K.warnSoft;
      case 2:
        return K.accentSoft;
      default:
        return K.dangerSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(category);

    return KCard(
      borderColor: color,
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Row(
        children: [
          Container(
            width: compact ? 38 : 46,
            height: compact ? 38 : 46,
            decoration: BoxDecoration(
              color: softFor(category),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '$category',
              style: TextStyle(
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.t(lang, 'risk.cat$category'),
                    style: compact ? K.bodyStrong : K.h2),
                const SizedBox(height: 3),
                Text(S.t(lang, 'risk.freq$category'), style: K.small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _Toggle({
    required this.label,
    required this.selected,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? background : K.card,
          border: Border.all(color: selected ? color : K.line, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? color : K.muted,
          ),
        ),
      ),
    );
  }
}
