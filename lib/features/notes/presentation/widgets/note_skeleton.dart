import 'package:flutter/material.dart';

class NoteSkeleton extends StatelessWidget {
  const NoteSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildSkeleton(width: 120, height: 18),
                  const Spacer(),
                  _buildSkeleton(width: 50, height: 14),
                ],
              ),
              const SizedBox(height: 8),
              _buildSkeleton(width: double.infinity, height: 14),
              const SizedBox(height: 4),
              _buildSkeleton(width: 200, height: 14),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildSkeleton(width: 60, height: 12),
                  const SizedBox(width: 10),
                  _buildSkeleton(width: 60, height: 12),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeleton({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}