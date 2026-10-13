import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/contact_info.dart';
import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';

/// Slim dark strip with scrolling highlights at the very top of the app.
class AnnouncementTicker extends StatefulWidget {
  const AnnouncementTicker({super.key});

  @override
  State<AnnouncementTicker> createState() => _AnnouncementTickerState();
}

class _AnnouncementTickerState extends State<AnnouncementTicker> {
  final _controller = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (_controller.hasClients) _controller.jumpTo(_controller.offset + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    final free = p.facilities.fold<int>(0, (a, f) => a + p.availableCount(f, p.today));
    final items = [
      'Welcome to SportScheduler: book courts, fields and halls online',
      if (p.facilities.isNotEmpty)
        '$free slots free today across ${p.facilities.length} facilities',
      'Need help? Call ${ContactInfo.phones.first}',
    ];

    return Container(
      height: 34,
      color: AppColors.slate,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: AppColors.blueLight),
                const SizedBox(width: 10),
                Text(items[i % items.length].toUpperCase(),
                    style: AppText.label(10.5,
                        color: Colors.white, weight: FontWeight.w700, spacing: 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
