import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

enum FootSide { right, left }

enum FootView { sole, top }

/// Stylised foot outline, built in a normalised box and scaled to fit.
/// Used by the capture guide, the sensory map and the empty states, so the
/// same shape appears everywhere in the app.
class FootShape {
  static Path outline(Size size, FootSide side) {
    // Normalised control points for a right sole, x to the right, y downwards.
    const points = <Offset>[
      Offset(0.50, 0.985), // heel centre
      Offset(0.26, 0.955),
      Offset(0.175, 0.80),
      Offset(0.205, 0.60),
      Offset(0.265, 0.475),
      Offset(0.235, 0.345),
      Offset(0.245, 0.215),
      Offset(0.345, 0.135),
      Offset(0.50, 0.115),
      Offset(0.665, 0.135),
      Offset(0.775, 0.225),
      Offset(0.775, 0.36),
      Offset(0.80, 0.50),
      Offset(0.835, 0.70),
      Offset(0.79, 0.90),
    ];

    final path = Path();
    final scaled = points
        .map((p) => Offset(
              (side == FootSide.left ? 1 - p.dx : p.dx) * size.width,
              p.dy * size.height,
            ))
        .toList();

    path.moveTo(scaled.first.dx, scaled.first.dy);
    for (var i = 0; i < scaled.length; i++) {
      final current = scaled[i];
      final next = scaled[(i + 1) % scaled.length];
      final mid = Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  /// Toe pads, drawn only for the sole view.
  static List<Rect> toes(Size size, FootSide side) {
    const layout = <List<double>>[
      // dx, dy, rx, ry  (normalised, right foot)
      [0.325, 0.088, 0.058, 0.045],
      [0.435, 0.062, 0.050, 0.040],
      [0.535, 0.058, 0.047, 0.038],
      [0.630, 0.070, 0.043, 0.035],
      [0.715, 0.098, 0.038, 0.031],
    ];

    return layout.map((t) {
      final dx = (side == FootSide.left ? 1 - t[0] : t[0]) * size.width;
      final dy = t[1] * size.height;
      return Rect.fromCenter(
        center: Offset(dx, dy),
        width: t[2] * 2 * size.width,
        height: t[3] * 2 * size.height,
      );
    }).toList();
  }
}

/// The camera overlay: everything outside the foot is dimmed, the outline
/// breathes while you frame, and turns solid green the moment the shot is taken.
class FootGuidePainter extends CustomPainter {
  final FootSide side;
  final FootView view;
  final double pulse; // 0..1 animation value
  final bool locked; // true right after a successful capture

  FootGuidePainter({
    required this.side,
    required this.view,
    required this.pulse,
    required this.locked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boxWidth = math.min(size.width * 0.62, size.height * 0.42);
    final boxHeight = boxWidth * 2.05;
    final origin = Offset(
      (size.width - boxWidth) / 2,
      (size.height - boxHeight) / 2,
    );
    final box = Size(boxWidth, boxHeight);

    final path = FootShape.outline(box, side).shift(origin);

    // Dim everything outside the foot.
    final scrim = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addPath(path, Offset.zero)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      scrim,
      Paint()..color = const Color(0xCC0B1A1E),
    );

    final accent = locked ? K.ok : Colors.white;

    // Soft glow inside the outline.
    canvas.drawPath(
      path,
      Paint()
        ..color = locked
            ? K.ok.withAlpha(46)
            : Colors.white.withAlpha((14 + 14 * pulse).round()),
    );

    // The outline itself.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = locked ? 4 : 2.6 + pulse * 1.4
        ..color = locked ? K.ok : accent.withAlpha((170 + 70 * pulse).round()),
    );

    if (view == FootView.sole) {
      final toePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = (locked ? K.ok : Colors.white).withAlpha(130);
      for (final toe in FootShape.toes(box, side)) {
        canvas.drawOval(toe.shift(origin), toePaint);
      }
    } else {
      // Ankle line for the top view.
      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = (locked ? K.ok : Colors.white).withAlpha(130);
      final y = origin.dy + boxHeight * 0.78;
      canvas.drawLine(
        Offset(origin.dx + boxWidth * 0.22, y),
        Offset(origin.dx + boxWidth * 0.78, y),
        linePaint,
      );
    }

    // Corner brackets around the frame, the familiar "align here" cue.
    _brackets(canvas, Rect.fromLTWH(origin.dx, origin.dy, boxWidth, boxHeight), accent);
  }

  void _brackets(Canvas canvas, Rect rect, Color color) {
    final inflated = rect.inflate(18);
    const len = 26.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withAlpha(locked ? 235 : 150);

    void corner(Offset a, Offset b, Offset c) {
      canvas.drawLine(a, b, paint);
      canvas.drawLine(b, c, paint);
    }

    corner(
      inflated.topLeft + const Offset(0, len),
      inflated.topLeft,
      inflated.topLeft + const Offset(len, 0),
    );
    corner(
      inflated.topRight + const Offset(-len, 0),
      inflated.topRight,
      inflated.topRight + const Offset(0, len),
    );
    corner(
      inflated.bottomRight + const Offset(0, -len),
      inflated.bottomRight,
      inflated.bottomRight + const Offset(-len, 0),
    );
    corner(
      inflated.bottomLeft + const Offset(len, 0),
      inflated.bottomLeft,
      inflated.bottomLeft + const Offset(0, -len),
    );
  }

  @override
  bool shouldRepaint(covariant FootGuidePainter old) =>
      old.pulse != pulse || old.locked != locked || old.side != side || old.view != view;
}

/// Small foot icon used in the capture chips and the history rows.
class FootBadgePainter extends CustomPainter {
  final FootSide side;
  final Color color;
  final bool filled;

  FootBadgePainter({required this.side, required this.color, this.filled = false});

  @override
  void paint(Canvas canvas, Size size) {
    final box = Size(size.width * 0.52, size.height * 0.88);
    final origin = Offset((size.width - box.width) / 2, (size.height - box.height) / 2);
    final path = FootShape.outline(box, side).shift(origin);

    canvas.drawPath(
      path,
      Paint()
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant FootBadgePainter old) =>
      old.color != color || old.filled != filled || old.side != side;
}

/// Four segments that fill as the positions are captured, the Face ID cue.
class CaptureRingPainter extends CustomPainter {
  final int total;
  final List<bool> done;
  final int active;

  CaptureRingPainter({required this.total, required this.done, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: math.min(size.width, size.height) / 2 - 4,
    );

    const gap = 0.14;
    final sweep = (2 * math.pi / total) - gap;

    for (var i = 0; i < total; i++) {
      final start = -math.pi / 2 + i * (2 * math.pi / total) + gap / 2;
      final isDone = i < done.length && done[i];

      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = isDone ? 5 : 3.5
          ..color = isDone
              ? K.ok
              : (i == active ? Colors.white : Colors.white.withAlpha(70)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CaptureRingPainter old) =>
      old.done != done || old.active != active;
}
