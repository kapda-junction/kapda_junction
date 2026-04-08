import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  static const _items = [
    (icon: Icons.dashboard_outlined,    active: Icons.dashboard,        label: 'Dashboard',  path: '/dashboard'),
    (icon: Icons.inventory_2_outlined,  active: Icons.inventory_2,      label: 'Products',   path: '/products'),
    (icon: Icons.category_outlined,     active: Icons.category,         label: 'Categories', path: '/categories'),
    (icon: Icons.receipt_long_outlined, active: Icons.receipt_long,     label: 'Orders',     path: '/orders'),
    (icon: Icons.local_offer_outlined,  active: Icons.local_offer,      label: 'Coupons',    path: '/coupons'),
    (icon: Icons.assignment_return_outlined, active: Icons.assignment_return, label: 'Returns', path: '/returns'),
    (icon: Icons.star_rate_outlined, active: Icons.star_rate, label: 'Reviews', path: '/reviews'),
    (icon: Icons.image_outlined,        active: Icons.image,            label: 'Banners',    path: '/banners'),
    (icon: Icons.notifications_none,    active: Icons.notifications,    label: 'Notifications', path: '/notifications'),
    (icon: Icons.warehouse_outlined,    active: Icons.warehouse,        label: 'Inventory',  path: '/inventory'),
    (icon: Icons.palette_outlined,      active: Icons.palette,          label: 'Options',    path: '/options'),
    (icon: Icons.settings_outlined,     active: Icons.settings,         label: 'Settings',   path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Drawer(
      width: 260,
      backgroundColor: const Color(0xFF0F172A), // brand dark navy always
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ── Header ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront, color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kapda Junction',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white.withAlpha(120),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 1, thickness: 1),
          const SizedBox(height: 8),

          // ── Nav items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                final isSelected = location.startsWith(item.path);
                return _DrawerItem(
                  icon: isSelected ? item.active : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () {
                    Navigator.of(context).pop(); // close drawer
                    if (!isSelected) context.go(item.path);
                  },
                );
              },
            ),
          ),

          // ── Footer ──
          const Divider(color: Color(0xFF1E293B), height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              top: false,
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                isSelected: false,
                isDestructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/login');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isDestructive
        ? const Color(0xFFFCA5A5)
        : isSelected
            ? AppColors.accent
            : const Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent.withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.accent.withAlpha(60), width: 1)
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withAlpha(30),
        highlightColor: color.withAlpha(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
