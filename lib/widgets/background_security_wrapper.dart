import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_settings_provider.dart';
import '../services/auth_service.dart';
import '../services/app_lock_state.dart';
import '../services/recurring_budget_service.dart';
import '../screens/pin_entry_screen.dart';

/// Wrapper widget that handles background security logic
/// Must be placed inside the Provider scope
class BackgroundSecurityWrapper extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  const BackgroundSecurityWrapper({
    super.key,
    required this.child,
    this.navigatorKey,
  });

  @override
  State<BackgroundSecurityWrapper> createState() =>
      _BackgroundSecurityWrapperState();
}

class _BackgroundSecurityWrapperState extends State<BackgroundSecurityWrapper>
    with WidgetsBindingObserver {
  bool _isInBackground = false; // Track if we're already in background

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle background security logic
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Only set background time once per background session
        if (!_isInBackground) {
          _isInBackground = true;
          _setAppBackgrounded();
        }
        break;
      case AppLifecycleState.resumed:
        _isInBackground = false; // Reset background flag
        _checkBackgroundTimeout();

        // Check for recurring budgets when app resumes
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            RecurringBudgetService.instance.checkNow();
          }
        });
        break;
      default:
        break;
    }
  }

  Future<void> _setAppBackgrounded() async {
    try {
      final userSettings = context.read<UserSettingsProvider>();

      // Only set background time if security is enabled
      if (userSettings.pinEnabled || userSettings.biometricEnabled) {
        await AuthService.instance.setAppBackgrounded();
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> _checkBackgroundTimeout() async {
    try {
      final userSettings = context.read<UserSettingsProvider>();

      // Only check if security is enabled
      if (!userSettings.pinEnabled && !userSettings.biometricEnabled) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastBackground = prefs.getInt('last_background_time') ?? 0;

      if (lastBackground == 0) {
        return;
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTime - lastBackground;
      final backgroundLockThreshold = userSettings.backgroundLockTimeout * 1000;

      if (timeDifference > backgroundLockThreshold) {
        // Check if app is already in lock state to avoid double lock screen
        if (AppLockState.isLockVisible.value) {
          await AuthService.instance.resetAuthenticationStatus();
          return;
        }

        await AuthService.instance.resetAuthenticationStatus();

        // Navigate to PIN screen immediately only if not already locked
        if (mounted) {
          _showLockScreen();
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  void _showLockScreen() {
    try {
      // Use navigatorKey if provided, otherwise try to find navigator in context
      final navigator = widget.navigatorKey?.currentState ??
          Navigator.of(context, rootNavigator: true);

      navigator.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PinEntryScreen(
            title: 'App Locked',
            subtitle:
                'App was locked due to inactivity. Enter PIN to continue.',
            onSuccess: () {
              // On success, simply pop the lock screen
              if (navigator.canPop()) {
                navigator.pop();
              }
            },
          ),
        ),
      );
    } catch (e) {
      // Silently handle errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
