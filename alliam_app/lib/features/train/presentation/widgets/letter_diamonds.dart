import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/alliam_colors.dart';

class LetterDiamonds extends StatefulWidget {
  const LetterDiamonds({
    required this.word,
    required this.entered,
    required this.revealWord,
    this.success = false,
    this.activeIndex = -1,
    super.key,
  });

  final String word;
  final String entered;
  final bool revealWord;
  final bool success;
  final int activeIndex;

  @override
  State<LetterDiamonds> createState() => _LetterDiamondsState();
}

class _LetterDiamondsState extends State<LetterDiamonds>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    if (widget.success) {
      _successController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant LetterDiamonds oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.word != oldWidget.word) {
      _entranceController.forward(from: 0);
    }
    if (widget.success && !oldWidget.success) {
      _successController.forward(from: 0);
    } else if (!widget.success && oldWidget.success) {
      _successController.reset();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        const gap = 8.0;
        final diamondSize =
            ((available / widget.word.length - gap) / math.sqrt2).clamp(
              54.6,
              114.4,
            );
        final visualSize = diamondSize * math.sqrt2;

        return Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: 10,
          children: [
            for (var index = 0; index < widget.word.length; index++)
              AnimatedBuilder(
                key: ValueKey('${widget.word}-$index'),
                animation: Listenable.merge([
                  _entranceController,
                  _successController,
                ]),
                builder: (context, child) {
                  final count = widget.word.length;
                  final entranceStart = count <= 1
                      ? 0.0
                      : (index / count) * 0.42;
                  final entranceEnd = math.min(1.0, entranceStart + 0.48);
                  final entranceProgress = CurvedAnimation(
                    parent: _entranceController,
                    curve: Interval(
                      entranceStart,
                      entranceEnd,
                      curve: Curves.easeOutBack,
                    ),
                  ).value;
                  final start = count <= 1 ? 0.0 : (index / count) * 0.56;
                  final end = math.min(1.0, start + 0.38);
                  final progress = CurvedAnimation(
                    parent: _successController,
                    curve: Interval(start, end, curve: Curves.easeOutBack),
                  ).value;
                  final successScale = 1 + (math.sin(progress * math.pi) * 0.2);
                  return Opacity(
                    opacity: entranceProgress.clamp(0, 1),
                    child: Transform.scale(
                      alignment: Alignment.center,
                      scale:
                          (0.72 + entranceProgress * 0.28) *
                          (widget.success ? successScale : 1),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: visualSize,
                  height: visualSize,
                  child: Center(
                    child: Transform.translate(
                      offset: widget.activeIndex == index
                          ? const Offset(0, -6)
                          : Offset.zero,
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeInOutCubic,
                          width: diamondSize,
                          height: diamondSize,
                          decoration: BoxDecoration(
                            color: widget.success
                                ? const Color(0xFFE4F3DF)
                                : AlliamColors.surfaceStrong,
                            borderRadius: BorderRadius.circular(
                              diamondSize * 0.27,
                            ),
                            border:
                                !widget.revealWord &&
                                    index >= widget.entered.length
                                ? null
                                : Border.all(
                                    color: widget.success
                                        ? AlliamColors.success
                                        : AlliamColors.coral,
                                    width: (diamondSize * 0.045).clamp(
                                      2.0,
                                      4.0,
                                    ),
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD7B69B).withValues(
                                  alpha: widget.revealWord ? 0.38 : 0.25,
                                ),
                                blurRadius: widget.revealWord ? 48 : 38,
                                offset: const Offset(14, 22),
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: -math.pi / 4,
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 320),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: Tween<double>(
                                          begin: 0.88,
                                          end: 1,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                child: Text(
                                  widget.revealWord
                                      ? widget.word[index].toUpperCase()
                                      : index < widget.entered.length
                                      ? widget.entered[index].toUpperCase()
                                      : '?',
                                  key: ValueKey(
                                    widget.revealWord
                                        ? widget.word[index]
                                        : index < widget.entered.length
                                        ? widget.entered[index]
                                        : '?',
                                  ),
                                  style: TextStyle(
                                    color:
                                        widget.revealWord ||
                                            index < widget.entered.length
                                        ? widget.success
                                              ? AlliamColors.success
                                              : AlliamColors.coral
                                        : AlliamColors.text.withValues(
                                            alpha: 0.25,
                                          ),
                                    fontFamily: 'Talina DEMO',
                                    fontWeight: FontWeight.w400,
                                    fontSize: diamondSize * 0.56,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
