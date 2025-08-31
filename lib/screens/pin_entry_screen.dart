import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_settings_provider.dart';
import '../services/auth_service.dart';
import '../services/app_lock_state.dart';
import '../utils/theme.dart';
import '../l10n/localization_extension.dart';

class PinEntryScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool showBiometricOption;
  final VoidCallback? onSuccess;

  const PinEntryScreen({
    super.key,
    this.title = '',
    this.subtitle = '',
    this.showBiometricOption = true,
    this.onSuccess,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _enteredPin = '';
  bool _isLoading = false;
  int _attempts = 0;
  static const int maxAttempts = 5;

  @override
  void initState() {
    super.initState();

    // Mark that PIN entry screen is showing (part of lock state)
    AppLockState.setLockVisible(true);

    // Try biometric authentication first if available, with delay to ensure provider is ready
    if (widget.showBiometricOption) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Add longer delay to ensure provider initialization is complete
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted && _shouldShowBiometricOption()) {
            _tryBiometricAuth();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    // Clear lock state when PIN entry screen is disposed
    AppLockState.setLockVisible(false);
    super.dispose();
  }

  bool _shouldShowBiometricOption() {
    if (!widget.showBiometricOption) return false;

    try {
      final userSettings = context.read<UserSettingsProvider>();
      // Only show biometric if both PIN and biometric are enabled
      return userSettings.pinEnabled && userSettings.biometricEnabled;
    } catch (e) {
      // If context is not available or error occurs, default to showBiometricOption parameter
      return widget.showBiometricOption;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                widget.title.isNotEmpty
                    ? widget.title
                    : context.tr('enter_pin'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                widget.subtitle.isNotEmpty
                    ? widget.subtitle
                    : context.tr('enter_pin_to_continue'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // PIN Display
              _buildPinDisplay(),
              const SizedBox(height: 24),

              // Number Pad
              _buildNumberPad(),

              const SizedBox(height: 16),

              // Attempts warning
              if (_attempts > 0) ...[
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    context
                        .tr('incorrect_pin_remaining_attempts')
                        .replaceAll('{attempts}', '${maxAttempts - _attempts}'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red[100],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _enteredPin.length
                ? Colors.white
                : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        // First row: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('1'),
            _buildNumberButton('2'),
            _buildNumberButton('3'),
          ],
        ),
        const SizedBox(height: 16),

        // Second row: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('4'),
            _buildNumberButton('5'),
            _buildNumberButton('6'),
          ],
        ),
        const SizedBox(height: 16),

        // Third row: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('7'),
            _buildNumberButton('8'),
            _buildNumberButton('9'),
          ],
        ),
        const SizedBox(height: 16),

        // Fourth row: biometric, 0, delete
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Biometric Button
            if (_shouldShowBiometricOption())
              GestureDetector(
                onTap: _isLoading ? null : _tryBiometricAuth,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              )
            else
              const SizedBox(width: 72), // Empty space if no biometric
            _buildNumberButton('0'),
            _buildDeleteButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _onNumberPressed(number),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onDeletePressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withOpacity(0.2),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += number;
      });

      if (_enteredPin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userSettings = context.read<UserSettingsProvider>();
      final storedPin = userSettings.pinCode;

      if (storedPin != null &&
          AuthService.instance.verifyPin(_enteredPin, storedPin)) {
        // PIN correct - mark as authenticated
        await AuthService.instance.markAsAuthenticated();
        // Clear lock state before calling success callback
        AppLockState.setLockVisible(false);
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.of(context).pop(true);
        }
      } else {
        // PIN incorrect
        setState(() {
          _attempts++;
          _enteredPin = '';
        });

        if (_attempts >= maxAttempts) {
          _showMaxAttemptsDialog();
        } else {
          _showError(context.tr('incorrect_pin_try_again'));
        }
      }
    } catch (e) {
      _showError(
          context.tr('error_occurred').replaceAll('{error}', e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _tryBiometricAuth() async {
    try {
      final userSettings = context.read<UserSettingsProvider>();

      // Check if user settings are loaded with more retries
      int retryCount = 0;
      while (userSettings.user == null && retryCount < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retryCount++;
        if (!mounted) return;
      }

      // If still not loaded after retries, skip biometric
      if (userSettings.user == null) {
        print(
            'User settings not loaded after retries, skipping biometric auth');
        return;
      }

      if (!userSettings.biometricEnabled) return;

      final isAvailable = await AuthService.instance.isBiometricAvailable();
      if (!isAvailable) return;

      final authenticated =
          await AuthService.instance.authenticateWithBiometric(
        reason: context.tr('verify_identity_to_open_app'),
      );

      if (authenticated) {
        // Mark as authenticated and call success callback
        await AuthService.instance.markAsAuthenticated();
        // Clear lock state before calling success callback
        AppLockState.setLockVisible(false);
        if (mounted) {
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            Navigator.of(context).pop(true);
          }
        }
      }
    } catch (e) {
      // Biometric failed, user can still enter PIN
      print('Biometric authentication failed: $e');
    }
  }

  void _showMaxAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.tr('too_many_attempts')),
        content: Text(
          context.tr('max_attempts_message'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _attempts = 0;
              });
            },
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
