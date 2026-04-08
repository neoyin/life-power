import 'package:flutter/material.dart';
import 'package:life_power_client/core/i18n.dart';

class MainNavigationBar extends StatelessWidget {
  final int currentIndex;

  const MainNavigationBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2a3435).withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.bolt, tr('nav_home'), '/'),
              _buildNavItem(context, 1, Icons.battery_charging_full, tr('nav_charge'), '/charge'),
              _buildNavItem(context, 2, Icons.group, tr('nav_watching'), '/watchers'),
              _buildNavItem(context, 3, Icons.settings, tr('nav_settings'), '/settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, String route) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFd7e3f7).withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF535f6f)
                  : const Color(0xFF727d7e),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF535f6f)
                    : const Color(0xFF727d7e),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
