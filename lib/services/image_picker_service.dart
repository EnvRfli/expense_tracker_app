import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
      // For gallery, we need storage permission (Android < 13)
      if (Platform.isAndroid) {
        PermissionStatus storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          storageStatus = await Permission.storage.request();
        }
        
        // For Android 13+, use photos permission
        PermissionStatus photosStatus = await Permission.photos.status;
        if (photosStatus.isDenied) {
          photosStatus = await Permission.photos.request();
        }
        
        return storageStatus.isGranted || photosStatus.isGranted;
      }
      return true; // iOS handles permissions automatically
    }
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
}
