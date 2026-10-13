import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/contact_section.dart';
import '../widgets/page_header.dart';
import '../widgets/surface.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminders = true;
  bool _email = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchedulerProvider>();

    Widget tile(String title, String sub, bool value,
            ValueChanged<bool> onChanged) =>
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(sub,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          value: value,
          onChanged: onChanged,
        );

    return LayoutBuilder(builder: (context, c) {
      final pad = pagePadding(c.maxWidth);
      return ListView(
        padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
        children: [
          const PageHeader(
              title: 'Settings',
              subtitle: 'Manage notifications and smart features.'),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SurfaceCard(
                child: Column(
                  children: [
                    tile(
                        'Booking reminders',
                        'Get reminded before your slot starts',
                        _reminders,
                        (v) => setState(() => _reminders = v)),
                    const Divider(),
                    tile(
                        'Email notifications',
                        'Receive status updates by email',
                        _email,
                        (v) => setState(() => _email = v)),
                    const Divider(),
                    tile(
                        'Smart suggestions',
                        'Show recommended facilities and best times',
                        p.smartEnabled,
                        p.setSmartEnabled),
                    const Divider(),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('About',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Smart Sports Scheduler v1.0 · built on the Sports design system',
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.muted)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const ContactSection(),
        ],
      );
    });
  }
}
