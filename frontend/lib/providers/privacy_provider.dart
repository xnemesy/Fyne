import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PrivacyState {
  final bool isBlurred;
  final bool isSettingsEnabled;
  final bool isAppInBackground;

  PrivacyState({
    this.isBlurred = false,
    this.isSettingsEnabled = true,
    this.isAppInBackground = false,
  });

  PrivacyState copyWith({
    bool? isBlurred,
    bool? isSettingsEnabled,
    bool? isAppInBackground,
  }) {
    return PrivacyState(
      isBlurred: isBlurred ?? this.isBlurred,
      isSettingsEnabled: isSettingsEnabled ?? this.isSettingsEnabled,
      isAppInBackground: isAppInBackground ?? this.isAppInBackground,
    );
  }
}

class PrivacyNotifier extends Notifier<PrivacyState> with WidgetsBindingObserver {
  late StreamSubscription<int> _proximitySubscription;
  late StreamSubscription<AccelerometerEvent> _accelSubscription;

  @override
  PrivacyState build() {
    WidgetsBinding.instance.addObserver(this);
    _initSensors();
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _proximitySubscription.cancel();
      _accelSubscription.cancel();
    });
    return PrivacyState();
  }

  void _initSensors() {
    // Proximity sensor listener
    _proximitySubscription = ProximitySensor.events.listen((int event) {
      if (state.isSettingsEnabled) {
        state = state.copyWith(isBlurred: event > 0);
      }
    });

    // Accelerometer listener for "Face Down" detection
    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (state.isSettingsEnabled) {
        // Z-axis near -10 means face down
        bool faceDown = event.z < -8.5;
        if (faceDown != state.isBlurred) {
          state = state.copyWith(isBlurred: faceDown);
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    bool inBackground = lifecycleState == AppLifecycleState.inactive || 
                       lifecycleState == AppLifecycleState.paused;
    
    state = state.copyWith(
      isAppInBackground: inBackground,
      isBlurred: inBackground || state.isBlurred,
    );
  }

  void togglePrivacyFilter(bool enabled) {
    state = state.copyWith(isSettingsEnabled: enabled);
  }
}

final privacyProvider = NotifierProvider<PrivacyNotifier, PrivacyState>(() => PrivacyNotifier());
