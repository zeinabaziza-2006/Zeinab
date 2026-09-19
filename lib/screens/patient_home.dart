import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/case_store.dart';
import '../data/khatwa_store.dart';
import '../data/risk_profile.dart';
import '../data/triage.dart';
import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/strings.dart';
import 'ai_chatbot.dart';
import 'doctor_network.dart';
import 'feature_pages.dart';
import 'foot_check.dart';
import 'glycemia.dart';
import 'report_view.dart';
import 'risk_profile_page.dart';
import 'sensory_check.dart';
import 'settings_page.dart';
import 'wellbeing.dart';

class PatientHomePage extends StatefulWidget {
  final String language;

  const PatientHomePage({super.key, required this.language});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  String get lang => appLanguage.value;

  @override
  Widget build(BuildContext context) {
    final account = AuthStore.instance.current;
    final patientId = account?.id ?? '';

    return AnimatedBuilder(
      animation: CaseStore.instance,
      builder: (context, _) {
        final cases = CaseStore.instance.forPatient(patientId);
        final last = cases.isNotEmpty ? cases.first : null;
        final doneToday = CaseStore.instance.hasCheckToday(patientId);
        final streak = CaseStore.instance.streak(patientId);

        // Last seven days, oldest first: was there a check that day?
        final today = DateTime.now();
        final days = cases
            .map((item) => DateTime(item.date.year, item.date.month, item.date.day))
            .toSet();
        final week = List<bool>.generate(7, (i) {
          final day = DateTime(today.year, today.month, today.day)
              .subtract(Duration(days: 6 - i));
          return days.contains(day);
        });

        return KPage(
          title: '${S.t(lang, 'home.hello')} ${_firstName(account?.name ?? '')}',
          subtitle: S.t(lang, 'app.tagline'),
          showBack: false,
          actions: [
            const LanguageButton(),
            IconButton(
              tooltip: S.t(lang, 'settings.title'),
              icon: const Icon(Icons.settings_outlined, size: 22),
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
              _TodayCard(
                lang: lang,
                doneToday: doneToday,
                streak: streak,
                week: week,
                onStart: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FootCheckPage(language: lang)),
                ),
              ),
              const SizedBox(height: 18),
              KSectionLabel(S.t(lang, 'risk.title')),
              Builder(
                builder: (context) {
                  final profile = RiskProfile.latest();
                  if (profile == null) {
                    return KCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RiskProfilePage(language: lang),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment_outlined, color: K.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(S.t(lang, 'risk.cta'), style: K.bodyStrong),
                                const SizedBox(height: 2),
                                Text(S.t(lang, 'risk.subtitle'), style: K.small),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: K.muted),
                        ],
                      ),
                    );
                  }
                  return InkWell(
                    borderRadius: BorderRadius.circular(K.r20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RiskProfilePage(language: lang),
                      ),
                    ),
                    child: RiskCard(category: profile.category, lang: lang, compact: true),
                  );
                },
              ),
              const SizedBox(height: 18),
              KSectionLabel(S.t(lang, 'home.lastResult')),
              if (last == null)
                KCard(
                  child: Row(
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, color: K.muted),
                      const SizedBox(width: 12),
                      Expanded(child: Text(S.t(lang, 'home.noCheck'), style: K.body)),
                    ],
                  ),
                )
              else
                _CaseRow(
                  footCase: last,
                  lang: lang,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportPage(caseId: last.id, language: lang),
                    ),
                  ),
                ),
              if (cases.length > 1) ...[
                const SizedBox(height: 18),
                KSectionLabel(S.t(lang, 'home.history')),
                for (final item in cases.skip(1).take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CaseRow(
                      footCase: item,
                      lang: lang,
                      compact: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportPage(caseId: item.id, language: lang),
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 18),
              KSectionLabel(S.t(lang, 'home.tools')),
              _ToolGrid(lang: lang),
              const SizedBox(height: 18),
              KBanner(text: S.t(lang, 'report.disclaimer'), icon: Icons.shield_outlined),
              const SizedBox(height: 10),
              KBanner(
                text: AuthStore.instance.encryptionActive
                    ? S.t(lang, 'security.encrypted')
                    : S.t(lang, 'security.notEncrypted'),
                icon: Icons.enhanced_encryption_outlined,
                color: AuthStore.instance.encryptionActive ? K.ok : K.warn,
                background: AuthStore.instance.encryptionActive ? K.okSoft : K.warnSoft,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  String _firstName(String name) {
    final parts = name.trim().split(' ');
    return parts.isEmpty ? '' : parts.first;
  }
}

class _TodayCard extends StatelessWidget {
  final String lang;
  final bool doneToday;
  final int streak;
  final List<bool> week;
  final VoidCallback onStart;

  const _TodayCard({
    required this.lang,
    required this.doneToday,
    required this.streak,
    required this.week,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: K.primaryDark,
        borderRadius: BorderRadius.circular(K.r20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  S.t(lang, 'home.todayTitle'),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: K.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$streak ${S.t(lang, 'home.streak')}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            doneToday ? S.t(lang, 'home.done') : S.t(lang, 'home.todaySub'),
            style: const TextStyle(color: Color(0xFFBFD8D8), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < week.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        height: 30,
                        decoration: BoxDecoration(
                          color: week[i] ? K.ok : Colors.white12,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: i == week.length - 1 ? Colors.white54 : Colors.transparent,
                          ),
                        ),
                        child: week[i]
                            ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
                if (i != week.length - 1) const SizedBox(width: 5),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: K.primaryDark,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(K.r14)),
              ),
              onPressed: onStart,
              icon: const Icon(Icons.camera_alt_outlined, size: 20),
              label: Text(S.t(lang, 'home.start')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseRow extends StatelessWidget {
  final FootCase footCase;
  final String lang;
  final bool compact;
  final VoidCallback onTap;

  const _CaseRow({
    required this.footCase,
    required this.lang,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final level = footCase.triage.level;
    return KCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Row(
        children: [
          LevelDot(level: level),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(levelHeadline(lang, level),
                    style: compact ? K.bodyStrong : K.h2, maxLines: 2),
                const SizedBox(height: 3),
                Text(
                  '${formatDate(footCase.date)} · ${footCase.photos.length} ${S.t(lang, 'check.photos')}',
                  style: K.small,
                ),
              ],
            ),
          ),
          if (footCase.status == 'reviewed')
            KTag(S.t(lang, 'doctor.reviewed'), color: K.ok, background: K.okSoft)
          else if (footCase.status == 'submitted')
            KTag(S.t(lang, 'doctor.waiting'), color: K.warn, background: K.warnSoft),
        ],
      ),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  final String lang;

  const _ToolGrid({required this.lang});

  @override
  Widget build(BuildContext context) {
    final tools = <_Tool>[
      _Tool('tool.glycemia', Icons.water_drop_outlined, () => GlycemiaPage(language: lang)),
      _Tool('tool.temperature', Icons.thermostat_outlined, () => TemperaturePage(language: lang)),
      _Tool('tool.sensory', Icons.touch_app_outlined, () => SensoryCheckPage(language: lang)),
      _Tool('tool.wellbeing', Icons.favorite_outline_rounded, () => WellbeingPage(language: lang)),
      _Tool('tool.activity', Icons.directions_walk_rounded, () => ActivityPage(language: lang)),
      _Tool('tool.food', Icons.restaurant_outlined, () => FoodPage(language: lang)),
      _Tool('tool.exercises', Icons.self_improvement_outlined, () => ExercisesPage(language: lang)),
      _Tool('tool.tips', Icons.lightbulb_outline_rounded, () => TipsPage(language: lang)),
      _Tool('tool.videos', Icons.play_circle_outline_rounded, () => VideosPage(language: lang)),
      _Tool('tool.appointments', Icons.event_outlined, () => AppointmentsPage(language: lang)),
      _Tool('tool.chat', Icons.forum_outlined, () => AiChatbotPage(language: lang)),
      _Tool('tool.doctors', Icons.groups_outlined, () => DoctorNetworkPage(language: lang)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 520 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tools.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final tool = tools[index];
            return KCard(
              padding: const EdgeInsets.all(10),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => tool.build()),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(tool.icon, color: K.primary, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    S.t(lang, tool.labelKey),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, height: 1.25, fontWeight: FontWeight.w600, color: K.ink),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Tool {
  final String labelKey;
  final IconData icon;
  final Widget Function() build;

  const _Tool(this.labelKey, this.icon, this.build);
}

// ---------------------------------------------------------------- shared bits

class LevelDot extends StatelessWidget {
  final TriageLevel level;
  final double size;

  const LevelDot({super.key, required this.level, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: levelSoftColor(level),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      alignment: Alignment.center,
      child: Icon(levelIcon(level), color: levelColor(level), size: size * 0.5),
    );
  }
}

Color levelColor(TriageLevel level) {
  switch (level) {
    case TriageLevel.green:
      return K.ok;
    case TriageLevel.amber:
      return K.warn;
    case TriageLevel.red:
      return K.danger;
  }
}

Color levelSoftColor(TriageLevel level) {
  switch (level) {
    case TriageLevel.green:
      return K.okSoft;
    case TriageLevel.amber:
      return K.warnSoft;
    case TriageLevel.red:
      return K.dangerSoft;
  }
}

IconData levelIcon(TriageLevel level) {
  switch (level) {
    case TriageLevel.green:
      return Icons.check_rounded;
    case TriageLevel.amber:
      return Icons.visibility_outlined;
    case TriageLevel.red:
      return Icons.priority_high_rounded;
  }
}

String levelHeadline(String lang, TriageLevel level) {
  switch (level) {
    case TriageLevel.green:
      return S.t(lang, 'level.none');
    case TriageLevel.amber:
      return S.t(lang, 'level.yellow');
    case TriageLevel.red:
      return S.t(lang, 'level.red');
  }
}

String levelShort(String lang, TriageLevel level) {
  switch (level) {
    case TriageLevel.green:
      return S.t(lang, 'level.label.none');
    case TriageLevel.amber:
      return S.t(lang, 'level.label.yellow');
    case TriageLevel.red:
      return S.t(lang, 'level.label.red');
  }
}

String formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '$d/$m/${date.year} · $h:$min';
}

/// Patient profile snapshot handed to the AI layer and stored with the case.
/// The IWGDF risk category travels with it, because the same photo means a
/// different urgency for a category 3 patient than for a category 0.
Map<String, dynamic> patientProfile() {
  final store = KhatwaStore.instance;
  final account = AuthStore.instance.current;
  final risk = RiskProfile.latest();

  return {
    'name': account?.name ?? store.patientName,
    'diabetesType': store.diabetesType,
    'medications': store.medications,
    'allergies': store.allergies,
    'otherConditions': store.otherConditions,
    if (risk != null) ...{
      'iwgdfRiskCategory': risk.category,
      'lossOfProtectiveSensation': risk.neuropathy,
      'peripheralArterialDisease': risk.arterial,
      'footDeformity': risk.deformity,
      'previousUlcerOrAmputation': risk.history,
    },
  };
}
