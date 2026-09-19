import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/khatwa_store.dart';
import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/foot_shapes.dart';
import '../ui/strings.dart';

class _TestPoint {
  final String id;
  final FootSide side;
  final double dx; // 0..1 inside its own foot box
  final double dy;
  final String labelKey;

  const _TestPoint(this.id, this.side, this.dx, this.dy, this.labelKey);
}

/// Sensation self-test on the classic monofilament sites.
///
/// Losing protective sensation is the single biggest risk factor for an ulcer,
/// and it is invisible: the person feels nothing, so nothing seems wrong. This
/// screen makes it visual and takes a minute.
class SensoryCheckPage extends StatefulWidget {
  final String language;

  const SensoryCheckPage({super.key, required this.language});

  @override
  State<SensoryCheckPage> createState() => _SensoryCheckPageState();
}

class _SensoryCheckPageState extends State<SensoryCheckPage> {
  static const points = <_TestPoint>[
    _TestPoint('r_hallux', FootSide.right, 0.42, 0.13, 'sens.hallux'),
    _TestPoint('r_met1', FootSide.right, 0.36, 0.28, 'sens.met1'),
    _TestPoint('r_met3', FootSide.right, 0.52, 0.26, 'sens.met3'),
    _TestPoint('r_met5', FootSide.right, 0.68, 0.32, 'sens.met5'),
    _TestPoint('r_heel', FootSide.right, 0.50, 0.85, 'sens.heel'),
    _TestPoint('l_hallux', FootSide.left, 0.58, 0.13, 'sens.hallux'),
    _TestPoint('l_met1', FootSide.left, 0.64, 0.28, 'sens.met1'),
    _TestPoint('l_met3', FootSide.left, 0.48, 0.26, 'sens.met3'),
    _TestPoint('l_met5', FootSide.left, 0.32, 0.32, 'sens.met5'),
    _TestPoint('l_heel', FootSide.left, 0.50, 0.85, 'sens.heel'),
  ];

  /// null = not tested, true = felt, false = not felt
  final Map<String, bool> results = {};

  String get lang => appLanguage.value;

  int get tested => results.length;
  int get numb => results.values.where((felt) => !felt).length;

  void _tap(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      final current = results[id];
      if (current == null) {
        results[id] = true;
      } else if (current) {
        results[id] = false;
      } else {
        results.remove(id);
      }
    });
  }

  Future<void> _save() async {
    await KhatwaStore.instance.addEntry({
      'type': 'sensory',
      'date': DateTime.now().toIso8601String(),
      'sensations': results,
      'tested': tested,
      'numb': numb,
    });
    if (!mounted) return;
    kToast(context, S.t(lang, 'doctor.saved'));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return KPage(
      title: S.t(lang, 'tool.sensory'),
      subtitle: S.t(lang, 'sens.subtitle'),
      actions: const [LanguageButton()],
      bottom: FilledButton.icon(
        onPressed: tested == 0 ? null : _save,
        icon: const Icon(Icons.save_outlined, size: 18),
        label: Text('${S.t(lang, 'common.save')}  ($tested/10)'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          KBanner(text: S.t(lang, 'sens.how'), icon: Icons.touch_app_outlined),
          const SizedBox(height: 16),
          KCard(
            padding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
            child: Column(
              children: [
                SizedBox(
                  height: 330,
                  child: Row(
                    children: [
                      Expanded(child: _foot(FootSide.right)),
                      const SizedBox(width: 8),
                      Expanded(child: _foot(FootSide.left)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legend(K.ok, S.t(lang, 'sens.felt')),
                    const SizedBox(width: 18),
                    _legend(K.danger, S.t(lang, 'sens.notFelt')),
                    const SizedBox(width: 18),
                    _legend(K.line, S.t(lang, 'sens.untested')),
                  ],
                ),
              ],
            ),
          ),
          if (tested > 0) ...[
            const SizedBox(height: 16),
            KCard(
              borderColor: numb > 0 ? K.warn : K.ok,
              child: Row(
                children: [
                  Icon(
                    numb > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                    color: numb > 0 ? K.warn : K.ok,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      numb > 0
                          ? '${S.t(lang, 'sens.numbFound')} ($numb)'
                          : S.t(lang, 'sens.allFelt'),
                      style: K.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          KBanner(
            text: S.t(lang, 'sens.note'),
            icon: Icons.info_outline_rounded,
            color: K.inkSoft,
            background: K.paper,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 11, height: 11, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: K.small),
      ],
    );
  }

  Widget _foot(FootSide side) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FootMapPainter(side: side),
              ),
            ),
            for (final point in points.where((p) => p.side == side))
              Positioned(
                left: point.dx * width - 19,
                top: point.dy * height - 19,
                child: _Dot(
                  state: results[point.id],
                  label: S.t(lang, point.labelKey),
                  onTap: () => _tap(point.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  final bool? state;
  final String label;
  final VoidCallback onTap;

  const _Dot({required this.state, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = state == null ? K.muted : (state! ? K.ok : K.danger);
    final background = state == null ? K.card : (state! ? K.okSoft : K.dangerSoft);

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: state == null ? 1.4 : 2.2),
          ),
          child: state == null
              ? null
              : Icon(
                  state! ? Icons.check_rounded : Icons.close_rounded,
                  size: 19,
                  color: color,
                ),
        ),
      ),
    );
  }
}

class _FootMapPainter extends CustomPainter {
  final FootSide side;

  _FootMapPainter({required this.side});

  @override
  void paint(Canvas canvas, Size size) {
    final path = FootShape.outline(size, side);

    canvas.drawPath(path, Paint()..color = K.paper);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = K.line,
    );

    final toePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = K.line;
    for (final toe in FootShape.toes(size, side)) {
      canvas.drawOval(toe, toePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FootMapPainter old) => old.side != side;
}
