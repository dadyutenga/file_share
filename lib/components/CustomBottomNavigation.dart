import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              activeIcon: Icons.home_filled,
              inactiveIcon: Icons.home_outlined,
              label: 'Home',
              index: 0,
            ),
            _buildNavItem(
              activeIcon: Icons.folder_rounded,
              inactiveIcon: Icons.folder_outlined,
              label: 'Files', // Changed from 'Recents'
              index: 1,
            ),
            _buildNavItem(
              activeIcon: Icons.add_circle,
              inactiveIcon: Icons.add_circle_outline,
              label: 'Uploads',
              index: 2,
            ),
            _buildNavItem(
              activeIcon: Icons.settings,
              inactiveIcon: Icons.settings_outlined,
              label: 'Settings',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required int index,
  }) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected
        ? const Color(0xFF007AFF)
        : Colors.grey[400]!;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: color,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
