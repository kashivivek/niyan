import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

/// Service for financial transaction ledger operations.
/// Extracted from the monolithic DatabaseService for maintainability.
class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get currentOwnerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ──────────────────────────────────────────────
  // Transaction CRUD
  // ──────────────────────────────────────────────

  Future<void> addTransaction(TransactionModel transaction) {
    developer.log('Adding transaction: ${transaction.toFirestore()}');
    return _db.collection('transactions').add(transaction.toFirestore());
  }

  Stream<List<TransactionModel>> getTransactionsForUnit(String unitId) {
    return _db
        .collection('transactions')
        .where('unitId', isEqualTo: unitId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<TransactionModel>> allTransactions(String ownerId) {
    return _db
        .collection('transactions')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> recordTransaction({
    required String propertyId,
    required String unitId,
    required String tenantId,
    required double amount,
    required String description,
    required String type,
    required String month,
  }) async {
    final ref = _db.collection('transactions').doc();
    final transaction = TransactionModel(
      id: ref.id,
      unitId: unitId,
      propertyId: propertyId,
      ownerId: currentOwnerId,
      tenantId: tenantId,
      description: description,
      amount: amount,
      date: DateTime.now(),
      type: type == 'income' ? TransactionType.income : TransactionType.expense,
      month: month,
    );
    await ref.set(transaction.toFirestore());
  }
}
