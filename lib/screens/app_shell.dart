import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/announcement_ticker.dart';
import '../widgets/sidebar_nav.dart';
import '../providers/auth_provider.dart';
import 'admin_screen.dart';
import 'calendar_screen.dart';
import 'facility_list_screen.dart';
import 'favorites_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Desktop: full sidebar · Tablet: icon rail · Mobile: hamburger drawer.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    // Load data after sign-in (also runs when a saved login is restored).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scheduler = context.read<SchedulerProvider>();
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      if (user != null && scheduler.profileName.isEmpty) {
        scheduler.setProfile(user.name, user.studentId);
      }
      scheduler.load();
      if (auth.isAdmin) scheduler.setTab(6); // admins land on the dashboard
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>((a) => a.isAdmin);
    final rawTab = context.select<SchedulerProvider, int>((p) => p.tab);
    final pageCount = isAdmin ? 7 : 6;
    final tab = rawTab >= pageCount ? 0 : rawTab;
    final pages = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.9, -0.9),
          radius: 1.3,
          colors: [Color(0xFFDCEAF8), AppColors.background],
        ),
      ),
      child: IndexedStack(
      index: tab,
      children: [
        const FacilityListScreen(),
        const MyBookingsScreen(),
        const CalendarScreen(),
        const FavoritesScreen(),
        const ProfileScreen(),
        const SettingsScreen(),
        if (isAdmin) const AdminScreen(),
      ],
    ));

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 700) {
        return Scaffold(
          body: Column(
            children: [
              const AnnouncementTicker(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SidebarNav(compact: c.maxWidth < 1100),
                    Expanded(child: pages),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const AppLogo()),
        drawer: const Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(child: SidebarNav(inDrawer: true)),
        ),
        body: Column(children: [const AnnouncementTicker(), Expanded(child: pages)]),
      );
    });
  }
}
