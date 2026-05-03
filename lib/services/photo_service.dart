import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Service class for handling camera operations and photo processing.
///
/// Manages photo capture and Base64 encoding for Firestore storage
/// within Spark Plan limitations.
class PhotoService {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;

  /// Initializes the camera with the first available camera device.
  ///
  /// Should be called before attempting to take photos.
  /// Throws an exception if no cameras are available.
  Future<void> initializeCamera() async {
    if (_isCameraInitialized) {
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'No cameras available',
          'The device does not have any available cameras',
        );
      }

      // Use the rear camera if available, otherwise use the front camera
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
      );

      await _cameraController.initialize();
      _isCameraInitialized = true;
    } catch (e) {
      print('Error initializing camera: $e');
      rethrow;
    }
  }

  /// Gets the camera controller for use in UI widgets.
  ///
  /// Ensure initializeCamera() is called first.
  CameraController get cameraController {
    if (!_isCameraInitialized) {
      throw StateError('Camera not initialized. Call initializeCamera() first.');
    }
    return _cameraController;
  }

  /// Checks if the camera is initialized.
  bool get isCameraInitialized => _isCameraInitialized;

  /// Captures a photo and converts it to Base64.
  ///
  /// Returns the Base64-encoded image string.
  /// Throws an exception if the camera is not initialized or capture fails.
  Future<String> capturePhotoAsBase64() async {
    if (!_isCameraInitialized) {
      throw StateError('Camera not initialized. Call initializeCamera() first.');
    }

    try {
      final XFile image = await _cameraController.takePicture();
      final bytes = await image.readAsBytes();

      // Convert to Base64
      return base64Encode(bytes);
    } catch (e) {
      print('Error capturing photo: $e');
      rethrow;
    }
  }

  /// Captures a photo and returns the File.
  ///
  /// Useful for preview or further processing.
  Future<XFile> capturePhoto() async {
    if (!_isCameraInitialized) {
      throw StateError('Camera not initialized. Call initializeCamera() first.');
    }

    try {
      return await _cameraController.takePicture();
    } catch (e) {
      print('Error capturing photo: $e');
      rethrow;
    }
  }

  /// Resizes an image to a specified width while maintaining aspect ratio.
  ///
  /// Useful for reducing image size before Base64 encoding to minimize
  /// Firestore document size.
  Future<Uint8List> resizeImage(
    Uint8List imageBytes, {
    required int maxWidth,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final resized = img.copyResize(
        image,
        width: maxWidth,
        interpolation: img.Interpolation.average,
      );

      return Uint8List.fromList(img.encodeJpg(resized));
    } catch (e) {
      print('Error resizing image: $e');
      rethrow;
    }
  }

  /// Converts a File to Base64 string.
  ///
  /// Useful for converting locally stored images.
  Future<String> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting file to Base64: $e');
      rethrow;
    }
  }

  /// Decodes a Base64 string to bytes.
  ///
  /// Useful for displaying captured images.
  Uint8List base64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding Base64: $e');
      rethrow;
    }
  }

  /// Disposes of the camera controller and releases resources.
  ///
  /// Should be called in dispose() of the widget using the camera.
  Future<void> disposeCamera() async {
    if (_isCameraInitialized) {
      await _cameraController.dispose();
      _isCameraInitialized = false;
    }
  }
}
