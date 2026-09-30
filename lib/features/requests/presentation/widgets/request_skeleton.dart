import 'package:flutter/material.dart';

class RequestSkeleton extends StatelessWidget {
  const RequestSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget box(double h, {double? w}) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return Column(
      children: List.generate(
        4,
        (_) => Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [box(22, w: 75), const Spacer(), box(15, w: 35)]),
                const SizedBox(height: 12),
                box(18, w: 150),
                const SizedBox(height: 8),
                box(13, w: 220),
                const SizedBox(height: 8),
                box(13, w: 180),
                const SizedBox(height: 12),
                box(42),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
