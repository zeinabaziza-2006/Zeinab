import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/khatwa_store.dart';
import '../ui/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/strings.dart';

/// Blood glucose log.
///
/// One measure over time, so: a line chart with the target range drawn as a
/// band behind it, out of range points marked with status colour AND a shape,
/// and the latest value as a hero number. No second axis, no legend for a
/// single series.
class GlycemiaPage extends StatefulWidget {
  final String language;

  const GlycemiaPage({super.key, required this.language});

  @override
  State<GlycemiaPage> createState() => _GlycemiaPageState();
}

class _GlycemiaPageState extends State<GlycemiaPage> {
  final TextEditingController valueController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String unit = 'mg/dL';
  String moment = 'fasting';

  String get lang => appLanguage.value;

  static const moments = ['fasting', 'afterMeal', 'bedtime', 'random'];

  List<Map<String, dynamic>> get readings {
    final entries = KhatwaStore.instance
        .entriesOfType('glycemia')
        .where((entry) => entry['value'] != null)
        .toList();
    entries.sort((a, b) => '${b['date']}'.compareTo('${a['date']}'));
    return entries;
  }

  @override
  void dispose() {
    valueController.dispose();
    noteController.dispose();
    super.dispose();
  }

  /// Everything is plotted in mg/dL so one chart can hold both units.
  static double toMgdl(dynamic value, String unit) {
    final parsed = double.tryParse('$value'.replaceAll(',', '.')) ?? 0;
    return unit.toLowerCase().contains('mmol') ? parsed * 18 : parsed;
  }

  static String statusOf(double mgdl) {
    if (mgdl >= 250 || mgdl < 54) return 'critical';
    if (mgdl > 180 || mgdl < 70) return 'out';
    return 'in';
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'critical':
        return K.danger;
      case 'out':
        return K.warn;
      default:
        return K.ok;
    }
  }

  Future<void> _save() async {
    final raw = valueController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);

    if (value == null || value <= 0) {
      kToast(context, S.t(lang, 'glu.invalid'), error: true);
      return;
    }

    final mgdl = toMgdl(value, unit);
    final status = statusOf(mgdl);

    await KhatwaStore.instance.addEntry({
      'type': 'glycemia',
      'date': DateTime.now().toIso8601String(),
      'value': value,
      'glucose': value,
      'unit': unit,
      'moment': moment,
      'note': noteController.text.trim(),
      'level': status == 'in' ? 'none' : (status == 'out' ? 'yellow' : 'red'),
    });

    if (!mounted) return;

    HapticFeedback.mediumImpact();
    valueController.clear();
    noteController.clear();
    setState(() {});

    kToast(
      context,
      status == 'in' ? S.t(lang, 'glu.savedIn') : S.t(lang, 'glu.savedOut'),
      error: status == 'critical',
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = readings;
    final latest = list.isNotEmpty ? list.first : null;

    return KPage(
      title: S.t(lang, 'tool.glycemia'),
      subtitle: S.t(lang, 'glu.subtitle'),
      actions: const [LanguageButton()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          if (latest != null) _hero(latest),
          if (list.length >= 2) ...[
            const SizedBox(height: 16),
            KSectionLabel(S.t(lang, 'glu.trend')),
            KCard(
              padding: const EdgeInsets.fromLTRB(8, 18, 16, 10),
              child: SizedBox(
                height: 190,
                child: _GlucoseChart(
                  readings: list.reversed.take(14).toList(),
                  lang: lang,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          KSectionLabel(S.t(lang, 'glu.add')),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: KField(
                        label: S.t(lang, 'glu.value'),
                        controller: valueController,
                        keyboard: TextInputType.number,
                        hint: unit == 'mg/dL' ? '120' : '6.7',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.t(lang, 'glu.unit'), style: K.bodyStrong),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _Pill(
                                  label: 'mg/dL',
                                  selected: unit == 'mg/dL',
                                  onTap: () => setState(() => unit = 'mg/dL'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _Pill(
                                  label: 'mmol/L',
                                  selected: unit == 'mmol/L',
                                  onTap: () => setState(() => unit = 'mmol/L'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(S.t(lang, 'glu.moment'), style: K.bodyStrong),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in moments)
                      _Pill(
                        label: S.t(lang, 'glu.$option'),
                        selected: moment == option,
                        onTap: () => setState(() => moment = option),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                KField(
                  label: '${S.t(lang, 'glu.note')} (${S.t(lang, 'q.optional')})',
                  controller: noteController,
                ),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(S.t(lang, 'common.save')),
                ),
              ],
            ),
          ),
          if (list.isNotEmpty) ...[
            const SizedBox(height: 18),
            KSectionLabel(S.t(lang, 'home.history')),
            for (final reading in list.take(10))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _row(reading),
              ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _hero(Map<String, dynamic> latest) {
    final mgdl = toMgdl(latest['value'], '${latest['unit'] ?? 'mg/dL'}');
    final status = statusOf(mgdl);
    final color = statusColor(status);
    final date = DateTime.tryParse('${latest['date']}') ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: K.card,
        borderRadius: BorderRadius.circular(K.r20),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.t(lang, 'glu.latest'), style: K.label),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${latest['value']}',
                      style: TextStyle(
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${latest['unit'] ?? 'mg/dL'}', style: K.small),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      status == 'in'
                          ? Icons.check_circle_outline_rounded
                          : status == 'out'
                              ? Icons.error_outline_rounded
                              : Icons.warning_amber_rounded,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        S.t(lang, 'glu.status.$status'),
                        style: K.small.copyWith(color: color, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${S.t(lang, 'glu.${latest['moment'] ?? 'random'}')} · ${_time(date)}',
                  style: K.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Map<String, dynamic> reading) {
    final mgdl = toMgdl(reading['value'], '${reading['unit'] ?? 'mg/dL'}');
    final status = statusOf(mgdl);
    final color = statusColor(status);
    final date = DateTime.tryParse('${reading['date']}') ?? DateTime.now();

    return KCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reading['value']} ${reading['unit'] ?? 'mg/dL'}',
                  style: K.bodyStrong,
                ),
                Text(
                  '${S.t(lang, 'glu.${reading['moment'] ?? 'random'}')} · ${_time(date)}',
                  style: K.small,
                ),
              ],
            ),
          ),
          if ('${reading['note'] ?? ''}'.isNotEmpty)
            const Icon(Icons.sticky_note_2_outlined, size: 17, color: K.muted),
        ],
      ),
    );
  }

  String _time(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m · $h:$min';
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? K.primarySoft : K.card,
          border: Border.all(color: selected ? K.primary : K.line, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? K.primaryDark : K.muted,
          ),
        ),
      ),
    );
  }
}

