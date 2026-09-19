import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/ai_gateway.dart';
import '../data/auth_store.dart';
import '../data/case_store.dart';
import '../data/khatwa_store.dart';
import '../data/triage.dart';
import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/foot_shapes.dart';
import '../ui/strings.dart';
import 'capture_guide.dart';
import 'patient_home.dart';
import 'report_view.dart';

const List<GuideStep> kCaptureSteps = [
  GuideStep(
    key: 'right_sole',
    labelKey: 'check.rightSole',
    side: FootSide.right,
    view: FootView.sole,
  ),
  GuideStep(
    key: 'left_sole',
    labelKey: 'check.leftSole',
    side: FootSide.left,
    view: FootView.sole,
  ),
  GuideStep(
    key: 'right_top',
    labelKey: 'check.rightTop',
    side: FootSide.right,
    view: FootView.top,
  ),
  GuideStep(
    key: 'left_top',
    labelKey: 'check.leftTop',
    side: FootSide.left,
    view: FootView.top,
  ),
];

class FootCheckPage extends StatefulWidget {
  final String language;

  const FootCheckPage({super.key, required this.language});

  @override
  State<FootCheckPage> createState() => _FootCheckPageState();
}

class _FootCheckPageState extends State<FootCheckPage> {
  int step = 0;

  final Map<String, Uint8List> shots = {};
  final ImagePicker picker = ImagePicker();

  final List<String> questionKeys = [
    'pain',
    'wound',
    'swelling',
    'color',
    'smell',
    'fever',
    'numbness',
    'barefoot',
  ];

  final Map<String, bool> answers = {};
  final TextEditingController glucose = TextEditingController();

  String get lang => appLanguage.value;

  @override
  void dispose() {
    glucose.dispose();
    super.dispose();
  }

  Future<void> openGuide() async {
    final result = await Navigator.of(context).push<Map<String, Uint8List>>(
      MaterialPageRoute(
        builder: (_) => CaptureGuidePage(steps: kCaptureSteps, existing: shots),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      shots
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> pickFor(String key) async {
    try {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => shots[key] = bytes);
    } catch (_) {
      if (mounted) kToast(context, S.t(lang, 'common.error'), error: true);
    }
  }

  Future<void> analyse() async {
    final filled = kCaptureSteps.where((s) => shots.containsKey(s.key)).toList();

    final payload = <String, dynamic>{
      for (final key in questionKeys) key: answers[key] ?? false,
      'glucose': glucose.text.trim(),
    };
    final profile = patientProfile();

    final work = AiGateway.analyse(
      images: filled
          .map((s) => CaseImage(
                label: S.t('Français', s.labelKey),
                base64: base64Encode(shots[s.key]!),
              ))
          .toList(),
      answers: payload,
      profile: profile,
      lang: lang,
    );

    final triage = await Navigator.of(context).push<TriageResult>(
      MaterialPageRoute<TriageResult>(
        builder: (_) => AnalysingPage(work: work, usingAi: ApiConfig.hasKey),
      ),
    );

    if (triage == null || !mounted) return;

    final account = AuthStore.instance.current;
    final footCase = FootCase(
      id: 'case_${DateTime.now().millisecondsSinceEpoch}',
      patientId: account?.id ?? 'anonymous',
      patientName: account?.name ?? '',
      createdAt: DateTime.now().toIso8601String(),
      photoLabels: filled.map((s) => S.t('Français', s.labelKey)).toList(),
      photos: filled.map((s) => base64Encode(shots[s.key]!)).toList(),
      answers: payload,
      profile: profile,
      triage: triage,
      status: 'draft',
    );

    await CaseStore.instance.save(footCase);
    await KhatwaStore.instance.addEntry({
      'type': 'foot_photo',
      'date': footCase.createdAt,
      'level': footCase.triage.level.name,
      'photos': footCase.photos.length,
      'caseId': footCase.id,
    });

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReportPage(caseId: footCase.id, language: lang, freshResult: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KPage(
      title: S.t(lang, 'home.todayTitle'),
      subtitle: '${S.t(lang, 'check.step')} ${step + 1}/2',
      actions: const [LanguageButton()],
      bottom: _bottomBar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _StepBar(step: step, lang: lang),
          const SizedBox(height: 16),
          if (step == 0) ..._photoStep() else ..._questionStep(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    if (step == 0) {
      return FilledButton(
        onPressed: shots.isEmpty
            ? () => kToast(context, S.t(lang, 'check.needPhoto'), error: true)
            : () {
                HapticFeedback.selectionClick();
                setState(() => step = 1);
              },
        child: Text(S.t(lang, 'check.next')),
      );
    }

    return FilledButton.icon(
      onPressed: analyse,
      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
      label: Text(S.t(lang, 'check.analyze')),
    );
  }

  List<Widget> _photoStep() {
    final done = shots.length;

    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: K.primaryDark,
          borderRadius: BorderRadius.circular(K.r20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 54,
              child: CustomPaint(
                painter: FootBadgePainter(side: FootSide.right, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.t(lang, 'capture.guided'),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.t(lang, 'check.guide'),
                    style: const TextStyle(
                        color: Color(0xFFBFD8D8), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: K.primaryDark,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(K.r14),
                        ),
                      ),
                      onPressed: openGuide,
                      icon: const Icon(Icons.center_focus_strong_rounded, size: 19),
                      label: Text(
                        done == 0
                            ? S.t(lang, 'capture.open')
                            : S.t(lang, 'capture.continue'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: KSectionLabel('${S.t(lang, 'check.photos')}  $done/4')),
          if (done > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: KTag('$done ✓', color: K.ok, background: K.okSoft),
            ),
        ],
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 520 ? 4 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kCaptureSteps.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) => _slot(kCaptureSteps[index]),
          );
        },
      ),
    ];
  }

  Widget _slot(GuideStep guideStep) {
    final bytes = shots[guideStep.key];
    final filled = bytes != null;

    return KCard(
      padding: EdgeInsets.zero,
      borderColor: filled ? K.ok : K.line,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(K.r20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (filled)
              Image.memory(bytes, fit: BoxFit.cover)
            else
              Container(
                color: K.paper,
                child: Center(
                  child: SizedBox(
                    width: 46,
                    height: 58,
                    child: CustomPaint(
                      painter: FootBadgePainter(
                        side: guideStep.side,
                        color: K.line,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: filled ? K.ink : K.card,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (filled) ...[
                      const Icon(Icons.check_circle_rounded, size: 13, color: K.ok),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        S.t(lang, guideStep.labelKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: filled ? Colors.white : K.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: () => _slotMenu(guideStep)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _slotMenu(GuideStep guideStep) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: K.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, color: K.line),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.center_focus_strong_rounded, color: K.primary),
              title: Text(S.t(lang, 'capture.open'), style: K.bodyStrong),
              onTap: () {
                Navigator.of(sheetContext).pop();
                openGuide();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: K.primary),
              title: Text(S.t(lang, 'check.gallery'), style: K.bodyStrong),
              onTap: () {
                Navigator.of(sheetContext).pop();
                pickFor(guideStep.key);
              },
            ),
            if (shots.containsKey(guideStep.key))
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: K.danger),
                title: Text(S.t(lang, 'capture.remove'),
                    style: K.bodyStrong.copyWith(color: K.danger)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => shots.remove(guideStep.key));
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  List<Widget> _questionStep() {
    final answered = questionKeys.where((key) => answers.containsKey(key)).length;

    return [
      Row(
        children: [
          Expanded(child: KSectionLabel(S.t(lang, 'check.questions'))),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('$answered/${questionKeys.length}', style: K.small),
          ),
        ],
      ),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < questionKeys.length; i++) ...[
              _YesNo(
                question: S.t(lang, 'q.${questionKeys[i]}'),
                value: answers[questionKeys[i]],
                yes: S.t(lang, 'q.yes'),
                no: S.t(lang, 'q.no'),
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => answers[questionKeys[i]] = value);
                },
              ),
              if (i != questionKeys.length - 1)
                const Divider(height: 22, color: K.line),
            ],
          ],
        ),
      ),
      const SizedBox(height: 14),
      KCard(
        child: KField(
          label: '${S.t(lang, 'q.glucose')} (${S.t(lang, 'q.optional')})',
          controller: glucose,
          keyboard: TextInputType.number,
          hint: '120',
        ),
      ),
    ];
  }
}

/// Full screen analysis, with the stages named as they happen.
/// It replaces a spinner, and it doubles as the explanation of how the triage
/// works during a demo.
class AnalysingPage extends StatefulWidget {
  final Future<TriageResult> work;
  final bool usingAi;

