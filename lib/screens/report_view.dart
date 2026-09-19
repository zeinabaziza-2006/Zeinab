import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/case_store.dart';
import '../data/triage.dart';
import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/strings.dart';
import 'patient_home.dart';

class ReportPage extends StatelessWidget {
  final String caseId;
  final String language;
  final bool freshResult;

  const ReportPage({
    super.key,
    required this.caseId,
    required this.language,
    this.freshResult = false,
  });

  @override
  Widget build(BuildContext context) {
    final lang = appLanguage.value;

    return AnimatedBuilder(
      animation: CaseStore.instance,
      builder: (context, _) {
        final footCase = CaseStore.instance.byId(caseId);

        if (footCase == null) {
          return KPage(
            title: S.t(lang, 'report.title'),
            child: Text(S.t(lang, 'report.none'), style: K.body),
          );
        }

        final sent = footCase.status != 'draft';

        return KPage(
          title: S.t(lang, 'report.title'),
          subtitle: formatDate(footCase.date),
          actions: [
            IconButton(
              tooltip: S.t(lang, 'report.copy'),
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: buildReportText(footCase, lang)),
                );
                if (context.mounted) kToast(context, S.t(lang, 'doctor.copied'));
              },
            ),
            const LanguageButton(),
          ],
          bottom: sent
              ? Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: K.ok),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(S.t(lang, 'report.sentAlready'),
                          style: K.bodyStrong.copyWith(color: K.ok)),
                    ),
                  ],
                )
              : FilledButton.icon(
                  onPressed: () => _askConsent(context, footCase, lang),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(S.t(lang, 'report.send')),
                ),
          child: ReportBody(footCase: footCase, lang: lang, forClinician: false),
        );
      },
    );
  }

  /// Nothing leaves the patient side without an explicit consent, and identity
  /// sharing is a separate, optional choice.
  void _askConsent(BuildContext context, FootCase footCase, String lang) {
    var consent = true;
    var identity = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setLocalState) => AlertDialog(
          backgroundColor: K.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.r20)),
          title: Text(S.t(lang, 'consent.title'), style: K.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.t(lang, 'consent.body'), style: K.body),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: consent,
                onChanged: (value) => setLocalState(() => consent = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: K.primary,
                title: Text(S.t(lang, 'consent.share'), style: K.body),
              ),
              CheckboxListTile(
                value: identity,
                onChanged: (value) => setLocalState(() => identity = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: K.primary,
                title: Text(S.t(lang, 'consent.identity'), style: K.body),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(S.t(lang, 'common.cancel')),
            ),
            FilledButton(
              onPressed: consent
                  ? () async {
                      Navigator.of(dialogContext).pop();
                      await CaseStore.instance.submit(
                        footCase,
                        consent: true,
                        shareIdentity: identity,
                      );
                      if (context.mounted) kToast(context, S.t(lang, 'report.sent'));
                    }
                  : null,
              child: Text(S.t(lang, 'report.send')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared between the patient report and the clinician case view.
class ReportBody extends StatelessWidget {
  final FootCase footCase;
  final String lang;
  final bool forClinician;

  const ReportBody({
    super.key,
    required this.footCase,
    required this.lang,
    required this.forClinician,
  });

  @override
  Widget build(BuildContext context) {
    final triage = footCase.triage;
    final usedAi = triage.source != 'rules';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
          ),
          child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: levelSoftColor(triage.level),
            borderRadius: BorderRadius.circular(K.r20),
            border: Border.all(color: levelColor(triage.level)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LevelDot(level: triage.level, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(levelHeadline(lang, triage.level),
                        style: K.h2.copyWith(color: levelColor(triage.level))),
                    const SizedBox(height: 6),
                    Text(
                      forClinician && triage.clinicianSummary.isNotEmpty
                          ? triage.clinicianSummary
                          : triage.patientSummary,
                      style: K.body.copyWith(color: K.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: S.t(lang, 'report.confidence'),
                value: '${(triage.confidence * 100).round()}%',
                icon: Icons.insights_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(
                label: S.t(lang, 'report.quality'),
                value: _quality(lang, triage.photoQuality),
                icon: Icons.photo_size_select_actual_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        KTag(
          usedAi ? S.t(lang, 'report.source.ai') : S.t(lang, 'report.source.rules'),
          color: usedAi ? K.primaryDark : K.accent,
          background: usedAi ? K.primarySoft : K.accentSoft,
        ),
        if (triage.engineNote != null) ...[
          const SizedBox(height: 8),
          Text(triage.engineNote!, style: K.small.copyWith(color: K.accent)),
        ],
        if (footCase.photos.isNotEmpty) ...[
          const SizedBox(height: 18),
          KSectionLabel(S.t(lang, 'check.photos')),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: footCase.photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final label = index < footCase.photoLabels.length
                    ? footCase.photoLabels[index]
                    : '';
                return GestureDetector(
                  onTap: () => _openPhoto(context, footCase.photos[index], label),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(K.r14),
                    child: Image.memory(
                      base64Decode(footCase.photos[index]),
                      width: 110,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        ..._comparison(context),
        if (triage.findings.isNotEmpty) ...[
          const SizedBox(height: 18),
          KSectionLabel(S.t(lang, 'report.findings')),
          for (final finding in triage.findings)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: KCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: finding.severity == 'urgent'
                            ? K.danger
                            : finding.severity == 'info'
                                ? K.muted
                                : K.warn,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(finding.label, style: K.bodyStrong),
                          if (finding.detail.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(finding.detail, style: K.small),
                          ],
                        ],
                      ),
                    ),
                    KTag(
                      finding.source == 'image' ? 'photo' : finding.source,
                      color: K.inkSoft,
                      background: K.paper,
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (triage.advice.isNotEmpty) ...[
          const SizedBox(height: 8),
          KSectionLabel(S.t(lang, 'report.advice')),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in triage.advice)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_rounded, size: 17, color: K.primary),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item, style: K.body)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (forClinician) ...[
          const SizedBox(height: 8),
          KSectionLabel(S.t(lang, 'doctor.patientSays')),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in footCase.answers.entries)
                  if (entry.key != 'glucose')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(S.t(lang, 'q.${entry.key}'), style: K.body)),
                          KTag(
                            entry.value == true ? S.t(lang, 'q.yes') : S.t(lang, 'q.no'),
                            color: entry.value == true ? K.danger : K.ok,
                            background: entry.value == true ? K.dangerSoft : K.okSoft,
                          ),
                        ],
                      ),
                    ),
                if ('${footCase.answers['glucose'] ?? ''}'.isNotEmpty)
                  Row(
                    children: [
                      Expanded(child: Text(S.t(lang, 'q.glucose'), style: K.body)),
                      Text('${footCase.answers['glucose']}', style: K.bodyStrong),
                    ],
                  ),
              ],
            ),
          ),
        ],
        if (footCase.decision != null) ...[
          const SizedBox(height: 18),
          KSectionLabel(S.t(lang, 'doctor.decision')),
          KCard(
            borderColor: K.ok,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: K.ok, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${footCase.decision!['doctor'] ?? ''}', style: K.bodyStrong),
                    ),
                    KTag(
                      levelShort(lang, levelFromString('${footCase.decision!['level']}')),
                      color: levelColor(levelFromString('${footCase.decision!['level']}')),
                      background: levelSoftColor(levelFromString('${footCase.decision!['level']}')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('${S.t(lang, 'doctor.orientation')}: ${footCase.decision!['orientation'] ?? ''}',
                    style: K.body),
                if ('${footCase.decision!['note'] ?? ''}'.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('${footCase.decision!['note']}', style: K.body),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        KBanner(
          text: S.t(lang, 'report.disclaimer'),
          icon: Icons.shield_outlined,
          color: K.inkSoft,
          background: K.paper,
        ),
        const SizedBox(height: 10),
      ],
    );
  }


  /// Same position, previous check, side by side. The ministry brief asks for a
  /// photographic history, and evolution is what a clinician actually reads.
  List<Widget> _comparison(BuildContext context) {
    final earlier = CaseStore.instance
        .forPatient(footCase.patientId)
        .where((item) =>
            item.id != footCase.id &&
            item.createdAt.compareTo(footCase.createdAt) < 0 &&
            item.photos.isNotEmpty)
        .toList();

    if (earlier.isEmpty) return const [];
    final previous = earlier.first;

    final pairs = <List<dynamic>>[];
    for (var i = 0; i < footCase.photoLabels.length; i++) {
      final label = footCase.photoLabels[i];
      final j = previous.photoLabels.indexOf(label);
      if (j >= 0 && j < previous.photos.length && i < footCase.photos.length) {
        pairs.add([label, previous.photos[j], footCase.photos[i]]);
      }
    }
    if (pairs.isEmpty) return const [];

    return [
      const SizedBox(height: 18),
      KSectionLabel(S.t(lang, 'compare.title')),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.t(lang, 'compare.since')} ${formatDate(previous.date)}',
              style: K.small,
            ),
            const SizedBox(height: 12),
            for (final pair in pairs)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pair[0]}', style: K.bodyStrong),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ComparePhoto(
                            base64Data: '${pair[1]}',
                            caption: S.t(lang, 'compare.before'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ComparePhoto(
                            base64Data: '${pair[2]}',
                            caption: S.t(lang, 'compare.now'),
                            highlight: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }

  String _quality(String lang, String quality) {
    switch (quality) {
      case 'good':
        return lang == 'Français' ? 'Bonne' : (S.isRtl(lang) ? 'جيدة' : 'Good');
      case 'poor':
        return lang == 'Français' ? 'Faible' : (S.isRtl(lang) ? 'ضعيفة' : 'Poor');
      default:
        return lang == 'Français' ? 'Moyenne' : (S.isRtl(lang) ? 'متوسطة' : 'Fair');
    }
  }

  void _openPhoto(BuildContext context, String base64Data, String label) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: K.card,
        insetPadding: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.r20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(K.r20)),
              child: InteractiveViewer(
                child: Image.memory(base64Decode(base64Data), fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(label, style: K.bodyStrong),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Metric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return KCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: K.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: K.small),
                const SizedBox(height: 2),
                Text(value, style: K.bodyStrong),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparePhoto extends StatelessWidget {
  final String base64Data;
  final String caption;
  final bool highlight;

  const _ComparePhoto({
    required this.base64Data,
    required this.caption,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(K.r14),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: Image.memory(base64Decode(base64Data), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: highlight ? K.primary : K.muted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              caption,
              style: K.small.copyWith(
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? K.primaryDark : K.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Plain text version of the report, for sharing with a family member or
/// pasting into a message. No photos, no identifiers beyond the name.
String buildReportText(FootCase footCase, String lang) {
  final buffer = StringBuffer();
  final triage = footCase.triage;

  buffer.writeln('Khatwa · ${S.t(lang, 'report.title')}');
  buffer.writeln(formatDate(footCase.date));
  buffer.writeln('');
  buffer.writeln('${S.t(lang, 'check.result')}: ${levelHeadline(lang, triage.level)}');
  if (triage.patientSummary.isNotEmpty) buffer.writeln(triage.patientSummary);
  buffer.writeln('');

  if (triage.findings.isNotEmpty) {
    buffer.writeln('${S.t(lang, 'report.findings')}:');
    for (final finding in triage.findings) {
      buffer.writeln('- ${finding.label}: ${finding.detail}');
    }
    buffer.writeln('');
  }

  if (triage.advice.isNotEmpty) {
    buffer.writeln('${S.t(lang, 'report.advice')}:');
    for (final item in triage.advice) {
      buffer.writeln('- $item');
    }
    buffer.writeln('');
  }

  final decision = footCase.decision;
  if (decision != null) {
    buffer.writeln('${S.t(lang, 'doctor.decision')}: ${decision['doctor']}');
    buffer.writeln('${S.t(lang, 'doctor.orientation')}: ${decision['orientation']}');
    if ('${decision['note'] ?? ''}'.isNotEmpty) buffer.writeln('${decision['note']}');
    buffer.writeln('');
  }

  buffer.writeln(S.t(lang, 'report.disclaimer'));
  return buffer.toString();
}
