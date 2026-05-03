import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service class responsible for Firebase Storage operations.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a discovery photo file to Firebase Storage.
  ///
  /// Returns a map containing both the download URL and the storage path.
  Future<Map<String, String>?> uploadDiscoveryPhoto({
    required XFile file,
    required String userId,
    required String questId,
  }) async {
    try {
      final storagePath = 'captures/$userId/$questId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref(storagePath);
      final uploadTask = ref.putFile(File(file.path));
      await uploadTask.whenComplete(() {});
      final downloadUrl = await ref.getDownloadURL();
      return {
        'downloadUrl': downloadUrl,
        'storagePath': storagePath,
      };
    } catch (e) {
      print('Error uploading discovery photo: $e');
      return null;
    }
  }

  /// Retrieves a download URL for a Storage object path.
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error retrieving download URL: $e');
      return null;
    }
  }
}
