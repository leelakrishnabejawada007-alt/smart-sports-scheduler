import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "OUR SERVICES"-style heading: heavy italic caps, last word in blue,
/// short blue underline bar.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.size = 28, this.underline = true});
  final String text;
  final double size;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    final words = text.toUpperCase().split(' ');
    final hasLast = words.length > 1;
    final lead = hasLast ? words.sublist(0, words.length - 1).join(' ') : words.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(
          style: AppText.display(size),
          children: [
            TextSpan(text: lead),
            if (hasLast)
              TextSpan(text: ' ${words.last}', style: const TextStyle(color: AppColors.blue)),
          ],
        )),
        if (underline) ...[
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.blue, borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ],
    );
  }
}
