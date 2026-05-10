import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/asset_model.dart';

class AssetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AssetModel>> getAssets(String societyId) {
    return _db
        .collection('assets')
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snap) {
      final assets = snap.docs.map((doc) => AssetModel.fromFirestore(doc)).toList();
      // Sort in memory to avoid needing a composite index in Firestore
      assets.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      return assets;
    });
  }

  Future<void> addAsset(AssetModel asset) async {
    await _db.collection('assets').add(asset.toMap());
  }

  Future<void> updateAsset(AssetModel asset) async {
    await _db.collection('assets').doc(asset.id).update(asset.toMap());
  }

  Future<void> deleteAsset(String assetId) async {
    await _db.collection('assets').doc(assetId).delete();
  }

  Future<void> logMaintenance(String assetId, DateTime nextMaintenance) async {
    await _db.collection('assets').doc(assetId).update({
      'lastMaintenanceDate': FieldValue.serverTimestamp(),
      'nextMaintenanceDate': Timestamp.fromDate(nextMaintenance),
      'status': 'active', // Ensure it is active if it was under maintenance
    });
  }
}
