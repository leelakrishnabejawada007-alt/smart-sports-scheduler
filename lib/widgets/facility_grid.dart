import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/facility.dart';
import '../providers/scheduler_provider.dart';
import '../screens/facility_detail_screen.dart';
import '../utils/routes.dart';
import 'booking_modal.dart';
import 'facility_card.dart';

/// Responsive sliver grid of facility cards (used by Facilities + Favorites).
class FacilityGridSliver extends StatelessWidget {
  const FacilityGridSliver(
      {super.key, required this.facilities, required this.columns});
  final List<Facility> facilities;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: 304,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final f = facilities[i];
          return FacilityCard(
            facility: f,
            freeToday: p.availableCount(f, p.today),
            isFavorite: p.isFavorite(f.id),
            onTap: () => Navigator.push(
                ctx, slideRoute(FacilityDetailScreen(facility: f))),
            onBook: () => showBookingModal(ctx, f),
            onFavorite: () => p.toggleFavorite(f.id),
          );
        },
        childCount: facilities.length,
      ),
    );
  }
}
