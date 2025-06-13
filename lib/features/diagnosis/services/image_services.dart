import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:arco/core/exceptions/app_exceptions.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      // Check permissions
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          throw PermissionException('Camera permission denied');
        }
      } else if (source == ImageSource.gallery) {
        final status = await Permission.photos.request();
        if (!status.isGranted && !status.isLimited) {
          throw PermissionException('Photo library permission denied');
        }
      }
      
      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      
      return image;
    } catch (e) {
      if (e is PermissionException) {
        rethrow;
      }
      throw FileException('Failed to pick image: ${e.toString()}');
    }
  }
  
  Future<File> compressImage(File file) async {
    try {
      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      // Check file size
      final fileSize = await file.length();
      
      // Determine compression quality based on file size
      int quality = 85;
      if (fileSize > 5 * 1024 * 1024) { // > 5MB
        quality = 70;
      } else if (fileSize > 3 * 1024 * 1024) { // > 3MB
        quality = 80;
      }
      
      // Compress image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1024,
        minHeight: 1024,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
      
      if (result == null) {
        throw FileException('Failed to compress image');
      }
      
      return File(result.path);
    } catch (e) {
      if (e is FileException) {
        rethrow;
      }
      throw FileException('Image compression failed: ${e.toString()}');
    }
  }
  
  Future<bool> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> clearTemporaryFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync();
      
      for (final file in files) {
        if (file is File && file.path.contains('compressed_')) {
          await file.delete();
        }
      }
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}