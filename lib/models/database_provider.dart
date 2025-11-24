import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import './ex_category.dart';
import './expense.dart';

class DatabaseProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  String _searchText = '';
  String get searchText => _searchText;
  set searchText(String value) {
    _searchText = value;
    notifyListeners();
  }

  // In-app memory for holding the Expense categories temporarily
  List<ExpenseCategory> _categories = [];
  List<ExpenseCategory> get categories => _categories;

  List<Expense> _expenses = [];
  // When the search text is empty, return whole list, else search for the value
  List<Expense> get expenses {
    return _searchText != ''
        ? _expenses
            .where((e) =>
                e.title.toLowerCase().contains(_searchText.toLowerCase()))
            .toList()
        : _expenses;
  }

  // Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // Initialize categories for new user
  Future<void> initializeCategories() async {
    if (_userId == null) return;
    await _firestoreService.initializeCategories(_userId!);
  }

  // Fetch categories with real-time updates
  void fetchCategories() {
    if (_userId == null) return;

    _firestoreService.fetchCategories(_userId!).listen((categories) {
      _categories = categories;
      notifyListeners();
    });
  }

  // Update category
  Future<void> updateCategory(
    String category,
    int nEntries,
    double nTotalAmount,
  ) async {
    if (_userId == null) return;

    await _firestoreService.updateCategory(
      _userId!,
      category,
      nEntries,
      nTotalAmount,
    );

    // Update in-app memory
    var file = _categories.firstWhere((element) => element.title == category);
    file.entries = nEntries;
    file.totalAmount = nTotalAmount;
    notifyListeners();
  }

  // Add an expense to database
  Future<void> addExpense(Expense exp) async {
    if (_userId == null) return;

    // Add to Firestore
    final docId = await _firestoreService.addExpense(_userId!, exp);

    // Create expense with generated ID
    final file = Expense(
      id: docId,
      title: exp.title,
      amount: exp.amount,
      date: exp.date,
      category: exp.category,
    );

    // Add to in-app memory
    _expenses.add(file);
    notifyListeners();

    // Update category
    var ex = findCategory(exp.category);
    updateCategory(exp.category, ex.entries + 1, ex.totalAmount + exp.amount);
  }

  // Delete expense
  Future<void> deleteExpense(
      String expId, String category, double amount) async {
    if (_userId == null) return;

    await _firestoreService.deleteExpense(_userId!, expId);

    // Remove from in-app memory
    _expenses.removeWhere((element) => element.id == expId);
    notifyListeners();

    // Update category
    var ex = findCategory(category);
    updateCategory(category, ex.entries - 1, ex.totalAmount - amount);
  }

  // Fetch expenses by category with real-time updates
  void fetchExpenses(String category) {
    if (_userId == null) return;

    _firestoreService.fetchExpenses(_userId!, category).listen((expenses) {
      _expenses = expenses;
      notifyListeners();
    });
  }

  // Fetch all expenses with real-time updates
  void fetchAllExpenses() {
    if (_userId == null) return;

    _firestoreService.fetchAllExpenses(_userId!).listen((expenses) {
      _expenses = expenses;
      notifyListeners();
    });
  }

  // Find category by title
  ExpenseCategory findCategory(String title) {
    return _categories.firstWhere((element) => element.title == title);
  }

  // Calculate entries and amount for a category
  Map<String, dynamic> calculateEntriesAndAmount(String category) {
    double total = 0.0;
    var list = _expenses.where((element) => element.category == category);
    for (final i in list) {
      total += i.amount;
    }
    return {'entries': list.length, 'totalAmount': total};
  }

  // Calculate total expenses
  double calculateTotalExpenses() {
    return _categories.fold(
        0.0, (previousValue, element) => previousValue + element.totalAmount);
  }

  // Calculate week expenses
  List<Map<String, dynamic>> calculateWeekExpenses() {
    List<Map<String, dynamic>> data = [];

    // We know that we need 7 entries
    for (int i = 0; i < 7; i++) {
      // 1 total for each entry
      double total = 0.0;
      // Subtract i from today to get previous dates
      final weekDay = DateTime.now().subtract(Duration(days: i));

      // Check how many transactions happened that day
      for (int j = 0; j < _expenses.length; j++) {
        if (_expenses[j].date.year == weekDay.year &&
            _expenses[j].date.month == weekDay.month &&
            _expenses[j].date.day == weekDay.day) {
          // If found then add the amount to total
          total += _expenses[j].amount;
        }
      }

      // Add to a list
      data.add({'day': weekDay, 'amount': total});
    }
    // Return the list
    return data;
  }
}
