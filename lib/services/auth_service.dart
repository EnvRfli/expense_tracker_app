import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricInProgress = false;
  bool get isBiometricInProgress => _isBiometricInProgress;
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<bool> authenticateWithBiometric(
      {String reason = 'Silakan verifikasi identitas Anda'}) async {
    _isBiometricInProgress = true;
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('Biometric authentication not available');
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      if (e.code == 'no_fragment_activity') {
        print(
            'FragmentActivity required - this should be fixed by updating MainActivity');
        return false;
      } else if (e.code == 'NotAvailable') {
        print('Biometric authentication not available');
        return false;
      } else if (e.code == 'NotEnrolled') {
        print('No biometric credentials enrolled');
        return false;
      }

      return false;
    } catch (e) {
      print('General authentication error: $e');
      return false;
    } finally {
      _isBiometricInProgress = false;
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyPin(String enteredPin, String storedHashedPin) {
    final hashedEnteredPin = _hashPin(enteredPin);
    return hashedEnteredPin == storedHashedPin;
  }

  String getHashedPin(String pin) {
    return _hashPin(pin);
  }

  Future<bool> isAppLocked() async {
    if (_isBiometricInProgress) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastBackground = prefs.getInt('last_background_time') ?? 0;
    final lockTimeout =
        prefs.getInt('lock_timeout') ?? 0; // 0 means immediate lock
    final hasBeenAuthenticated =
        prefs.getBool('has_been_authenticated') ?? false;
    final lastAuthTime = prefs.getInt('last_auth_time') ?? 0;
    if (!hasBeenAuthenticated) {
      return true; // Always require authentication for first time
    }

    if (lastBackground == 0) {
      return false;
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = currentTime - lastBackground;
    final timeSinceAuth =
        lastAuthTime > 0 ? currentTime - lastAuthTime : 999999999;
    if (timeSinceAuth < 30000) {
      return false;
    }
    final shouldLock = timeDifference > (lockTimeout * 1000);

    return shouldLock;
  }

  Future<void> markAsAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_been_authenticated', true);
    final authTime = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('last_auth_time', authTime);
  }

  Future<bool> isRecentlyAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAuthTime = prefs.getInt('last_auth_time') ?? 0;

      if (lastAuthTime == 0) return false;

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeDifference = currentTime - lastAuthTime;
      return timeDifference < 5000;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearAuthenticationSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_been_authenticated');
  }

  Future<void> resetAuthenticationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_been_authenticated', false);
    await prefs.remove('last_background_time');
  }

  Future<void> setAppBackgrounded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'last_background_time', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_background_time');
    await markAsAuthenticated(); // Mark as authenticated when unlocking
  }

  Future<void> setLockTimeout(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lock_timeout', seconds);
  }

  Future<int> getLockTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lock_timeout') ?? 0; // Default: immediate lock
  }

  Future<bool> shouldUseBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricPreferred = prefs.getBool('biometric_preferred') ?? true;
    final isAvailable = await isBiometricAvailable();
    return biometricPreferred && isAvailable;
  }

  Future<void> setBiometricPreference(bool prefer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_preferred', prefer);
  }
}
