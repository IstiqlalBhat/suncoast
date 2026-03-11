import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';

class CameraService {
  final ImagePicker _imagePicker = ImagePicker();
  final _logger = Logger();

  Future<File?> takePhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (photo == null) return null;
      return File(photo.path);
    } catch (e) {
      _logger.e('Failed to take photo: $e');
      return null;
    }
  }

  Future<File?> pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      _logger.e('Failed to pick image: $e');
      return null;
    }
  }

  Future<File?> pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;
      final path = result.files.first.path;
      if (path == null) return null;
      return File(path);
    } catch (e) {
      _logger.e('Failed to pick PDF: $e');
      return null;
    }
  }

  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;
      final path = result.files.first.path;
      if (path == null) return null;
      return File(path);
    } catch (e) {
      _logger.e('Failed to pick file: $e');
      return null;
    }
  }
}
