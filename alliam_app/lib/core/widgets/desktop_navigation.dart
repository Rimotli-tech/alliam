import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../admin/admin_access.dart';
import '../audio/sound_effects_service.dart';
import '../theme/alliam_colors.dart';
import 'alliam_logo.dart';

class DesktopNavigation extends StatefulWidget {
  const DesktopNavigation({required this.currentPath, super.key});

  final String currentPath;

  @override
  State<DesktopNavigation> createState() => _DesktopNavigationState();
}

class _DesktopNavigationState extends State<DesktopNavigation> {
  static bool? _rememberedCollapsed;
  bool _initialized = false;
  late bool _collapsed;
  Future<bool>? _adminAccess;

  static const _destinations = [
    (Icons.home_outlined, 'Home', '/home'),
    (Icons.route_rounded, 'Pathway', '/pathway'),
    (Icons.fitness_center_rounded, 'Train', '/train'),
    (Icons.sports_kabaddi_rounded, 'Compete', '/compete'),
    (Icons.leaderboard_outlined, 'Rankings', '/rankings'),
    (Icons.groups_outlined, 'Friends & teams', '/social'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _collapsed =
        _rememberedCollapsed ?? MediaQuery.sizeOf(context).width < 1200;
    _adminAccess = AdminAccess.ensureAdmin();
    _initialized = true;
  }

  bool _selected(String path) {
    if (path == '/home') return widget.currentPath == path;
    return widget.currentPath == path ||
        widget.currentPath.startsWith('$path/');
  }

  void _toggle() {
    setState(() {
      _collapsed = !_collapsed;
      _rememberedCollapsed = _collapsed;
    });
  }

  void _navigate(String path) {
    if (widget.currentPath == path) return;
    unawaited(SoundEffectsService.instance.back());
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final owner =
        (user?.displayName?.trim().isNotEmpty == true
                ? user!.displayName!
                : user?.email?.split('@').first ?? 'Profile')
            .trim();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: _collapsed ? 78 : 242,
      margin: const EdgeInsets.fromLTRB(18, 18, 0, 18),
      decoration: BoxDecoration(
        color: AlliamColors.coral,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AlliamColors.coral.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              _collapsed ? 17 : 20,
              22,
              _collapsed ? 17 : 14,
              18,
            ),
            child: Row(
              children: [
                if (!_collapsed)
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AlliamLogo(width: 105, color: Colors.white),
                    ),
                  ),
                IconButton(
                  tooltip: _collapsed
                      ? 'Expand navigation'
                      : 'Collapse navigation',
                  onPressed: _toggle,
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.13),
                  ),
                  icon: AnimatedRotation(
                    turns: _collapsed ? 0.5 : 0,
                    duration: const Duration(milliseconds: 320),
                    child: const Icon(Icons.chevron_left_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final destination in _destinations)
            _NavigationItem(
              collapsed: _collapsed,
              selected: _selected(destination.$3),
              icon: destination.$1,
              label: destination.$2,
              onTap: () => _navigate(destination.$3),
            ),
          FutureBuilder<bool>(
            future: _adminAccess,
            builder: (context, snapshot) => snapshot.data == true
                ? _NavigationItem(
                    collapsed: _collapsed,
                    selected: _selected('/admin'),
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin',
                    onTap: () => _navigate('/admin'),
                  )
                : const SizedBox.shrink(),
          ),
          const Spacer(),
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: _collapsed ? 18 : 24),
            color: Colors.white.withValues(alpha: 0.24),
          ),
          const SizedBox(height: 14),
          _NavigationItem(
            collapsed: _collapsed,
            selected: widget.currentPath.startsWith('/profile'),
            icon: Icons.person_outline_rounded,
            label: owner,
            onTap: () => _navigate('/profile'),
          ),
          _NavigationItem(
            collapsed: _collapsed,
            selected: widget.currentPath.startsWith('/settings'),
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => _navigate('/settings'),
          ),
          _NavigationItem(
            collapsed: _collapsed,
            selected: false,
            icon: Icons.logout_rounded,
            label: 'Sign out',
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.collapsed,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool collapsed;
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 14, vertical: 4),
    child: Tooltip(
      message: collapsed ? label : '',
      child: Material(
        color: selected ? AlliamColors.canvas : Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          hoverColor: Colors.white.withValues(alpha: 0.12),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (!collapsed) const SizedBox(width: 16),
                Icon(
                  icon,
                  size: 21,
                  color: selected ? AlliamColors.coral : Colors.white,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? AlliamColors.coral : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
