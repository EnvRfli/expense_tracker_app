import 'package:flutter/foundation.dart';

class AppLockState {
  static final ValueNotifier<bool> isLockVisible = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isSplashVisible = ValueNotifier<bool>(false);

  static bool get shouldDetectIdle {
    return !isLockVisible.value && !isSplashVisible.value;
  }

  static void setLockVisible(bool visible) {
    isLockVisible.value = visible;
  }

  static void setSplashVisible(bool visible) {
    isSplashVisible.value = visible;
  }
}
