import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/facility.dart';
import '../providers/scheduler_provider.dart';
import '../utils/responsive.dart';
import '../widgets/contact_section.dart';
import '../widgets/facility_grid.dart';
import '../widgets/filter_pill.dart';
import '../widgets/message_view.dart';
import '../widgets/page_header.dart';
import '../widgets/skeleton.dart';
import '../widgets/smart_cards.dart';

class FacilityListScreen extends StatefulWidget {
  const FacilityListScreen({super.key});

  @override
  State<FacilityListScreen> createState() => _FacilityListScreenState();
}

class _FacilityListScreenState extends State<FacilityListScreen> {
  String? _sport; // null = all

  bool _matches(Facility f, String q) =>
      q.isEmpty ||
      f.name.toLowerCase().contains(q) ||
      f.location.toLowerCase().contains(q) ||
      f.sport.toLowerCase().contains(q) ||
      f.amenities.any((a) => a.toLowerCase().contains(q));

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    final sports = p.facilities.map((f) => f.sport).toSet().toList()..sort();
    final shown = p.facilities
        .where((f) => (_sport == null || f.sport == _sport) && _matches(f, p.query))
        .toList();

    return LayoutBuilder(builder: (context, c) {
      final pad = pagePadding(c.maxWidth);
      final cols = gridColumns(c.maxWidth - pad * 2 + 40);
      final ready = !p.loading && p.error == null;

      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 24, pad, 20),
            sliver: const SliverToBoxAdapter(
              child: PageHeader(
                title: 'Sports Facilities',
                subtitle: 'Find and book the perfect sports facility for your game.',
                search: true,
              ),
            ),
          ),
          if (ready)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 20),
              sliver: const SliverToBoxAdapter(child: SmartInsights()),
            ),
          if (ready)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  children: [
                    for (final s in [null, ...sports])
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: FilterPill(
                          label: s ?? 'All',
                          selected: _sport == s,
                          onTap: () => setState(() => _sport = s),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (p.loading)
            SliverPadding(
              padding: EdgeInsets.all(pad),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisExtent: 304,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                delegate: SliverChildBuilderDelegate(
                    (_, __) => const FacilityCardSkeleton(),
                    childCount: 6),
              ),
            )
          else if (p.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: MessageView(
                icon: Icons.wifi_off,
                title: 'Something went wrong',
                subtitle: p.error,
                actionLabel: 'Retry',
                onAction: p.load,
              ),
            )
          else if (shown.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: MessageView(
                icon: Icons.search_off,
                title: 'No facilities found',
                subtitle: 'Try another sport or a different search.',
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(pad),
              sliver: FacilityGridSliver(facilities: shown, columns: cols),
            ),
          if (ready)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, pad),
              sliver: const SliverToBoxAdapter(child: ContactSection()),
            ),
        ],
      );
    });
  }
}
