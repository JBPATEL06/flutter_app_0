// lib/screens/split_expense_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/database_provider.dart';
import '../widgets/split_expense_screen/split_group_list.dart';
import '../widgets/split_expense_screen/add_group_form.dart';
import '../services/auth_service.dart';
import './category_screen.dart';
import './login_screen.dart'; // ADDED IMPORT

enum MenuAction { logout, expenseCategories }

class SplitExpenseScreen extends StatefulWidget {
  const SplitExpenseScreen({super.key});
  static const name = '/split_expense_screen';

  @override
  State<SplitExpenseScreen> createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends State<SplitExpenseScreen> {
  @override
  void initState() {
// ... (rest of initState is unchanged)
    super.initState();
    // Fetch all split groups when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DatabaseProvider>(context, listen: false).fetchSplitGroups();
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
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
// ... (rest of build method is unchanged)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Expenses'),
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (item) {
              switch (item) {
                case MenuAction.logout:
                  _handleLogout(context);
                  break;
// ... (rest of menu logic is unchanged)
                case MenuAction.expenseCategories:
                  // Switch to Expense Categories Screen
                  Navigator.of(context).pushReplacementNamed(CategoryScreen.name);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuAction>>[
// ... (rest of menu item builder is unchanged)
              const PopupMenuItem<MenuAction>(
                value: MenuAction.expenseCategories,
                child: Row(
                  children: [
                    Icon(Icons.category),
                    SizedBox(width: 8),
                    Text('Expense Categories'),
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
      body: Column(
        children: const [
          Padding(
// ... (rest of widget unchanged)
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Groups',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: SplitGroupList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddGroupForm(),
          );
        },
        child: const Icon(Icons.group_add),
      ),
    );
  }
}