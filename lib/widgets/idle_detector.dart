import 'dart:async';

import 'package:flutter/material.dart';

/// A top-level wrapper that detects user inactivity (front-end only)
/// and shows a blocking dialog after [idleDuration] without input.
class IdleDetector extends StatefulWidget {
  const IdleDetector({
    super.key,
    required this.child,
    this.idleDuration = const Duration(seconds: 10),
    this.navigatorKey,
  });

  final Widget child;
  final Duration idleDuration;
  final GlobalKey<NavigatorState>? navigatorKey;

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
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimer();
    super.dispose();
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
    if (!_isForeground) return;
    _startTimer();
  }

  Future<void> _onIdle() async {
    if (!mounted || _dialogShowing || !_isForeground) return;
    _dialogShowing = true;
    try {
      // Prefer using the navigatorKey context if provided to ensure we
      // present above the app's Navigator.
      final dialogContext = widget.navigatorKey?.currentContext ?? context;
      await showDialog<void>(
        context: dialogContext,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('are you still there?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx, rootNavigator: true).pop();
                },
                child: const Text('OK'),
              ),
            ],
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
