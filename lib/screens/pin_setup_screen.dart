import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_settings_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isEdit;

  const PinSetupScreen({super.key, this.isEdit = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _currentPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Ubah PIN' : 'Setup PIN'),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              _isConfirming
                  ? 'Konfirmasi PIN Anda'
                  : (widget.isEdit ? 'Masukkan PIN Baru' : 'Buat PIN Keamanan'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Subtitle
            Text(
              _isConfirming
                  ? 'Masukkan kembali PIN untuk konfirmasi'
                  : 'PIN 6 digit untuk keamanan aplikasi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // PIN Display
            _buildPinDisplay(),
            const SizedBox(height: 48),

            // Number Pad
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDisplay() {
    final currentPinLength =
        _isConfirming ? _confirmPin.length : _currentPin.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < currentPinLength
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withOpacity(0.3),
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

        // Fourth row: empty, 0, delete
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72), // Empty space
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
          color: AppTheme.primaryColor.withOpacity(0.1),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryColor,
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
          color: Colors.red.withOpacity(0.1),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Colors.red,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _onNumberPressed(String number) {
    if (_isConfirming) {
      if (_confirmPin.length < 6) {
        setState(() {
          _confirmPin += number;
        });

        if (_confirmPin.length == 6) {
          _checkPinMatch();
        }
      }
    } else {
      if (_currentPin.length < 6) {
        setState(() {
          _currentPin += number;
        });

        if (_currentPin.length == 6) {
          // Auto proceed to confirmation after 6 digits
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() {
              _isConfirming = true;
            });
          });
        }
      }
    }
  }

  void _onDeletePressed() {
    if (_isConfirming) {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        });
      } else {
        // Go back to pin entry
        setState(() {
          _isConfirming = false;
          _confirmPin = '';
        });
      }
    } else {
      if (_currentPin.isNotEmpty) {
        setState(() {
          _currentPin = _currentPin.substring(0, _currentPin.length - 1);
        });
      }
    }
  }

  void _checkPinMatch() {
    if (_currentPin == _confirmPin) {
      _savePin();
    } else {
      _showError('PIN tidak cocok. Silakan coba lagi.');
      setState(() {
        _confirmPin = '';
      });
    }
  }

  void _savePin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userSettings = context.read<UserSettingsProvider>();
      final hashedPin = AuthService.instance.getHashedPin(_currentPin);

      // Update user settings with PIN
      final success = await userSettings.updatePinSettings(
        pinCode: hashedPin,
        pinEnabled: true,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEdit
                  ? 'PIN berhasil diubah!'
                  : 'PIN berhasil dibuat!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        _showError('Gagal menyimpan PIN. Silakan coba lagi.');
      }
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
