import 'package:flutter/material.dart';

class CommuteLoadingShimmer extends StatelessWidget {
  const CommuteLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _bar(width: 180, height: 16),
            const SizedBox(height: 12),
            _bar(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            _bar(width: 240, height: 14),
            const SizedBox(height: 20),
            _bar(width: 120, height: 12),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
