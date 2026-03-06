import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/fyne_theme.dart';
import '../../providers/navigation_provider.dart';

class FyneBottomNav extends ConsumerWidget {
  final VoidCallback? onAddTap;

  const FyneBottomNav({
    super.key,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? FyneColors.ink : FyneColors.paper,
        border: Border(
          top: BorderSide(
            color: isDark ? FyneColors.dividerDark : FyneColors.paperDark,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isActive: currentIndex == 0,
                  onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 0,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.pie_chart_outline,
                  activeIcon: Icons.pie_chart,
                  label: 'Stats',
                  isActive: currentIndex == 1,
                  onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
                ),
              ),
              _AddButton(onTap: onAddTap ?? () {}),
              Expanded(
                child: _NavItem(
                  icon: Icons.shield_outlined,
                  activeIcon: Icons.shield,
                  label: 'Vault',
                  isActive: currentIndex == 3,
                  onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 3,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  isActive: currentIndex == 4,
                  onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? FyneColors.forest
        : FyneColors.inkLight;

    return SizedBox(
      height: 56,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? FyneColors.forestLight : FyneColors.forest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.add,
            color: isDark ? FyneColors.ink : FyneColors.paper,
            size: 32,
          ),
        ),
      ),
    );
  }
}
