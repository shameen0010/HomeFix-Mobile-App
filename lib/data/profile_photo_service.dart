import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoService {
  ProfilePhotoService({
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  final FirebaseStorage _storage;
  final ImagePicker _picker;

  Future<String?> pickAndUpload({
    required String userId,
    required String collection,
  }) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    final extension = _extension(image.name);
    final ref = _storage.ref('$collection/$userId/profile.$extension');
    final metadata = SettableMetadata(
      contentType: _contentType(extension),
      cacheControl: 'public,max-age=3600',
    );
    if (kIsWeb) {
      await ref.putData(bytes, metadata);
    } else {
      await ref.putData(bytes, metadata);
    }
    return ref.getDownloadURL();
  }

  String _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? 'jpg' : name.substring(dot + 1).toLowerCase();
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
