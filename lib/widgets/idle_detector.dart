import 'dart:async';

import 'package:flutter/material.dart';
import '../screens/pin_entry_screen.dart';
import '../services/app_lock_state.dart';

/// A top-level wrapper that detects user inactivity (front-end only)
/// and shows a blocking dialog after [idleDuration] without input.
class IdleDetector extends StatefulWidget {
  const IdleDetector({
    super.key,
    required this.child,
    this.idleDuration = const Duration(minutes: 2),
    this.navigatorKey,
    this.promptCountdown = const Duration(seconds: 10),
  });

  final Widget child;
  final Duration idleDuration;
  final GlobalKey<NavigatorState>? navigatorKey;
  final Duration promptCountdown;

  @override
  State<IdleDetector> createState() => _IdleDetectorState();
}

class _IdleDetectorState extends State<IdleDetector>
    with WidgetsBindingObserver {
  Timer? _idleTimer;
  bool _dialogShowing = false;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen to app state changes to pause/resume idle detection
    AppLockState.isLockVisible.addListener(_onAppStateChanged);
    AppLockState.isSplashVisible.addListener(_onAppStateChanged);

    _startTimerIfAppropriate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLockState.isLockVisible.removeListener(_onAppStateChanged);
    AppLockState.isSplashVisible.removeListener(_onAppStateChanged);
    _cancelTimer();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      if (AppLockState.shouldDetectIdle && _isForeground) {
        _startTimerIfAppropriate();
      } else {
        _cancelTimer();
      }
    }
  }

  void _startTimerIfAppropriate() {
    // Only start timer if we should detect idle and app is in foreground
    if (AppLockState.shouldDetectIdle && _isForeground && !_dialogShowing) {
      _startTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Pause detection when app is not in foreground to avoid showing dialogs
    // while the app is backgrounded.
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      _resetTimer();
    } else {
      _cancelTimer();
    }
  }

  void _cancelTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _startTimer() {
    _cancelTimer();
    _idleTimer = Timer(widget.idleDuration, _onIdle);
  }

  void _resetTimer() {
    if (!_isForeground || !AppLockState.shouldDetectIdle) return;
    _startTimer();
  }

  Future<void> _onIdle() async {
    if (!mounted ||
        _dialogShowing ||
        !_isForeground ||
        !AppLockState.shouldDetectIdle) return;
    _dialogShowing = true;
    try {
      // Prefer using the navigatorKey context if provided to ensure we
      // present above the app's Navigator.
      final dialogContext = widget.navigatorKey?.currentContext ?? context;
      int secondsLeft = widget.promptCountdown.inSeconds;
      Timer? countdownTimer;

      Future<void> lockNow() async {
        // Close dialog first if still open
        if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        }
        // Navigate to PIN screen
        final nav = widget.navigatorKey?.currentState ?? Navigator.of(context);
        await nav.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => PinEntryScreen(
              title: 'App Locked',
              subtitle: 'Enter PIN to continue',
              onSuccess: () {
                // On success, simply pop the lock screen
                if (nav.canPop()) nav.pop();
              },
            ),
          ),
        );
      }

      await showDialog<void>(
        context: dialogContext,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              countdownTimer ??= Timer.periodic(
                const Duration(seconds: 1),
                (t) {
                  if (!mounted) return;
                  if (secondsLeft <= 1) {
                    t.cancel();
                    // Trigger lock
                    lockNow();
                  } else {
                    setState(() => secondsLeft -= 1);
                  }
                },
              );

              return Theme(
                data: Theme.of(ctx),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Are you still there?',
                          style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(ctx).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'The app will be locked for security in:',
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$secondsLeft',
                            style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'seconds',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        countdownTimer?.cancel();
                        countdownTimer = null;
                        Navigator.of(ctx, rootNavigator: true).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(ctx).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'I\'m still here',
                            style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(ctx).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                ),
              );
            },
          );
        },
      );
    } finally {
      _dialogShowing = false;
      // After dialog dismissal, restart the idle timer so the next inactivity
      // period is detected again.
      if (mounted) {
        _resetTimer();
      }
    }
  }

  // Wrap entire subtree to listen for pointer and keyboard interactions.
  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        _resetTimer();
        return KeyEventResult.ignored;
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetTimer(),
        onPointerSignal: (_) => _resetTimer(),
        child: widget.child,
      ),
    );
  }
}
