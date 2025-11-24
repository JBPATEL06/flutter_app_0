// lib/screens/category_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/category_screen/category_fetcher.dart';
import '../widgets/expense_form.dart';
import './split_expense_screen.dart'; 
import './login_screen.dart'; // ADDED IMPORT

enum MenuAction { logout, splitExpense } 

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});
  static const name = '/category_screen';
  
  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      final authService = AuthService();
      await authService.signOut();
      
      // FIX: Clear all routes and push to the LoginScreen
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginScreen.name, 
          (route) => false, // Clears the entire navigation stack
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Categories'),
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (item) {
              switch (item) {
                case MenuAction.logout:
                  _handleLogout(context);
                  break;
                case MenuAction.splitExpense:
                  // Switch to Split Expense Screen
                  Navigator.of(context).pushReplacementNamed(SplitExpenseScreen.name);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuAction>>[
              const PopupMenuItem<MenuAction>(
                value: MenuAction.splitExpense,
                child: Row(
                  children: [
                    Icon(Icons.group),
                    SizedBox(width: 8),
                    Text('Group Expenses'),
                  ],
                ),
              ),
              const PopupMenuItem<MenuAction>(
                value: MenuAction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: const CategoryFetcher(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const ExpenseForm(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}