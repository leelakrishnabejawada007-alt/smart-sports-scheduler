import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Time-slot pill: available / selected / booked / yours.
class SlotChip extends StatelessWidget {
  const SlotChip({
    super.key,
    required this.hour,
    required this.available,
    required this.selected,
    required this.onSelected,
    this.mine = false,
  });

  final int hour;
  final bool available;
  final bool selected;
  final bool mine;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    if (selected) {
      bg = AppColors.blue;
      fg = Colors.white;
      border = AppColors.blue;
    } else if (mine) {
      bg = AppColors.softBlue;
      fg = AppColors.blue;
      border = AppColors.softBlue;
    } else if (available) {
      bg = Colors.white;
      fg = AppColors.text;
      border = const Color(0xFFD3DAEA);
    } else {
      bg = const Color(0xFFF1F3F8);
      fg = const Color(0xFF9AA3B8);
      border = const Color(0xFFF1F3F8);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: available ? onSelected : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mine) ...[
                  Icon(Icons.check, size: 14, color: fg),
                  const SizedBox(width: 4),
                ],
                Text(
                  timeLabel(hour),
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration:
                        (!available && !mine) ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
