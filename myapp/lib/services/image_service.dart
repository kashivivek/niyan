import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadTenantPhoto(String tenantId, File image) async {
    try {
      final ref = _storage.ref().child('tenant_photos').child(tenantId);
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint(e.toString()); // Handle errors appropriately
      return null;
    }
  }
}
