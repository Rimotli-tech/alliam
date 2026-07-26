import 'package:flutter/widgets.dart';

class AlliamLogo extends StatelessWidget {
  const AlliamLogo({this.width = 112, this.color, super.key});

  final double width;
  final Color? color;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/alliam-splash-logo.png',
    width: width,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    color: color,
    colorBlendMode: color == null ? null : BlendMode.srcIn,
  );
}
