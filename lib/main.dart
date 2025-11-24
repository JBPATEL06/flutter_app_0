// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './models/database_provider.dart';
import './services/firestore_service.dart';
// screens
import './screens/login_screen.dart';
import './screens/signup_screen.dart';
import './screens/forgot_password_screen.dart';
import './screens/category_screen.dart';
import './screens/expense_screen.dart';
import './screens/all_expenses.dart';
import './screens/split_expense_screen.dart'; 
import './screens/group_detail_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => DatabaseProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(), // AuthWrapper handles the initial routing
      routes: {
        LoginScreen.name: (_) => const LoginScreen(),
        SignupScreen.name: (_) => const SignupScreen(),
        ForgotPasswordScreen.name: (_) => const ForgotPasswordScreen(),
        CategoryScreen.name: (_) => const CategoryScreen(),
        ExpenseScreen.name: (_) => const ExpenseScreen(),
        AllExpenses.name: (_) => const AllExpenses(),
        SplitExpenseScreen.name: (_) => const SplitExpenseScreen(), 
        GroupDetailScreen.name: (_) => const GroupDetailScreen(), 
      },
    );
  }
}

// Auth wrapper uses Firebase Auth Stream to determine the initial screen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // The core function for checking Firebase Auth session state
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. SPLASH SCREEN / LOADING STATE: 
        // This runs when Firebase is checking for an active session token.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade800,
                    Colors.purple.shade600,
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 100,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Expense Manager',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 32),
                    CircularProgressIndicator(color: Colors.white),
                  ],
                ),
              ),
            ),
          );
        }

        // 2. LOGGED IN STATE: If Firebase finds a valid user token
        if (snapshot.hasData && snapshot.data != null) {
          // Initialize categories for new user if needed
          final firestoreService = FirestoreService();
          firestoreService.initializeCategories(snapshot.data!.uid);

          // Navigate to category screen
          return const CategoryScreen();
        }

        // 3. LOGGED OUT STATE: If there is no user, show login screen
        return const LoginScreen();
      },
    );
  }
}