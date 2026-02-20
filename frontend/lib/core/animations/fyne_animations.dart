import 'package:flutter/material.dart';

class FyneAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static Widget fadeScale({
    required Widget child,
    required Object transitionKey,
  }) {
    return AnimatedSwitcher(
      duration: normal,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (widget, animation) {
        final scale = Tween<double>(begin: 0.95, end: 1.0).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: widget),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Object>(transitionKey),
        child: child,
      ),
    );
  }

  static Widget slideUp({
    required Widget child,
    required Object transitionKey,
  }) {
    return AnimatedSwitcher(
      duration: normal,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (widget, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: widget),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Object>(transitionKey),
        child: child,
      ),
    );
  }
}
