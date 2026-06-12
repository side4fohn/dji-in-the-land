import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/telemetry_manager.dart';

class AttitudeIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TelemetryManager>(
      builder: (context, t, _) => CustomPaint(
        painter: _AttitudePainter(
          pitch: 0,
          roll: 0,
          yaw: 0,
          altitude: t.altitude,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _AttitudePainter extends CustomPainter {
  final double pitch;
  final double roll;
  final double yaw;
  final double altitude;

  _AttitudePainter({
    required this.pitch,
    required this.roll,
    required this.yaw,
    required this.altitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final sphereR = outerR * 0.68;

    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), outerR, bgPaint);

    final pixelsPerDeg = sphereR / 45;
    final horizonOffset = pitch * pixelsPerDeg;

    canvas.save();
    canvas.clipRect(Rect.fromCircle(center: Offset(cx, cy), radius: sphereR));
    canvas.rotate(-roll * math.pi / 180);

    final skyPaint = Paint()..color = const Color(0xFF1E88E5);
    canvas.drawRect(Rect.fromLTRB(
        cx - sphereR, cy - sphereR + horizonOffset,
        cx + sphereR, cy + horizonOffset), skyPaint);

    final groundPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTRB(
        cx - sphereR, cy + horizonOffset,
        cx + sphereR, cy + sphereR), groundPaint);

    final horizonPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    canvas.drawLine(Offset(cx - sphereR, cy - horizonOffset),
        Offset(cx + sphereR, cy - horizonOffset), horizonPaint);

    canvas.restore();

    final ringPaint = Paint()
      ..color = const Color(0xFF448AFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), sphereR, ringPaint);
    canvas.drawCircle(Offset(cx, cy), outerR, ringPaint);

    final centerPaint = Paint()
      ..color = const Color(0xFFFF5722)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _AttitudePainter old) =>
      old.pitch != pitch || old.roll != roll || old.yaw != yaw;
}
