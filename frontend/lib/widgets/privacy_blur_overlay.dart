import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/privacy_provider.dart';

class PrivacyBlurOverlay extends ConsumerWidget {
  final Widget child;
  const PrivacyBlurOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacy = ref.watch(privacyProvider);
    final isHidden = privacy.isSettingsEnabled && (privacy.isBlurred || privacy.isAppInBackground);

    return Stack(
      children: [
        child,
        if (isHidden)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // Blocks interactions while blurred
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: const Color(0xFFFBFBF9).withOpacity(0.4),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF4A6741),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "CONTENUTO PROTETTO",
                          style: TextStyle(
                            color: const Color(0xFF1A1A1A).withOpacity(0.6),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
