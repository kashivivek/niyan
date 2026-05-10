import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/sos_model.dart';

class SosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Trigger an SOS alert
  Future<void> triggerSos({
    required String societyId,
    required String residentId,
    required String residentName,
    required String unitNumber,
  }) async {
    await _db.collection('sosAlerts').add({
      'societyId': societyId,
      'residentId': residentId,
      'residentName': residentName,
      'unitNumber': unitNumber,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Listen for active SOS alerts in a society (For Guards / Admins)
  Stream<List<SosModel>> getActiveSosAlerts(String societyId) {
    return _db
        .collection('sosAlerts')
        .where('societyId', isEqualTo: societyId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SosModel.fromFirestore(doc)).toList());
  }

  /// Mark an SOS as resolved
  Future<void> resolveSos(String sosId, String resolverName) async {
    await _db.collection('sosAlerts').doc(sosId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': resolverName,
    });
  }
}