  const AnalysingPage({super.key, required this.work, required this.usingAi});

  @override
  State<AnalysingPage> createState() => _AnalysingPageState();
}

class _AnalysingPageState extends State<AnalysingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  int stage = 0;
  TriageResult? result;
  bool finished = false;

  String get lang => appLanguage.value;

  List<String> get stages => [
        'analyse.s1',
        widget.usingAi ? 'analyse.s2' : 'analyse.s2offline',
        'analyse.s3',
        'analyse.s4',
      ];

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _run();
    _tick();
  }

  Future<void> _run() async {
    result = await widget.work;
    if (!mounted) return;
    setState(() => finished = true);
    _maybeClose();
  }

  Future<void> _tick() async {
    while (mounted && stage < stages.length - 1) {
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      setState(() => stage++);
      if (stage >= stages.length - 1) _maybeClose();
    }
  }

  void _maybeClose() {
    if (!mounted || !finished || stage < stages.length - 1) return;
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.primaryDark,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: RotationTransition(
                      turns: _spin,
                      child: SizedBox(
                        width: 74,
                        height: 74,
                        child: CustomPaint(
                          painter: CaptureRingPainter(
                            total: 4,
                            done: List<bool>.generate(4, (i) => i <= stage),
                            active: stage,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    S.t(lang, 'check.analyzing'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  for (var i = 0; i < stages.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: i < stage ? K.ok : Colors.white12,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: i <= stage ? Colors.white54 : Colors.white12,
                              ),
                            ),
                            child: i < stage
                                ? const Icon(Icons.check_rounded,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              S.t(lang, stages[i]),
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.35,
                                color: i <= stage ? Colors.white : Colors.white38,
                                fontWeight:
                                    i == stage ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _YesNo extends StatelessWidget {
  final String question;
  final bool? value;
  final String yes;
  final String no;
  final ValueChanged<bool> onChanged;

  const _YesNo({
    required this.question,
    required this.value,
    required this.yes,
    required this.no,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(question, style: K.bodyStrong)),
        const SizedBox(width: 10),
        _Choice(
          label: no,
          selected: value == false,
          color: K.ok,
          background: K.okSoft,
          onTap: () => onChanged(false),
        ),
        const SizedBox(width: 6),
        _Choice(
          label: yes,
          selected: value == true,
          color: K.danger,
          background: K.dangerSoft,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _Choice({
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

class _StepBar extends StatelessWidget {
  final int step;
  final String lang;

  const _StepBar({required this.step, required this.lang});

  @override
  Widget build(BuildContext context) {
    final labels = [S.t(lang, 'check.photos'), S.t(lang, 'check.questions')];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step ? K.primary : K.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: i <= step ? K.primary : K.muted,
                  ),
                ),
              ],
            ),
          ),
          if (i != labels.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}
