import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/contact_info.dart';
import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';
import 'sidebar_nav.dart';

/// Dark footer: brand + address, quick links, and "Need help" contact details
/// (no map). Tap a number or the email to copy it.
class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  static const _links = [
    'Facilities',
    'My Bookings',
    'Calendar',
    'Favorites',
    'Profile',
    'Settings'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.slateDeep, Color(0xFF111A33), Color(0xFF1B1038)],
        ),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 760;
        final pad = wide ? 40.0 : 24.0;

        final brand = const _Brand();
        final links = _Links(labels: _links);
        const reach = _Reach();

        return Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: brand),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: links),
                    const SizedBox(width: 24),
                    const Expanded(flex: 4, child: reach),
                  ],
                )
              else ...[
                brand,
                const SizedBox(height: 28),
                links,
                const SizedBox(height: 28),
                reach,
              ],
              const SizedBox(height: 28),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 12,
                spacing: 12,
                children: [
                  Text('© 2026 SPORTSCHEDULER. ALL RIGHTS RESERVED.',
                      style: AppText.label(10.5,
                          color: Colors.white54,
                          weight: FontWeight.w600,
                          spacing: 1)),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 18)),
                    onPressed: () => Scrollable.maybeOf(context)
                        ?.position
                        .animateTo(0,
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutCubic),
                    icon: const Icon(Icons.arrow_upward, size: 16),
                    label: const Text('RETURN TO TOP'),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

Widget _header(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(text,
          style: AppText.label(11, color: AppColors.blueLight, spacing: 2)),
    );

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLogo(light: true),
          SizedBox(height: 16),
          Text(ContactInfo.address,
              style: TextStyle(
                  fontSize: 13.5, height: 1.7, color: Colors.white70)),
        ],
      );
}

class _Links extends StatelessWidget {
  const _Links({required this.labels});
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final p = context.read<SchedulerProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('NAVIGATE'),
        for (var i = 0; i < labels.length; i++)
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              Scrollable.maybeOf(context)?.position.jumpTo(0);
              p.setTab(i);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(labels[i].toUpperCase(),
                  style: AppText.label(11.5,
                      color: Colors.white,
                      weight: FontWeight.w700,
                      spacing: 1)),
            ),
          ),
      ],
    );
  }
}

class _Reach extends StatelessWidget {
  const _Reach();

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(child: child),
            ],
          ),
        );
    const numberStyle = TextStyle(
        fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white);
    final phones = ContactInfo.phones;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('NEED HELP'),
        row(
          Icons.phone_outlined,
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            children: [
              for (var i = 0; i < phones.length; i++) ...[
                if (i > 0) const Text('/', style: numberStyle),
                InkWell(
                  onTap: () async {
                    final digits = phones[i].replaceAll(
                      RegExp(r'\D'),
                      '',
                    );

                    final whatsappNumber =
                        digits.startsWith('91') ? digits : '91$digits';

                    final uri = Uri.parse(
                      'https://wa.me/$whatsappNumber',
                    );

                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: Text(
                    phones[i],
                    style: numberStyle,
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            const Icon(
              Icons.mail_outline,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: ContactInfo.email,
                  query: 'subject=Smart Sports Scheduler Enquiry',
                );

                await launchUrl(emailUri);
              },
              child: Text(
                ContactInfo.email,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.camera_alt,
              color: Colors.pinkAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () async {
                final Uri instagramUri = Uri.parse(
                  'https://instagram.com/always_krishnnna?dlrf=MTczN3NueWYyOXZpYg%3D%3D',
                );

                await launchUrl(
                  instagramUri,
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text(
                'Follow us on Instagram',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        row(
          Icons.schedule,
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Text(ContactInfo.hours,
                style: TextStyle(
                    fontSize: 13, height: 1.5, color: Colors.white70)),
          ),
        ),
      ],
    );
  }
}

class _Copyable extends StatelessWidget {
  const _Copyable(
      {required this.text, required this.label, required this.style});
  final String text;
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Tap to copy',
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$label copied')));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(text, style: style),
          ),
        ),
      );
}
