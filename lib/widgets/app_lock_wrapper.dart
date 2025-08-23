import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_settings_provider.dart';
import '../services/auth_service.dart';
import '../screens/pin_entry_screen.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _hasInitialized = false;
  int _retryCount = 0;
  static const int _maxRetries = 50; // Maximum 5 seconds with 100ms delay

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _setAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        _checkLockStatus();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return PinEntryScreen(
        title: 'Aplikasi Terkunci',
        subtitle: 'Masukkan PIN atau gunakan biometrik untuk membuka',
        onSuccess: () {
          setState(() {
            _isLocked = false;
          });

          // Mark as initialized immediately to prevent re-checking
          _hasInitialized = true;
        },
      );
    }

    return widget.child;
  }

  void _checkLockStatus() async {
    // Skip if already checking or if we just unlocked
    if (_hasInitialized) {
      // Quick check for mounted widget
      if (!mounted) return;

      final userSettings = context.read<UserSettingsProvider>();
      if (userSettings.user == null ||
          (!userSettings.pinEnabled && !userSettings.biometricEnabled)) {
        setState(() {
          _isLocked = false;
        });
        return;
      }

      // Only do a quick lock check without reset
      final isLocked = await AuthService.instance.isAppLocked();

      if (mounted) {
        setState(() {
          _isLocked = isLocked;
        });
      }
      return;
    }

    final userSettings = context.read<UserSettingsProvider>();

    // Wait for user settings to be loaded
    if (userSettings.user == null) {
      _retryCount++;

      if (_retryCount >= _maxRetries) {
        setState(() {
          _isLocked = false;
        });
        return;
      }

      // UserSettings not loaded yet, wait a bit and try again
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _checkLockStatus();
      }
      return;
    }

    // Reset retry count once user is loaded
    _retryCount = 0;

    // Only check lock if PIN or biometric is enabled
    if (!userSettings.pinEnabled && !userSettings.biometricEnabled) {
      setState(() {
        _isLocked = false;
      });
      _hasInitialized = true;
      return;
    }

    // Reset authentication status only on true app start, not hot restart
    // Check if we need to reset authentication status
    // Don't reset if user was recently authenticated (e.g., biometric just succeeded)
    final isRecentlyAuth = await AuthService.instance.isRecentlyAuthenticated();
    final shouldResetAuth = await _shouldResetAuthenticationStatus();

    if (shouldResetAuth && !isRecentlyAuth) {
      await AuthService.instance.resetAuthenticationStatus();
    }

    _hasInitialized = true;

    // Give more time for biometric authentication to complete
    // This prevents the race condition where app is marked as locked
    // before biometric authentication has a chance to run
    await Future.delayed(const Duration(milliseconds: 1500));

    // Check if app should be locked
    final isLocked = await AuthService.instance.isAppLocked();

    if (mounted) {
      setState(() {
        _isLocked = isLocked;
      });
    }
  }

  // Determine if authentication status should be reset
  // This helps distinguish between true app start vs hot restart
  Future<bool> _shouldResetAuthenticationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check when the app was last backgrounded
      final lastBackground = prefs.getInt('last_background_time') ?? 0;

      // If no background time is set, this is likely a fresh start
      if (lastBackground == 0) {
        return true;
      }

      // Check how much time has passed since last background
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTime - lastBackground;

      // If more than 10 seconds have passed, consider it a true app restart
      // Hot restart usually happens much faster than this
      final shouldReset = timeDifference > 10000; // 10 seconds

      return shouldReset;
    } catch (e) {
      // If there's an error, err on the side of security
      return true;
    }
  }

  void _setAppBackgrounded() async {
    final userSettings = context.read<UserSettingsProvider>();

    // Only set background time if security is enabled
    if (userSettings.pinEnabled || userSettings.biometricEnabled) {
      await AuthService.instance.setAppBackgrounded();
    }
  }
}
