import 'package:flutter/material.dart';

/// Icon + colour per sport, used as the photo placeholder.
class SportStyle {
  static IconData icon(String sport) => switch (sport) {
        'Basketball' => Icons.sports_basketball,
        'Tennis' => Icons.sports_tennis,
        'Football' => Icons.sports_soccer,
        'Badminton' => Icons.sports_tennis,
        'Volleyball' => Icons.sports_volleyball,
        'Cricket' => Icons.sports_cricket,
        _ => Icons.sports,
      };

  static Color color(String sport) => switch (sport) {
        'Basketball' => const Color(0xFFE67E22),
        'Tennis' => const Color(0xFF7CA82B),
        'Football' => const Color(0xFF1E8E5A),
        'Badminton' => const Color(0xFF3F7CD8),
        'Volleyball' => const Color(0xFFD9A400),
        'Cricket' => const Color(0xFF8E5BC8),
        _ => const Color(0xFF0B7A5E),
      };
}
