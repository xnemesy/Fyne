import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/fyne_theme.dart';

class FyneShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const FyneShimmer({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
      highlightColor: isDark ? Colors.white24 : Colors.black.withOpacity(0.02),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class FyneTransactionShimmer extends StatelessWidget {
  const FyneTransactionShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const FyneShimmer(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(12))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FyneShimmer(width: MediaQuery.of(context).size.width * 0.4, height: 16),
                const SizedBox(height: 8),
                FyneShimmer(width: MediaQuery.of(context).size.width * 0.2, height: 12),
              ],
            ),
          ),
          const FyneShimmer(width: 60, height: 20),
        ],
      ),
    );
  }
}
