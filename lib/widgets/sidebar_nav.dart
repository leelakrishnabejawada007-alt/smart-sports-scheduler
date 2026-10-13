import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../providers/auth_provider.dart';
import '../providers/scheduler_provider.dart';
import '../utils/session.dart';
import '../theme/app_theme.dart';
import 'surface.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false, this.light = false});
  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: light ? Colors.white : AppColors.blue,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.sports_score,
                color: light ? AppColors.blue : Colors.white, size: 22),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'SPORT',
                      style: AppText.display(17,
                          color: light ? Colors.white : AppColors.slate)),
                  TextSpan(
                      text: 'SCHEDULER',
                      style: AppText.display(17,
                          color: light ? AppColors.blueLight : AppColors.blue)),
                ])),
              ],
            ),
          ],
        ],
      );
}

/// Left navigation. Full width on desktop, icon-only on tablet,
/// and shown inside a Drawer (hamburger) on mobile.
class SidebarNav extends StatelessWidget {
  const SidebarNav({super.key, this.compact = false, this.inDrawer = false});
  final bool compact;
  final bool inDrawer;

  static const _baseItems = [
    (Icons.stadium_outlined, Icons.stadium, 'Facilities'),
    (Icons.event_note_outlined, Icons.event_note, 'My Bookings'),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'Calendar'),
    (Icons.favorite_border, Icons.favorite, 'Favorites'),
    (Icons.person_outline, Icons.person, 'Profile'),
    (Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    final pending =
        p.myBookings.where((b) => b.status == BookingStatus.pending).length;

    final admin = context.watch<AuthProvider>().isAdmin;
    final items = [
      ..._baseItems,
      if (admin)
        (
          Icons.admin_panel_settings_outlined,
          Icons.admin_panel_settings,
          'Admin'
        ),
    ];

    final content = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      padding:
          EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(left: compact ? 0 : 4, bottom: 24),
            child: Align(
                alignment: compact ? Alignment.center : Alignment.centerLeft,
                child: AppLogo(compact: compact)),
          ),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _NavItem(
                icon: items[i].$1,
                activeIcon: items[i].$2,
                label: items[i].$3,
                active: p.tab == i,
                compact: compact,
                badge: i == 1 ? pending : 0,
                onTap: () {
                  p.setTab(i);
                  if (inDrawer) Navigator.of(context).pop();
                },
              ),
            ),
          const Spacer(),
          _UserFooter(
            compact: compact,
            onLogout: () {
              if (inDrawer) Navigator.of(context).pop();
              logOut(context);
            },
          ),
        ],
      ),
    );
    return inDrawer
        ? content
        : SizedBox(width: compact ? 84 : 248, child: content);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.compact,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool compact;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Badge(
      isLabelVisible: badge > 0,
      label: Text('$badge'),
      child: Icon(active ? activeIcon : icon,
          size: 22, color: active ? AppColors.blue : AppColors.muted),
    );
    final item = HoverBuilder(
      builder: (context, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: active
              ? AppColors.softBlue
              : hovered
                  ? AppColors.tint
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 0 : 14, vertical: 12),
              child: compact
                  ? Center(child: iconWidget)
                  : Row(
                      children: [
                        iconWidget,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(label.toUpperCase(),
                              style: AppText.label(12,
                                  color:
                                      active ? AppColors.blue : AppColors.text,
                                  weight: active
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  spacing: 0.8)),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
    return compact ? Tooltip(message: label, child: item) : item;
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter({required this.compact, required this.onLogout});
  final bool compact;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (compact) {
      return Tooltip(
        message: 'Log out',
        child: IconButton(
          onPressed: onLogout,
          icon: const Icon(Icons.logout, color: AppColors.muted),
        ),
      );
    }
    final parts = (user?.name ?? '')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .toList();
    final initials =
        parts.isEmpty ? 'S' : parts.map((s) => s[0].toUpperCase()).join();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: AppColors.tint, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.softBlue,
            child: Text(initials,
                style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Student',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(user?.email ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            visualDensity: VisualDensity.compact,
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 20, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
