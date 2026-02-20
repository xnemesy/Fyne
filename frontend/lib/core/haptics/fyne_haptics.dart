import 'package:flutter/services.dart';

class FyneHaptics {
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> heavy() => HapticFeedback.heavyImpact();
  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> success() async {
    await light();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await medium();
  }

  static Future<void> save() async {
    await medium();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await light();
  }

  static Future<void> delete() async {
    await heavy();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await light();
  }

  static Future<void> error() => HapticFeedback.vibrate();

  static Future<void> onTransactionTap() => light();
  static Future<void> onPeriodChange() => selection();
  static Future<void> onSaveSuccess() => save();
  static Future<void> onDeleteConfirm() => delete();
  static Future<void> onPullRefresh() => medium();
  static Future<void> onError() => error();
}
