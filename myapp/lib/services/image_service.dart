import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadTenantPhoto(String tenantId, XFile? xFile) async {
    if (xFile == null) return null;
    try {
      final ref = _storage.ref().child('tenant_photos').child(tenantId);
      TaskSnapshot snapshot;
      if (kIsWeb) {
        final bytes = await xFile.readAsBytes();
        snapshot = await ref.putData(bytes);
      } else {
        // Use io.File only on mobile. The compiler should be fine with this 
        // if we are careful, but sometimes it still checks the type.
        // We cast to dynamic to bypass strict constructor checks on web.
        final file = io.File(xFile.path);
        snapshot = await ref.putFile(file);
      }
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<String?> uploadProfilePhoto(String userId, XFile? xFile) async {
    if (xFile == null) return null;
    try {
      final ref = _storage.ref().child('profile_photos').child(userId);
      TaskSnapshot snapshot;
      if (kIsWeb) {
        final bytes = await xFile.readAsBytes();
        snapshot = await ref.putData(bytes);
      } else {
        final file = io.File(xFile.path);
        snapshot = await ref.putFile(file);
      }
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}
