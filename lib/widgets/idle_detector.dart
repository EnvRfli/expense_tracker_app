import 'dart:async';

import 'package:flutter/material.dart';
import '../screens/pin_entry_screen.dart';
import '../services/app_lock_state.dart';
import '../l10n/localization_extension.dart';

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
    if (AppLockState.shouldDetectIdle && _isForeground && !_dialogShowing) {
      _startTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
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
      final dialogContext = widget.navigatorKey?.currentContext ?? context;
      int secondsLeft = widget.promptCountdown.inSeconds;
      Timer? countdownTimer;

      Future<void> lockNow() async {
        if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        }
        final nav = widget.navigatorKey?.currentState ?? Navigator.of(context);
        await nav.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => PinEntryScreen(
              title: 'App Locked',
              subtitle: 'Enter PIN to continue',
              onSuccess: () {
                if (nav.canPop()) nav.pop();
              },
            ),
          ),
        );
      }

      await showDialog<void>(
        context: dialogContext,
        barrierDismissible: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              countdownTimer ??= Timer.periodic(
                const Duration(seconds: 1),
                (t) {
                  if (!mounted) return;
                  if (secondsLeft <= 1) {
                    t.cancel();
                    lockNow();
                  } else {
                    setState(() => secondsLeft -= 1);
                  }
                },
              );

              return PopScope(
                canPop: true,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) {
                    countdownTimer?.cancel();
                    countdownTimer = null;
                  }
                },
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    context.tr('inactive_warning'),
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  content: Text(
                    context.tr('app_lock_countdown', params: {
                      'seconds': secondsLeft.toString(),
                    }),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        countdownTimer?.cancel();
                        countdownTimer = null;
                        Navigator.of(ctx, rootNavigator: true).pop();
                      },
                      child: Text(context.tr('keep_staying')),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      _dialogShowing = false;
      if (mounted) {
        _resetTimer();
      }
    }
  }

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
