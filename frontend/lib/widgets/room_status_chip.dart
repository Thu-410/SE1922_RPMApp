import 'package:flutter/material.dart';

import '../models/room.dart';

class RoomStatusChip extends StatelessWidget {
  const RoomStatusChip({super.key, required this.status, this.compact = false});

  final RoomStatus status;
  final bool compact;

  static Color colorOf(RoomStatus status) => switch (status) {
    RoomStatus.available => const Color(0xFF079455),
    RoomStatus.occupied => const Color(0xFF445BE7),
    RoomStatus.maintenance => const Color(0xFFD97706),
    RoomStatus.inactive => const Color(0xFF667085),
  };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
