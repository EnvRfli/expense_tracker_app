import 'package:flutter/foundation.dart';

/// Global app state to track various states that should pause idle detection
class AppLockState {
  static final ValueNotifier<bool> isLockVisible = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isSplashVisible = ValueNotifier<bool>(false);

  /// Returns true if idle detection should be active
  static bool get shouldDetectIdle {
    return !isLockVisible.value && !isSplashVisible.value;
  }

  /// Set lock screen visibility
  static void setLockVisible(bool visible) {
    isLockVisible.value = visible;
  }

  /// Set splash screen visibility
  static void setSplashVisible(bool visible) {
    isSplashVisible.value = visible;
  }
}
