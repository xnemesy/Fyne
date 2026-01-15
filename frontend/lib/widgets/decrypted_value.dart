import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DecryptedValue extends StatelessWidget {
  final String? value;
  final String currency;
  final TextStyle style;
  final bool isLarge;

  const DecryptedValue({
    super.key,
    required this.value,
    this.currency = '€',
    required this.style,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: value != null
          ? Text(
              "$value $currency",
              key: ValueKey(value),
              style: style,
            )
          : Container(
              key: const ValueKey('placeholder'),
              width: isLarge ? 120 : 60,
              height: isLarge ? 32 : 16,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
    );
  }
}
