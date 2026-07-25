import 'package:flutter/material.dart';

class AppleLogo extends StatelessWidget {
  const AppleLogo({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AppleLogoPainter(color: color ?? Theme.of(context).colorScheme.onSurface),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  _AppleLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.398, 0)
      ..cubicTo(size.width * 0.44, size.width * 0.073, size.width * 0.494, size.width * 0.203, size.width * 0.523, size.width * 0.203)
      ..cubicTo(size.width * 0.551, size.width * 0.203, size.width * 0.604, size.width * 0.062, size.width * 0.652, 0)
      ..cubicTo(size.width * 0.702, 0, size.width * 0.777, size.width * 0.03, size.width * 0.825, size.width * 0.106)
      ..cubicTo(size.width * 0.868, size.width * 0.174, size.width * 0.895, size.width * 0.273, size.width * 0.895, size.width * 0.392)
      ..cubicTo(size.width * 0.895, size.width * 0.533, size.width * 0.815, size.width * 0.635, size.width * 0.811, size.width * 0.64)
      ..cubicTo(size.width * 0.77, size.width * 0.728, size.width * 0.706, size.width * 0.824, size.width * 0.602, size.width * 0.824)
      ..cubicTo(size.width * 0.549, size.width * 0.824, size.width * 0.518, size.width * 0.793, size.width * 0.465, size.width * 0.793)
      ..cubicTo(size.width * 0.413, size.width * 0.793, size.width * 0.374, size.width * 0.824, size.width * 0.327, size.width * 0.824)
      ..cubicTo(size.width * 0.222, size.width * 0.824, size.width * 0.144, size.width * 0.719, size.width * 0.102, size.width * 0.634)
      ..cubicTo(size.width * 0.053, size.width * 0.533, size.width * 0.018, size.width * 0.358, size.width * 0.018, size.width * 0.256)
      ..cubicTo(size.width * 0.018, size.width * 0.125, size.width * 0.049, size.width * 0.034, size.width * 0.102, size.width * 0.034)
      ..cubicTo(size.width * 0.143, size.width * 0.034, size.width * 0.199, size.width * 0.062, size.width * 0.233, size.width * 0.062)
      ..cubicTo(size.width * 0.265, size.width * 0.062, size.width * 0.328, 0, size.width * 0.398, 0)
      ..close();

    // Body (apple shape)
    canvas.drawPath(path, paint);

    // Leaf
    final leafPath = Path()
      ..moveTo(size.width * 0.655, size.width * 0.072)
      ..cubicTo(size.width * 0.715, size.width * 0.02, size.width * 0.77, size.width * 0.005, size.width * 0.831, 0)
      ..cubicTo(size.width * 0.81, size.width * 0.047, size.width * 0.763, size.width * 0.113, size.width * 0.685, size.width * 0.161)
      ..cubicTo(size.width * 0.667, size.width * 0.144, size.width * 0.665, size.width * 0.107, size.width * 0.655, size.width * 0.072)
      ..close();

    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(covariant _AppleLogoPainter oldDelegate) => color != oldDelegate.color;
}
