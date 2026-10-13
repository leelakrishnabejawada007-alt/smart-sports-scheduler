import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../providers/scheduler_provider.dart';
import 'facility_list_screen.dart';
import 'my_bookings_screen.dart';

/// Adaptive navigation: bottom bar on phones, side rail on wide screens.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    final pending =
        p.myBookings.where((b) => b.status == BookingStatus.pending).length;

    final pages = IndexedStack(
      index: p.tab,
      children: const [FacilityListScreen(), MyBookingsScreen()],
    );
    final bookingsIcon = Badge(
      isLabelVisible: pending > 0,
      label: Text('$pending'),
      child: const Icon(Icons.event_note_outlined),
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 800) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: p.tab,
                onDestinationSelected: p.setTab,
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Icon(Icons.sports,
                      size: 32, color: Theme.of(context).colorScheme.primary),
                ),
                destinations: [
                  const NavigationRailDestination(
                    icon: Icon(Icons.stadium_outlined),
                    selectedIcon: Icon(Icons.stadium),
                    label: Text('Facilities'),
                  ),
                  NavigationRailDestination(
                    icon: bookingsIcon,
                    label: const Text('My bookings'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: pages),
            ],
          ),
        );
      }
      return Scaffold(
        body: pages,
        bottomNavigationBar: NavigationBar(
          selectedIndex: p.tab,
          onDestinationSelected: p.setTab,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.stadium_outlined),
              selectedIcon: Icon(Icons.stadium),
              label: 'Facilities',
            ),
            NavigationDestination(icon: bookingsIcon, label: 'My bookings'),
          ],
        ),
      );
    });
  }
}
