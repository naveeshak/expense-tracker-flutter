import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection('expenses');

  Stream<List<ExpenseModel>> getExpenses() {
    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ExpenseModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _expensesCollection.add(
      expense.toMap(),
    );
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _expensesCollection.doc(expense.id).update({
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category,
      'date': Timestamp.fromDate(expense.date),
      'note': expense.note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExpense(String id) async {
    await _expensesCollection.doc(id).delete();
  }
}