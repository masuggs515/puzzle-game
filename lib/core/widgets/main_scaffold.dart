// lib/core/widgets/main_scaffold.dart
// Phase 9 — MERIDIAN bottom navigation

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/achievements')) return 1;
    if (location.startsWith('/shop')) return 2;
    return 0; // home and everything else
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.ink,
          border: Border(
            top: BorderSide(color: AppColors.signal, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavTab(
              glyph: '\u2316',
              label: 'BASE',
              selected: selectedIndex == 0,
              onTap: () => context.go('/home'),
            ),
            _NavTab(
              glyph: '\u25c8',
              label: 'DOSSIER',
              selected: selectedIndex == 1,
              onTap: () => context.go('/achievements'),
            ),
            _NavTab(
              glyph: '\u25c6',
              label: 'SUPPLY',
              selected: selectedIndex == 2,
              onTap: () => context.go('/shop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final String glyph;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
    required this.glyph,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.signal
        : AppColors.parchment.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              glyph,
              style: TextStyle(fontSize: 18, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SpecialElite',
                fontSize: 8,
                letterSpacing: 1.0,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
