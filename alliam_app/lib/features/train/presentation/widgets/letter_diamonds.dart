import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/alliam_colors.dart';

class LetterDiamonds extends StatefulWidget {
  const LetterDiamonds({
    required this.word,
    required this.entered,
    required this.revealWord,
    this.success = false,
    this.incorrect = false,
    this.compact = false,
    this.activeIndex = -1,
    super.key,
  });

  final String word;
  final String entered;
  final bool revealWord;
  final bool success;
  final bool incorrect;
  final bool compact;
  final int activeIndex;

  @override
  State<LetterDiamonds> createState() => _LetterDiamondsState();
}

class _LetterDiamondsState extends State<LetterDiamonds>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _successController;
  late final AnimationController _pulseController;
  late final AnimationController _incorrectController;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _incorrectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    if (widget.activeIndex >= 0) _pulseController.repeat();
    if (widget.success) {
      _successController.forward();
    }
    if (widget.incorrect) {
      _incorrectController.forward();
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
    if (widget.incorrect && !oldWidget.incorrect) {
      _incorrectController.forward(from: 0);
    } else if (!widget.incorrect && oldWidget.incorrect) {
      _incorrectController.reset();
    }
    if (widget.activeIndex >= 0 && oldWidget.activeIndex < 0) {
      _pulseController.repeat();
    } else if (widget.activeIndex < 0 && oldWidget.activeIndex >= 0) {
      _pulseController
        ..stop()
        ..reset();
    } else if (widget.activeIndex != oldWidget.activeIndex &&
        widget.activeIndex >= 0) {
      _pulseController
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _successController.dispose();
    _pulseController.dispose();
    _incorrectController.dispose();
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
              widget.compact ? 40.0 : 54.6,
              widget.compact ? 70.0 : 114.4,
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
                  _pulseController,
                  _incorrectController,
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
                  final active = widget.activeIndex == index;
                  final pulse = _pulseController.value;
                  final spokenScale = active
                      ? 1 + math.sin(pulse * math.pi) * 0.14
                      : 1.0;
                  final incorrectProgress = _incorrectController.value;
                  final wrongLetter =
                      index >= widget.entered.length ||
                      widget.entered[index].toLowerCase() !=
                          widget.word[index].toLowerCase();
                  final jitterProgress = (incorrectProgress / 0.16).clamp(
                    0.0,
                    1.0,
                  );
                  final jitter = widget.incorrect && incorrectProgress < 0.16
                      ? math.sin(jitterProgress * math.pi * 8) *
                            9 *
                            (1 - jitterProgress)
                      : 0.0;
                  final wrongScaleProgress = ((incorrectProgress - 0.14) / 0.10)
                      .clamp(0.0, 1.0);
                  final wrongScale =
                      widget.incorrect &&
                          wrongLetter &&
                          incorrectProgress >= 0.14 &&
                          incorrectProgress < 0.82
                      ? 1 +
                            Curves.easeOutBack.transform(wrongScaleProgress) *
                                0.22
                      : 1.0;
                  final diamond = Transform.scale(
                    scale: spokenScale,
                    child: child,
                  );
                  return Transform.translate(
                    offset: Offset(jitter, 0),
                    child: Opacity(
                      opacity: entranceProgress.clamp(0, 1),
                      child: Transform.scale(
                        alignment: Alignment.center,
                        scale:
                            (0.72 + entranceProgress * 0.28) *
                            (widget.success ? successScale : 1) *
                            wrongScale,
                        child: active
                            ? Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  for (final phase in const [0.0, 0.42])
                                    Opacity(
                                      opacity:
                                          (1 - ((pulse + phase) % 1.0)).clamp(
                                            0.0,
                                            1.0,
                                          ) *
                                          0.55,
                                      child: Transform.scale(
                                        scale:
                                            1 + ((pulse + phase) % 1.0) * 0.38,
                                        child: Transform.rotate(
                                          angle: math.pi / 4,
                                          child: Container(
                                            width: diamondSize,
                                            height: diamondSize,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    diamondSize * 0.27,
                                                  ),
                                              border: Border.all(
                                                color: AlliamColors.coral,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  diamond,
                                ],
                              )
                            : diamond,
                      ),
                    ),
                  );
                },
                child: AnimatedBuilder(
                  animation: _incorrectController,
                  builder: (context, _) => SizedBox(
                    width: visualSize,
                    height: visualSize,
                    child: Center(
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
                                : widget.incorrect &&
                                      _incorrectController.value < 0.16
                                ? const Color(0xFFFFE4E1)
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
                                        : widget.incorrect &&
                                              _incorrectController.value < 0.16
                                        ? const Color(0xFFD7372F)
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
                                  widget.revealWord &&
                                          (!widget.incorrect ||
                                              _incorrectController.value >=
                                                  0.80)
                                      ? widget.word[index].toUpperCase()
                                      : index < widget.entered.length
                                      ? widget.entered[index].toUpperCase()
                                      : '?',
                                  key: ValueKey(
                                    widget.revealWord &&
                                            (!widget.incorrect ||
                                                _incorrectController.value >=
                                                    0.80)
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
                                              : widget.incorrect &&
                                                    _incorrectController.value <
                                                        0.16
                                              ? const Color(0xFFD7372F)
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
