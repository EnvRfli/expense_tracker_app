import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isInitialized => _isInitialized;

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _notifyListenersSafely();
    }
  }

  void setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      _notifyListenersSafely();
    }
  }

  void clearError() {
    setError(null);
  }

  void markInitialized() {
    if (!_isInitialized) {
      _isInitialized = true;
      _notifyListenersSafely();
    }
  }

  @override
  void notifyListeners() {
    _notifyListenersSafely();
  }

  void _notifyListenersSafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) {
          super.notifyListeners();
        }
      });
    } else {
      if (hasListeners) {
        super.notifyListeners();
      }
    }
  }

  Future<T?> handleAsync<T>(Future<T> Function() operation,
      {bool silent = false}) async {
    try {
      if (!silent) setLoading(true);
      clearError();
      final result = await operation();
      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      if (!silent) setLoading(false);
    }
  }

  Future<T?> handleAsyncSilent<T>(Future<T> Function() operation) async {
    return handleAsync(operation, silent: true);
  }

  Future<void> initialize() async {}
}
