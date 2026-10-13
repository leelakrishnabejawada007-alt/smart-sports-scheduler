import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/scheduler_provider.dart';
import '../utils/responsive.dart';
import '../widgets/facility_grid.dart';
import '../widgets/message_view.dart';
import '../widgets/page_header.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    final favs = p.favoriteFacilities;

    return LayoutBuilder(builder: (context, c) {
      final pad = pagePadding(c.maxWidth);
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 24, pad, 20),
            sliver: const SliverToBoxAdapter(
              child: PageHeader(
                  title: 'Favorites',
                  subtitle: 'Your saved facilities, ready to book.'),
            ),
          ),
          if (favs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: MessageView(
                icon: Icons.favorite_border,
                title: 'No favorites yet',
                subtitle: 'Tap the heart on a facility to save it here.',
                actionLabel: 'Browse facilities',
                onAction: () => p.setTab(0),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
              sliver: FacilityGridSliver(
                  facilities: favs, columns: gridColumns(c.maxWidth - pad * 2 + 40)),
            ),
        ],
      );
    });
  }
}
