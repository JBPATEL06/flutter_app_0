// lib/models/database_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import './ex_category.dart';
import './expense.dart';
import './split_group.dart'; 

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
  List<Expense> get expenses {
    return _searchText != ''
        ? _expenses
            .where((e) =>
                e.title.toLowerCase().contains(_searchText.toLowerCase()))
            .toList()
        : _expenses;
  }

  // Split Group State
  List<SplitGroup> _splitGroups = [];
  // Filter only by search text, as hold feature is removed for groups.
  List<SplitGroup> get splitGroups {
    return _searchText != ''
        ? _splitGroups
            .where((g) => g.title.toLowerCase().contains(_searchText.toLowerCase()))
            .toList()
        : _splitGroups;
  }
  
  List<SplitGroup> get allSplitGroups => _splitGroups;

  SplitGroup? _currentSplitGroup;
  SplitGroup? get currentSplitGroup => _currentSplitGroup;

  List<GroupExpense> _groupExpenses = [];
  List<GroupExpense> get groupExpenses {
    return _groupExpenses.where((e) => e.isHold == false).toList();
  }
  
  List<GroupExpense> get allGroupExpenses => _groupExpenses;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // Existing Expense Category Methods
  Future<void> initializeCategories() async {
    if (_userId == null) return;
    await _firestoreService.initializeCategories(_userId!);
  }

  void fetchCategories() {
    if (_userId == null) return;
    _firestoreService.fetchCategories(_userId!).listen((categories) {
      _categories = categories;
      notifyListeners();
    });
  }

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
    var file = _categories.firstWhere((element) => element.title == category);
    file.entries = nEntries;
    file.totalAmount = nTotalAmount;
    notifyListeners();
  }

  Future<void> addExpense(Expense exp) async {
    if (_userId == null) return;
    final docId = await _firestoreService.addExpense(_userId!, exp);
    final file = Expense(
      id: docId,
      title: exp.title,
      amount: exp.amount,
      date: exp.date,
      category: exp.category,
    );
    _expenses.add(file);
    notifyListeners();
    var ex = findCategory(exp.category);
    updateCategory(exp.category, ex.entries + 1, ex.totalAmount + exp.amount);
  }

  Future<void> deleteExpense(
      String expId, String category, double amount) async {
    if (_userId == null) return;
    await _firestoreService.deleteExpense(_userId!, expId);
    _expenses.removeWhere((element) => element.id == expId);
    notifyListeners();
    var ex = findCategory(category);
    updateCategory(category, ex.entries - 1, ex.totalAmount - amount);
  }

  void fetchExpenses(String category) {
    if (_userId == null) return;
    _firestoreService.fetchExpenses(_userId!, category).listen((expenses) {
      _expenses = expenses;
      notifyListeners();
    });
  }

  void fetchAllExpenses() {
    if (_userId == null) return;
    _firestoreService.fetchAllExpenses(_userId!).listen((expenses) {
      _expenses = expenses;
      notifyListeners();
    });
  }

  ExpenseCategory findCategory(String title) {
    return _categories.firstWhere((element) => element.title == title);
  }

  Map<String, dynamic> calculateEntriesAndAmount(String category) {
    double total = 0.0;
    var list = _expenses.where((element) => element.category == category);
    for (final i in list) {
      total += i.amount;
    }
    return {'entries': list.length, 'totalAmount': total};
  }

  double calculateTotalExpenses() {
    return _categories.fold(
        0.0, (previousValue, element) => previousValue + element.totalAmount);
  }

  List<Map<String, dynamic>> calculateWeekExpenses() {
    List<Map<String, dynamic>> data = [];
    for (int i = 0; i < 7; i++) {
      double total = 0.0;
      final weekDay = DateTime.now().subtract(Duration(days: i));
      for (int j = 0; j < _expenses.length; j++) {
        if (_expenses[j].date.year == weekDay.year &&
            _expenses[j].date.month == weekDay.month &&
            _expenses[j].date.day == weekDay.day) {
          total += _expenses[j].amount;
        }
      }
      data.add({'day': weekDay, 'amount': total});
    }
    return data;
  }
  
  // SPLIT EXPENSE METHODS

  void fetchSplitGroups() {
    if (_userId == null) return;
    _firestoreService.fetchSplitGroups(_userId!).listen((groups) {
      _splitGroups = groups;
      notifyListeners();
    });
  }

  Future<void> addSplitGroup(String title, List<String> members) async {
    if (_userId == null) return;
    final newGroup = SplitGroup(
      id: '',
      title: title,
      members: members,
      totalExpenses: 0.0
    );
    final docId = await _firestoreService.addSplitGroup(_userId!, newGroup);
    final file = SplitGroup(
      id: docId,
      title: newGroup.title,
      members: newGroup.members,
      totalExpenses: newGroup.totalExpenses,
      isHold: newGroup.isHold
    );
    _splitGroups.add(file);
    notifyListeners();
  }
  
  Future<void> deleteSplitGroup(String groupId) async {
    if (_userId == null) return;
    await _firestoreService.deleteSplitGroup(_userId!, groupId);
    _splitGroups.removeWhere((element) => element.id == groupId);
    notifyListeners();
  }
  
  // REMOVED: toggleSplitGroupHold logic as requested.

  // NEW: Update Split Group Title
  Future<void> updateSplitGroupTitle(String groupId, String newTitle) async {
    if (_userId == null) return;
    
    await _firestoreService.updateSplitGroupTitle(_userId!, groupId, newTitle);
    
    // Update local list manually for immediate UI responsiveness
    final index = _splitGroups.indexWhere((e) => e.id == groupId);
    if (index != -1) {
      final currentGroup = _splitGroups[index];
      _splitGroups[index] = SplitGroup(
        id: currentGroup.id,
        title: newTitle, 
        members: currentGroup.members,
        totalExpenses: currentGroup.totalExpenses,
        isHold: currentGroup.isHold,
      );
    }
    notifyListeners();
  }


  void selectSplitGroup(SplitGroup group) {
    _currentSplitGroup = group;
    if (_userId == null) {
      notifyListeners();
      return;
    }
    _firestoreService.fetchGroupExpenses(_userId!, group.id).listen((expenses) {
      _groupExpenses = expenses;
      
      double total = expenses.where((e) => e.isHold == false).fold(0.0, (sum, exp) => sum + exp.totalAmount);
      
      if (_currentSplitGroup!.totalExpenses.toStringAsFixed(2) != total.toStringAsFixed(2)) {
        final updatedGroup = SplitGroup(
          id: _currentSplitGroup!.id,
          title: _currentSplitGroup!.title,
          members: _currentSplitGroup!.members,
          totalExpenses: total,
          isHold: _currentSplitGroup!.isHold
        );
        _currentSplitGroup = updatedGroup;
        _firestoreService.updateSplitGroup(_userId!, _currentSplitGroup!);
      }

      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> addGroupExpense(GroupExpense exp) async {
    if (_userId == null || _currentSplitGroup == null) return;
    await _firestoreService.addGroupExpense(_userId!, _currentSplitGroup!.id, exp);
  }
  
  Future<void> updateGroupExpense(GroupExpense exp) async {
    if (_userId == null || _currentSplitGroup == null) return;
    await _firestoreService.updateGroupExpense(_userId!, _currentSplitGroup!.id, exp);
  }
  
  Future<void> deleteGroupExpense(String expenseId) async {
    if (_userId == null || _currentSplitGroup == null) return;
    await _firestoreService.deleteGroupExpense(_userId!, _currentSplitGroup!.id, expenseId);
  }

  Future<void> toggleGroupExpenseHold(GroupExpense expense) async {
    if (_userId == null || _currentSplitGroup == null) return;
    final newHoldStatus = !expense.isHold;
    final groupId = _currentSplitGroup!.id;

    await _firestoreService.updateGroupExpenseHoldStatus(
      _userId!, 
      groupId, 
      expense.id, 
      newHoldStatus
    );
  }

  Future<void> addMemberToCurrentGroup(String memberName) async {
    if (_currentSplitGroup == null || _userId == null) return;

    if (!_currentSplitGroup!.members.contains(memberName)) {
      _currentSplitGroup!.members.add(memberName);
      await _firestoreService.updateSplitGroup(_userId!, _currentSplitGroup!);
      notifyListeners();
    }
  }

  Future<void> deleteMemberFromCurrentGroup(String memberName) async {
    if (_currentSplitGroup == null || _userId == null) return;

    _currentSplitGroup!.members.remove(memberName);
    await _firestoreService.updateSplitGroup(_userId!, _currentSplitGroup!);
    notifyListeners();
  }


  // Core Settlement Logic (Custom/Unequal Split amounts)
  List<Map<String, dynamic>> calculateSettlement() {
    if (_currentSplitGroup == null || _groupExpenses.isEmpty) return [];

    final activeExpenses = _groupExpenses.where((e) => e.isHold == false).toList();
    if (activeExpenses.isEmpty) return [];

    final members = _currentSplitGroup!.members;
    final Map<String, double> balances = { for (var member in members) member: 0.0 };

    for (var exp in activeExpenses) { 
      // Credit the person who paid the total amount
      balances[exp.paidBy] = (balances[exp.paidBy] ?? 0.0) + exp.totalAmount;
      
      // Debit involved members their specific share amount (memberShares)
      exp.memberShares.forEach((member, share) {
          balances[member] = (balances[member] ?? 0.0) - share;
      });
    }
    
    final creditors = balances.entries
        .where((e) => e.value > 0.01) 
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value)); 

    final debtors = balances.entries
        .where((e) => e.value < -0.01)
        .toList()
        ..sort((a, b) => a.value.compareTo(b.value)); 
        
    List<Map<String, dynamic>> settlements = [];
    int i = 0, j = 0;
    while (i < creditors.length && j < debtors.length) {
      String creditor = creditors[i].key;
      double creditorAmount = creditors[i].value;
      String debtor = debtors[j].key;
      double debtorAmount = -debtors[j].value; 

      double settlementAmount = (debtorAmount < creditorAmount) ? debtorAmount : creditorAmount;

      settlements.add({
        'payer': debtor,
        'receiver': creditor,
        'amount': settlementAmount,
      });

      // Update balances
      creditors[i] = MapEntry(creditor, creditorAmount - settlementAmount);
      debtors[j] = MapEntry(debtor, debtors[j].value + settlementAmount);

      if (creditors[i].value.abs() < 0.01) i++;
      if (debtors[j].value.abs() < 0.01) j++;
    }
    
    return settlements;
  }
}