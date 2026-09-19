import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_store.dart';
import '../data/case_store.dart';
import '../data/fhir_export.dart';
import '../data/triage.dart';
import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/strings.dart';
import 'ai_chatbot.dart';
import 'patient_home.dart';
import 'report_view.dart';
import 'settings_page.dart';

class DoctorHomePage extends StatefulWidget {
  final String language;

  const DoctorHomePage({super.key, required this.language});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  String filter = 'all'; // all | new | reviewed

  String get lang => appLanguage.value;

  @override
  Widget build(BuildContext context) {
    final account = AuthStore.instance.current;

    return AnimatedBuilder(
      animation: CaseStore.instance,
      builder: (context, _) {
        final all = CaseStore.instance.submitted;
        final cases = all.where((item) {
          if (filter == 'new') return item.status != 'reviewed';
          if (filter == 'reviewed') return item.status == 'reviewed';
          return true;
        }).toList()
          ..sort((a, b) {
            final rank = levelRank(b.triage.level).compareTo(levelRank(a.triage.level));
            if (rank != 0) return rank;
            return b.createdAt.compareTo(a.createdAt);
          });

        final pending = all.where((item) => item.status != 'reviewed').length;

        // Median time between submission and the clinician decision, one of the
        // delays the challenge asks teams to measure.
        final delays = <int>[];
        for (final item in all) {
          final decision = item.decision;
          if (decision == null) continue;
          final decided = DateTime.tryParse('${decision['date'] ?? ''}');
          if (decided == null) continue;
          delays.add(decided.difference(item.date).inMinutes.abs());
        }
        delays.sort();
        final medianDelay = delays.isEmpty
            ? null
            : delays[delays.length ~/ 2];

        return KPage(
          title: S.t(lang, 'doctor.queue'),
          subtitle: account == null
              ? null
              : '${account.name}${account.speciality.isEmpty ? '' : ' · ${account.speciality}'}',
          showBack: false,
          actions: [
            const LanguageButton(),
            IconButton(
              tooltip: S.t(lang, 'tool.chat'),
              icon: const Icon(Icons.forum_outlined, size: 21),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AiChatbotPage(language: lang, role: 'doctor'),
                ),
              ),
            ),
            IconButton(
              tooltip: S.t(lang, 'settings.title'),
              icon: const Icon(Icons.settings_outlined, size: 21),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
            IconButton(
              tooltip: S.t(lang, 'auth.logout'),
              icon: const Icon(Icons.logout_rounded, size: 20),
              onPressed: () async {
                CaseStore.instance.lock();
                await AuthStore.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Kpi(
                      value: '${all.length}',
                      label: S.t(lang, 'doctor.case'),
                      color: K.primary,
                      background: K.primarySoft,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Kpi(
                      value: '$pending',
                      label: S.t(lang, 'doctor.waiting'),
                      color: K.warn,
                      background: K.warnSoft,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Kpi(
                      value: '${all.where((item) => item.triage.level == TriageLevel.red).length}',
                      label: S.t(lang, 'level.label.red'),
                      color: K.danger,
                      background: K.dangerSoft,
                    ),
                  ),
                ],
              ),
              if (medianDelay != null) ...[
                const SizedBox(height: 10),
                KCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: K.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(S.t(lang, 'doctor.delay'), style: K.body),
                      ),
                      Text(
                        medianDelay < 60
                            ? '$medianDelay min'
                            : '${(medianDelay / 60).toStringAsFixed(1)} h',
                        style: K.bodyStrong,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _FilterChip(
                    label: S.t(lang, 'doctor.queue'),
                    selected: filter == 'all',
                    onTap: () => setState(() => filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: S.t(lang, 'doctor.new'),
                    selected: filter == 'new',
                    onTap: () => setState(() => filter = 'new'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: S.t(lang, 'doctor.reviewed'),
                    selected: filter == 'reviewed',
                    onTap: () => setState(() => filter = 'reviewed'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (cases.isEmpty)
                KCard(
                  child: Row(
                    children: [
                      const Icon(Icons.inbox_outlined, color: K.muted),
                      const SizedBox(width: 12),
                      Expanded(child: Text(S.t(lang, 'doctor.empty'), style: K.body)),
                    ],
                  ),
                )
              else
                for (final item in cases)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QueueRow(
                      footCase: item,
                      lang: lang,
                      onTap: () {
                        CaseStore.instance.record('open', item.id);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DoctorCasePage(caseId: item.id),
                          ),
                        );
                      },
                    ),
                  ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

class _Kpi extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color background;

  const _Kpi({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(K.r14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? K.ink : K.card,
          border: Border.all(color: selected ? K.ink : K.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : K.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final FootCase footCase;
  final String lang;
  final VoidCallback onTap;

  const _QueueRow({required this.footCase, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return KCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderColor: footCase.triage.level == TriageLevel.red ? K.danger : K.line,
      child: Row(
        children: [
          LevelDot(level: footCase.triage.level, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        footCase.shareIdentity && footCase.patientName.isNotEmpty
                            ? footCase.patientName
                            : footCase.pseudonym,
                        style: K.h2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    KTag(
                      levelShort(lang, footCase.triage.level),
                      color: levelColor(footCase.triage.level),
                      background: levelSoftColor(footCase.triage.level),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatDate(footCase.date)} · ${footCase.photos.length} ${S.t(lang, 'check.photos')}',
                  style: K.small,
                ),
                if (footCase.status == 'reviewed') ...[
                  const SizedBox(height: 6),
                  KTag(S.t(lang, 'doctor.reviewed'), color: K.ok, background: K.okSoft),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Case review: everything the patient sent, plus the clinician decision that
/// the challenge makes mandatory before any orientation.
class DoctorCasePage extends StatefulWidget {
  final String caseId;

  const DoctorCasePage({super.key, required this.caseId});

  @override
  State<DoctorCasePage> createState() => _DoctorCasePageState();
}

class _DoctorCasePageState extends State<DoctorCasePage> {
  String? level;
  String? orientation;
  final note = TextEditingController();
  bool saving = false;
  bool revealed = false;

  String get lang => appLanguage.value;

  @override
  void initState() {
    super.initState();
    final footCase = CaseStore.instance.byId(widget.caseId);
    if (footCase == null) return;

    level = levelToString(footCase.triage.level);
    final decision = footCase.decision;
    if (decision != null) {
      level = '${decision['level']}';
      orientation = '${decision['orientation']}';
      note.text = '${decision['note'] ?? ''}';
    }
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final footCase = CaseStore.instance.byId(widget.caseId);

    if (footCase == null) {
      return KPage(title: S.t(lang, 'doctor.case'), child: Text(S.t(lang, 'report.none')));
    }

    level ??= levelToString(footCase.triage.level);

    final identityVisible = footCase.shareIdentity || revealed;

    return KPage(
      title: identityVisible && footCase.patientName.isNotEmpty
          ? footCase.patientName
          : footCase.pseudonym,
      subtitle: formatDate(footCase.date),
      actions: [
        IconButton(
          tooltip: S.t(lang, 'doctor.fhir'),
          icon: const Icon(Icons.code_rounded, size: 21),
          onPressed: () => _showFhir(context, footCase),
        ),
      ],
      bottom: FilledButton.icon(
        onPressed: saving ? null : () => _save(footCase),
        icon: const Icon(Icons.verified_outlined, size: 19),
        label: Text(S.t(lang, 'doctor.save')),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportBody(footCase: footCase, lang: lang, forClinician: true),
          if (!footCase.shareIdentity)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: KCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_off_outlined, color: K.muted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        identityVisible
                            ? S.t(lang, 'audit.reveal')
                            : S.t(lang, 'security.masked'),
                        style: K.body,
                      ),
                    ),
                    if (!identityVisible)
                      TextButton(
                        onPressed: () {
                          setState(() => revealed = true);
                          CaseStore.instance.record('reveal', footCase.id);
                        },
                        child: Text(S.t(lang, 'security.reveal')),
                      ),
                  ],
                ),
              ),
            ),
          KSectionLabel(S.t(lang, 'security.audit')),
          KCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in CaseStore.instance.auditFor(footCase.id).take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint_rounded, size: 16, color: K.muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${S.t(lang, 'audit.${entry.action}')} · ${entry.actor}',
                            style: K.small,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatDate(DateTime.tryParse(entry.date) ?? DateTime.now()),
                          style: K.small,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          KSectionLabel(S.t(lang, 'doctor.decision')),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(S.t(lang, 'doctor.confirm'), style: K.bodyStrong),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final option in ['green', 'amber', 'red']) ...[
                      Expanded(
                        child: _LevelOption(
                          label: levelShort(lang, levelFromString(option)),
                          selected: level == option,
                          color: levelColor(levelFromString(option)),
                          background: levelSoftColor(levelFromString(option)),
                          onTap: () => setState(() => level = option),
                        ),
                      ),
                      if (option != 'red') const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                Text(S.t(lang, 'doctor.orientation'), style: K.bodyStrong),
                const SizedBox(height: 10),
                for (final option in [
                  S.t(lang, 'doctor.followup'),
                  S.t(lang, 'doctor.ssb'),
                  S.t(lang, 'doctor.hospital'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RadioRow(
                      label: option,
                      selected: orientation == option,
                      onTap: () => setState(() => orientation = option),
                    ),
                  ),
                const SizedBox(height: 12),
                KField(
                  label: S.t(lang, 'doctor.note'),
                  controller: note,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _save(FootCase footCase) async {
    setState(() => saving = true);

    await CaseStore.instance.setDecision(
      caseId: footCase.id,
      level: level ?? 'amber',
      orientation: orientation ?? S.t(lang, 'doctor.followup'),
      note: note.text.trim(),
      doctorName: AuthStore.instance.current?.name ?? '',
    );

    if (!mounted) return;
    setState(() => saving = false);
    kToast(context, S.t(lang, 'doctor.saved'));
    Navigator.of(context).maybePop();
  }

  void _showFhir(BuildContext context, FootCase footCase) {
    final json = FhirExport.build(footCase);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: K.card,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.r20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.t(lang, 'doctor.fhir'), style: K.h2),
                          const SizedBox(height: 2),
                          Text(S.t(lang, 'doctor.fhirSub'), style: K.small),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: K.line),
              Expanded(
                child: Container(
                  color: K.paper,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: SelectableText(
                      json,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        height: 1.45,
                        color: K.ink,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: json));
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      kToast(context, S.t(lang, 'doctor.copied'));
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(S.t(lang, 'doctor.copy')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _LevelOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(K.r14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? background : K.card,
          border: Border.all(color: selected ? color : K.line, width: selected ? 1.6 : 1),
          borderRadius: BorderRadius.circular(K.r14),
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

class _RadioRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadioRow({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(K.r14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? K.primarySoft : K.card,
          border: Border.all(color: selected ? K.primary : K.line),
          borderRadius: BorderRadius.circular(K.r14),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? K.primary : K.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: selected ? K.bodyStrong.copyWith(color: K.primaryDark) : K.body),
            ),
          ],
        ),
      ),
    );
  }
}
