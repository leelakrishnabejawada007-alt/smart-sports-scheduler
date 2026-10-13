import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'section_title.dart';

/// Title + subtitle on the left; search, notifications and avatar on the right.
class PageHeader extends StatelessWidget {
  const PageHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      this.search = false,
      this.actions = true});
  final String title;
  final String subtitle;
  final bool search;
  final bool actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title, size: 28),
        const SizedBox(height: 10),
        Text(subtitle,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted)),
      ],
    );
    final Widget actionButtons = actions
        ? const Row(
            mainAxisSize: MainAxisSize.min,
            children: [_NotificationButton(), SizedBox(width: 10), _Avatar()],
          )
        : const SizedBox.shrink();

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 760) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            if (search) ...[
              const SizedBox(width: 300, child: _SearchField()),
              const SizedBox(width: 16),
            ],
            actionButtons,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 12),
            actionButtons
          ]),
          if (search) ...[const SizedBox(height: 14), const _SearchField()],
        ],
      );
    });
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: context.read<SchedulerProvider>().setQuery,
        decoration: InputDecoration(
          hintText: 'Search facilities, sports…',
          hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.muted),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border)),
        ),
      );
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    final recent = p.myBookings.take(4).toList();
    final pending = recent.where((b) => b.status.name == 'pending').length;

    return PopupMenuButton<int>(
      tooltip: 'Notifications',
      offset: const Offset(0, 50),
      onSelected: (_) => p.setTab(1),
      itemBuilder: (_) => recent.isEmpty
          ? [
              const PopupMenuItem<int>(
                  enabled: false, child: Text('No notifications yet'))
            ]
          : [
              for (final b in recent)
                PopupMenuItem<int>(
                  value: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.facilityName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${p.displayStatus(b)} · ${shortDate(b.date)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
            ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Badge(
          isLabelVisible: pending > 0,
          label: Text('$pending'),
          child: const Icon(Icons.notifications_none_rounded,
              color: AppColors.text, size: 22),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();
    final parts =
        p.profileName.split(' ').where((s) => s.isNotEmpty).take(2).toList();
    final initials =
        parts.isEmpty ? 'S' : parts.map((s) => s[0].toUpperCase()).join();
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => p.setTab(4),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.softBlue,
        child: Text(initials,
            style: const TextStyle(
                color: AppColors.blue, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