/// Line chart, oldest to newest, with the target band behind the line.
class _GlucoseChart extends StatelessWidget {
  final List<Map<String, dynamic>> readings;
  final String lang;

  const _GlucoseChart({required this.readings, required this.lang});

  @override
  Widget build(BuildContext context) {
    final values = readings
        .map((r) => _GlycemiaPageState.toMgdl(r['value'], '${r['unit'] ?? 'mg/dL'}'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ChartPainter(values: values),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Row(
            children: [
              Container(width: 14, height: 8, color: K.okSoft),
              const SizedBox(width: 7),
              Text(S.t(lang, 'glu.target'), style: K.small),
              const Spacer(),
              Text(
                '${readings.length} ${S.t(lang, 'glu.readings')}',
                style: K.small,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;

  _ChartPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const leftPad = 34.0;
    const topPad = 10.0;
    const bottomPad = 8.0;

    final plot = Rect.fromLTRB(leftPad, topPad, size.width, size.height - bottomPad);

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final top = (maxValue < 200 ? 220.0 : maxValue + 30).ceilToDouble();
    final bottom = (minValue > 60 ? 50.0 : minValue - 20).floorToDouble();

    double y(double value) =>
        plot.bottom - ((value - bottom) / (top - bottom)) * plot.height;

    double x(int index) => values.length == 1
        ? plot.center.dx
        : plot.left + (index / (values.length - 1)) * plot.width;

    // Target band, recessive, behind everything.
    canvas.drawRect(
      Rect.fromLTRB(plot.left, y(180), plot.right, y(70)),
      Paint()..color = K.okSoft,
    );

    // Grid lines and axis labels.
    final gridPaint = Paint()
      ..color = K.line
      ..strokeWidth = 1;
    for (final value in [70.0, 180.0, top]) {
      final yy = y(value);
      canvas.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), gridPaint);
      _label(canvas, value.toStringAsFixed(0), Offset(2, yy - 7));
    }

    // The line itself.
    final line = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(x(i), y(values[i]));
      if (i == 0) {
        line.moveTo(point.dx, point.dy);
      } else {
        line.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = K.primary,
    );

    // Points: in range stays neutral, out of range takes a status colour and a
    // ring, so the state is never carried by colour alone.
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final status = _GlycemiaPageState.statusOf(value);
      final center = Offset(x(i), y(value));
      final color = _GlycemiaPageState.statusColor(status);

      canvas.drawCircle(center, 5.5, Paint()..color = K.card);
      canvas.drawCircle(
        center,
        status == 'in' ? 3.4 : 4.6,
        Paint()..color = status == 'in' ? K.primary : color,
      );
      if (status != 'in') {
        canvas.drawCircle(
          center,
          7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = color,
        );
      }
    }

    // Direct label on the last point only.
    final lastValue = values.last;
    _label(
      canvas,
      lastValue.toStringAsFixed(0),
      Offset(x(values.length - 1) - 14, y(lastValue) - 24),
      bold: true,
    );
  }

  void _label(Canvas canvas, String text, Offset offset, {bool bold = false}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 11,
          color: bold ? K.ink : K.muted,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.values != values;
}
