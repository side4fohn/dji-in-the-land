import 'package:flutter/material.dart';

class VideoOverlay extends StatelessWidget {
  const VideoOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _OverlayPainter(),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;

    // Crosshair
    const crossSize = 18.0;
    const gap = 6.0;

    // Horizontal lines with gap
    canvas.drawLine(Offset(cx - crossSize, cy), Offset(cx - gap, cy), paint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + crossSize, cy), paint);

    // Vertical lines with gap
    canvas.drawLine(Offset(cx, cy - crossSize), Offset(cx, cy - gap), paint);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + crossSize), paint);

    // Center circle
    paint.style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), 12, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
