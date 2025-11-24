import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/ex_category.dart';
import '../constants/icons.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user-specific collection references
  CollectionReference _categoriesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  CollectionReference _expensesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('expenses');
  }

  // Initialize categories for new user
  Future<void> initializeCategories(String userId) async {
    final categoriesRef = _categoriesCollection(userId);

    // Check if categories already exist
    final snapshot = await categoriesRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return; // Categories already initialized
    }

    // Create initial categories
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

  // Fetch categories
  Stream<List<ExpenseCategory>> fetchCategories(String userId) {
    return _categoriesCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ExpenseCategory.fromString(data);
      }).toList();
    });
  }

  // Update category
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

  // Add expense
  Future<String> addExpense(String userId, Expense expense) async {
    final docRef = await _expensesCollection(userId).add(expense.toMap());
    return docRef.id;
  }

  // Delete expense
  Future<void> deleteExpense(String userId, String expenseId) async {
    await _expensesCollection(userId).doc(expenseId).delete();
  }

  // Fetch expenses by category
  Stream<List<Expense>> fetchExpenses(String userId, String category) {
    return _expensesCollection(userId)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID
        return Expense.fromString(data);
      }).toList();
    });
  }

  // Fetch all expenses
  Stream<List<Expense>> fetchAllExpenses(String userId) {
    return _expensesCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID
        return Expense.fromString(data);
      }).toList();
    });
  }

  // Get category by title
  Future<ExpenseCategory?> getCategory(String userId, String title) async {
    final doc = await _categoriesCollection(userId).doc(title).get();
    if (doc.exists) {
      return ExpenseCategory.fromString(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
