import 'package:flutter/material.dart';

import '../theme/alliam_colors.dart';

enum AlliamCardVariant { home, training, arena }

class AlliamCard extends StatefulWidget {
  const AlliamCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.variant = AlliamCardVariant.home,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final AlliamCardVariant variant;

  @override
  State<AlliamCard> createState() => _AlliamCardState();
}

class _AlliamCardState extends State<AlliamCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final training = widget.variant == AlliamCardVariant.training;
    final arena = widget.variant == AlliamCardVariant.arena;
    final radius = training
        ? 30.0
        : arena
        ? 36.0
        : 32.0;
    final borderWidth = training
        ? 5.0
        : arena
        ? 6.0
        : 4.0;
    final iconSize = training
        ? 42.0
        : arena
        ? 44.0
        : 31.0;
    final iconBox = training || arena ? 54.0 : 42.0;
    final titleSize = training ? 17.0 : 20.0;
    final subtitleSize = training ? 12.0 : 13.0;
    final normalShadow = training
        ? const BoxShadow(
            color: Color(0x1F948D87),
            blurRadius: 24,
            offset: Offset(8, 18),
          )
        : arena
        ? const BoxShadow(
            color: Color(0x24948D87),
            blurRadius: 11,
            offset: Offset(8, 22),
          )
        : const BoxShadow(
            color: Color(0x24948D87),
            blurRadius: 22,
            offset: Offset(9, 14),
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: _hovered ? AlliamColors.surfaceStrong : AlliamColors.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: _hovered
                ? const Color(0xFFFFD4C7)
                : training || arena
                ? AlliamColors.line
                : const Color(0xFFEEE5DE),
            width: borderWidth,
          ),
          boxShadow: [
            if (_hovered)
              const BoxShadow(color: Color(0x47948D87), blurRadius: 32)
            else
              normalShadow,
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(radius - borderWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHome =
                    widget.variant == AlliamCardVariant.home &&
                    constraints.maxHeight < 165;
                return Padding(
                  padding: training
                      ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                      : compactHome
                      ? const EdgeInsets.symmetric(horizontal: 10, vertical: 11)
                      : const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: compactHome ? 34 : iconBox,
                        height: compactHome ? 34 : iconBox,
                        child: Icon(
                          widget.icon,
                          color: AlliamColors.coral,
                          size: compactHome ? 27 : iconSize,
                        ),
                      ),
                      SizedBox(
                        height: training
                            ? 5
                            : arena
                            ? 13
                            : compactHome
                            ? 5
                            : 8,
                      ),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AlliamColors.coral,
                              fontSize: titleSize,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(
                        height: training
                            ? 2
                            : arena
                            ? 4
                            : compactHome
                            ? 4
                            : 8,
                      ),
                      Flexible(
                        child: Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AlliamColors.text,
                                fontSize: subtitleSize,
                                height: training ? 1.22 : 1.2,
                                fontWeight: arena ? FontWeight.w500 : null,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
