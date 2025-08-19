import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from camera or gallery
  static Future<File?> pickImage({
    required ImageSource source,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    try {
      // Check and request permissions
      bool hasPermission = await _checkPermissions(source);
      if (!hasPermission) {
        if (kDebugMode) {
          print('Permission denied for image picker');
        }
        return null;
      }

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;

      // Save to app directory
      final File savedFile = await _saveImageToAppDirectory(File(image.path));
      return savedFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      return null;
    }
  }

  /// Check and request necessary permissions
  static Future<bool> _checkPermissions(ImageSource source) async {
    if (source == ImageSource.camera) {
      // For camera, we need camera permission
      PermissionStatus cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        cameraStatus = await Permission.camera.request();
      }
      return cameraStatus.isGranted;
    } else {
      // For gallery, we need storage/photos permission
      if (Platform.isAndroid) {
        // Check Android SDK version
        int androidVersion = await _getAndroidSdkVersion();

        if (androidVersion >= 33) {
          // Android 13+ (API 33+) - use photos permission
          PermissionStatus photosStatus = await Permission.photos.status;
          if (photosStatus.isDenied) {
            photosStatus = await Permission.photos.request();
          }
          return photosStatus.isGranted;
        } else {
          // Android < 13 - use storage permission
          PermissionStatus storageStatus = await Permission.storage.status;
          if (storageStatus.isDenied) {
            storageStatus = await Permission.storage.request();
          }
          return storageStatus.isGranted;
        }
      }
      return true; // iOS handles permissions automatically
    }
  }

  /// Get Android SDK version
  static Future<int> _getAndroidSdkVersion() async {
    if (Platform.isAndroid) {
      try {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt;
      } catch (e) {
        if (kDebugMode) {
          print('Error getting Android SDK version: $e');
        }
        return 29; // Fallback to older version
      }
    }
    return 0;
  }

  /// Save image to app's private directory
  static Future<File> _saveImageToAppDirectory(File imageFile) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String receiptsDir = path.join(appDir.path, 'receipts');

    // Create receipts directory if it doesn't exist
    final Directory receiptsDirectory = Directory(receiptsDir);
    if (!await receiptsDirectory.exists()) {
      await receiptsDirectory.create(recursive: true);
    }

    // Generate unique filename
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String extension = path.extension(imageFile.path);
    final String fileName = 'receipt_$timestamp$extension';
    final String newPath = path.join(receiptsDir, fileName);

    // Copy file to new location
    final File newFile = await imageFile.copy(newPath);

    // Delete original temporary file
    try {
      await imageFile.delete();
    } catch (e) {
      if (kDebugMode) {
        print('Could not delete temporary file: $e');
      }
    }

    return newFile;
  }

  /// Delete image file
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting image: $e');
      }
      return false;
    }
  }

  /// Get image size info
  static Future<Map<String, dynamic>?> getImageInfo(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        final int bytes = await file.length();
        return {
          'path': imagePath,
          'size': bytes,
          'sizeFormatted': _formatBytes(bytes),
          'exists': true,
        };
      }
      return {'exists': false};
    } catch (e) {
      if (kDebugMode) {
        print('Error getting image info: $e');
      }
      return null;
    }
  }

  /// Format bytes to human readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Show image source selection dialog
  static Future<ImageSource?> showImageSourceDialog(context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Pilih Sumber Foto',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // Camera option
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.blue,
                      ),
                    ),
                    title: const Text('Kamera'),
                    subtitle: const Text('Ambil foto menggunakan kamera'),
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),

                  // Gallery option
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.green,
                      ),
                    ),
                    title: const Text('Galeri'),
                    subtitle: const Text('Pilih foto dari galeri'),
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),

                  const SizedBox(height: 10),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show permission denied dialog
  static Future<void> showPermissionDeniedDialog(
      BuildContext context, ImageSource source) async {
    String title = source == ImageSource.camera
        ? 'Izin Kamera Diperlukan'
        : 'Izin Galeri Diperlukan';

    String message = source == ImageSource.camera
        ? 'Aplikasi memerlukan izin kamera untuk mengambil foto. Silakan berikan izin di pengaturan aplikasi.'
        : 'Aplikasi memerlukan izin akses galeri untuk memilih foto. Silakan berikan izin di pengaturan aplikasi.';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Pengaturan'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Pick image with context for showing dialogs
  static Future<File?> pickImageWithContext({
    required BuildContext context,
    required ImageSource source,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    try {
      // Check and request permissions
      bool hasPermission = await _checkPermissions(source);
      if (!hasPermission) {
        // Show permission denied dialog
        await showPermissionDeniedDialog(context, source);
        return null;
      }

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;

      // Save to app directory
      final File savedFile = await _saveImageToAppDirectory(File(image.path));
      return savedFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Terjadi kesalahan saat mengambil gambar: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return null;
    }
  }

  /// Show image source selection dialog and pick image
  static Future<File?> showImageSourceDialogAndPick(
      BuildContext context) async {
    final ImageSource? source = await showImageSourceDialog(context);
    if (source == null) return null;

    return await pickImageWithContext(context: context, source: source);
  }
}
