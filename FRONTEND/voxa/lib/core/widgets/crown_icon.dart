import 'package:flutter/material.dart';

class CrownIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CrownIcon({
    super.key,
    this.size = 22.0,
    this.color = const Color(0xFFE5A800),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CrownPainter(color: color)),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final Color color;

  _CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.18, h * 0.38)
      ..lineTo(w * 0.22, h * 0.68)
      ..lineTo(w * 0.78, h * 0.68)
      ..lineTo(w * 0.82, h * 0.38)
      ..lineTo(w * 0.66, h * 0.48)
      ..lineTo(w * 0.50, h * 0.22)
      ..lineTo(w * 0.34, h * 0.48)
      ..close();

    canvas.drawPath(path, paint);

    canvas.drawLine(
      Offset(w * 0.22, h * 0.82),
      Offset(w * 0.78, h * 0.82),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
