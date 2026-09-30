import 'package:flutter/material.dart';

class RequestStatusBadge extends StatelessWidget {
  final String status;

  const RequestStatusBadge({super.key, required this.status});

  String get label {
    switch (status) {
      case 'review':
        return 'در حال بررسی';
      case 'processed':
        return 'بررسی شده';
      case 'rejected':
        return 'رد شده';
      default:
        return 'جدید';
    }
  }

  Color get color {
    switch (status) {
      case 'review':
        return Colors.amber.shade800;
      case 'processed':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
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
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
