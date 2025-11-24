// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/ex_category.dart';
import '../constants/icons.dart';
import '../models/split_group.dart'; 

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user-specific collection references
  CollectionReference _categoriesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  CollectionReference _expensesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('expenses');
  }
  
  // Split Expense Collections
  CollectionReference _splitGroupsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('splitGroups');
  }

  CollectionReference _groupExpensesCollection(String userId, String groupId) {
    return _splitGroupsCollection(userId).doc(groupId).collection('groupExpenses');
  }

  // Existing methods for Category/Expense...
  Future<void> initializeCategories(String userId) async {
    final categoriesRef = _categoriesCollection(userId);
    final snapshot = await categoriesRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return;
    }
    final batch = _firestore.batch();
    for (final categoryName in icons.keys) {
      final docRef = categoriesRef.doc(categoryName);
      batch.set(docRef, {
        'title': categoryName,
        'entries': 0,
        'totalAmount': '0.0',
      });
    }
    await batch.commit();
  }

  Stream<List<ExpenseCategory>> fetchCategories(String userId) {
    return _categoriesCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ExpenseCategory.fromString(data);
      }).toList();
    });
  }

  Future<void> updateCategory(
    String userId,
    String category,
    int nEntries,
    double nTotalAmount,
  ) async {
    await _categoriesCollection(userId).doc(category).update({
      'entries': nEntries,
      'totalAmount': nTotalAmount.toString(),
    });
  }

  Future<String> addExpense(String userId, Expense expense) async {
    final docRef = await _expensesCollection(userId).add(expense.toMap());
    return docRef.id;
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _expensesCollection(userId).doc(expenseId).delete();
  }

  Stream<List<Expense>> fetchExpenses(String userId, String category) {
    return _expensesCollection(userId)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Expense.fromString(data);
      }).toList();
    });
  }

  Stream<List<Expense>> fetchAllExpenses(String userId) {
    return _expensesCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Expense.fromString(data);
      }).toList();
    });
  }

  Future<ExpenseCategory?> getCategory(String userId, String title) async {
    final doc = await _categoriesCollection(userId).doc(title).get();
    if (doc.exists) {
      return ExpenseCategory.fromString(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // SPLIT EXPENSE METHODS

  Future<String> addSplitGroup(String userId, SplitGroup group) async {
    final docRef = await _splitGroupsCollection(userId).add(group.toMap());
    return docRef.id;
  }

  Stream<List<SplitGroup>> fetchSplitGroups(String userId) {
    return _splitGroupsCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SplitGroup.fromMap(data, doc.id);
      }).toList();
    });
  }

  // UPDATED: Update Split Group for all editable properties (including title)
  Future<void> updateSplitGroup(String userId, SplitGroup group) async {
    await _splitGroupsCollection(userId).doc(group.id).update({
      'title': group.title, // Keep title updatable
      'members': group.members,
      'totalExpenses': group.totalExpenses.toString(),
      'isHold': group.isHold, // Still needed for compatibility
    });
  }
  
  // NEW: Dedicated method to update only the Split Group Title
  Future<void> updateSplitGroupTitle(String userId, String groupId, String newTitle) async {
    await _splitGroupsCollection(userId).doc(groupId).update({
      'title': newTitle,
    });
  }
  
  Future<void> deleteSplitGroup(String userId, String groupId) async {
    await _splitGroupsCollection(userId).doc(groupId).delete();
  }

  Future<String> addGroupExpense(String userId, String groupId, GroupExpense expense) async {
    final docRef = await _groupExpensesCollection(userId, groupId).add(expense.toMap());
    return docRef.id;
  }
  
  Future<void> updateGroupExpense(String userId, String groupId, GroupExpense expense) async {
    await _groupExpensesCollection(userId, groupId).doc(expense.id).update(expense.toMap());
  }

  Future<void> updateGroupExpenseHoldStatus(String userId, String groupId, String expenseId, bool isHold) async {
    await _groupExpensesCollection(userId, groupId).doc(expenseId).update({
      'isHold': isHold,
    });
  }

  Stream<List<GroupExpense>> fetchGroupExpenses(String userId, String groupId) {
    return _groupExpensesCollection(userId, groupId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GroupExpense.fromMap(data, doc.id);
      }).toList();
    });
  }

  Future<void> deleteGroupExpense(String userId, String groupId, String expenseId) async {
    await _groupExpensesCollection(userId, groupId).doc(expenseId).delete();
  }
}