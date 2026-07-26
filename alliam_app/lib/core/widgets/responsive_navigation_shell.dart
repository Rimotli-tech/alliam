import 'package:flutter/material.dart';

import '../theme/alliam_colors.dart';
import 'desktop_navigation.dart';

class ResponsiveNavigationShell extends StatelessWidget {
  const ResponsiveNavigationShell({
    required this.currentPath,
    required this.child,
    super.key,
  });

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 900) return child;
      return ColoredBox(
        color: AlliamColors.canvas,
        child: Row(
          children: [
            DesktopNavigation(currentPath: currentPath),
            const SizedBox(width: 18),
            Expanded(child: child),
          ],
        ),
      );
    },
  );
}
