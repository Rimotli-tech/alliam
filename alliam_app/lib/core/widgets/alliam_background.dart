import 'package:flutter/material.dart';

import '../theme/alliam_colors.dart';

class AlliamBackground extends StatelessWidget {
  const AlliamBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AlliamColors.canvas),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _GridPainter()),
          child,
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AlliamColors.line.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    final spacing = size.width / 6;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
