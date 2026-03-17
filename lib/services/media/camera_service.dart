import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

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
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      return _resolvePickedFile(result.files.first);
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
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      return _resolvePickedFile(result.files.first);
    } catch (e) {
      _logger.e('Failed to pick file: $e');
      return null;
    }
  }

  Future<File?> _resolvePickedFile(PlatformFile pickedFile) async {
    final path = pickedFile.path;
    if (path != null && path.isNotEmpty) {
      return File(path);
    }

    final bytes = pickedFile.bytes;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    return _writeTempFile(
      fileName: pickedFile.name,
      bytes: bytes,
      extension: pickedFile.extension,
    );
  }

  // Some providers expose only bytes, so cache a temporary file for upload.
  Future<File> _writeTempFile({
    required String fileName,
    required Uint8List bytes,
    String? extension,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final sanitizedName = fileName.trim().isEmpty
        ? 'picked-file'
        : fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final normalizedExtension = (extension ?? '').trim().toLowerCase();
    final hasExtension =
        normalizedExtension.isNotEmpty &&
        sanitizedName.toLowerCase().endsWith('.$normalizedExtension');
    final resolvedName = hasExtension
        ? sanitizedName
        : '$sanitizedName${normalizedExtension.isEmpty ? '' : '.$normalizedExtension'}';
    final file = File(
      '${tempDir.path}/${DateTime.now().microsecondsSinceEpoch}-$resolvedName',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
