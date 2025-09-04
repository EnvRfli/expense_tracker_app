import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_settings_provider.dart';
import '../services/auth_service.dart';
import '../services/app_lock_state.dart';
import '../screens/pin_entry_screen.dart';
import '../l10n/localization_extension.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> {
  bool _isLocked = false;
  bool _hasInitialized = false;
  int _retryCount = 0;
  static const int _maxRetries = 50;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLockState.setLockVisible(_isLocked);

    if (_isLocked) {
      return PinEntryScreen(
        title: context.tr('app_locked'),
        subtitle: context.tr('enter_pin_or_biometric'),
        onSuccess: () {
          setState(() {
            _isLocked = false;
          });

          _hasInitialized = true;
        },
      );
    }

    return widget.child;
  }

  void _checkLockStatus() async {
    if (_hasInitialized) {
      if (!mounted) return;

      final userSettings = context.read<UserSettingsProvider>();

      if (userSettings.user == null ||
          (!userSettings.pinEnabled && !userSettings.biometricEnabled)) {
        setState(() {
          _isLocked = false;
        });
        return;
      }

      final isLocked = await AuthService.instance.isAppLocked();

      if (mounted) {
        setState(() {
          _isLocked = isLocked;
        });
      }
      return;
    }

    final userSettings = context.read<UserSettingsProvider>();

    if (userSettings.user == null) {
      _retryCount++;

      if (_retryCount >= _maxRetries) {
        setState(() {
          _isLocked = false;
        });
        return;
      }

      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _checkLockStatus();
      }
      return;
    }

    _retryCount = 0;

    if (!userSettings.pinEnabled && !userSettings.biometricEnabled) {
      setState(() {
        _isLocked = false;
      });
      _hasInitialized = true;
      return;
    }

    final isRecentlyAuth = await AuthService.instance.isRecentlyAuthenticated();
    final shouldResetAuth = await _shouldResetAuthenticationStatus();

    if (shouldResetAuth && !isRecentlyAuth) {
      await AuthService.instance.resetAuthenticationStatus();
    }

    _hasInitialized = true;

    await Future.delayed(const Duration(milliseconds: 1500));

    final isLocked = await AuthService.instance.isAppLocked();

    if (mounted) {
      setState(() {
        _isLocked = isLocked;
      });
    }
  }

  Future<bool> _shouldResetAuthenticationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userSettings = context.read<UserSettingsProvider>();

      final lastBackground = prefs.getInt('last_background_time') ?? 0;

      if (lastBackground == 0) {
        return true;
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTime - lastBackground;

      final backgroundLockThreshold =
          userSettings.backgroundLockTimeout * 1000; // Convert to milliseconds

      if (timeDifference > backgroundLockThreshold) {
        return true;
      }

      final shouldReset = timeDifference > 10000; // 10 seconds

      return shouldReset;
    } catch (e) {
      return true;
    }
  }
}
