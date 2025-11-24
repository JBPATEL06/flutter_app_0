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
import './screens/split_expense_screen.dart'; // NEW IMPORT
import './screens/group_detail_screen.dart'; // NEW IMPORT

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
      home: const AuthWrapper(),
      routes: {
        LoginScreen.name: (_) => const LoginScreen(),
        SignupScreen.name: (_) => const SignupScreen(),
        ForgotPasswordScreen.name: (_) => const ForgotPasswordScreen(),
        CategoryScreen.name: (_) => const CategoryScreen(),
        ExpenseScreen.name: (_) => const ExpenseScreen(),
        AllExpenses.name: (_) => const AllExpenses(),
        SplitExpenseScreen.name: (_) => const SplitExpenseScreen(), // NEW ROUTE
        GroupDetailScreen.name: (_) => const GroupDetailScreen(), // NEW ROUTE
      },
    );
  }
}

// Auth wrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          // Initialize categories for the user if needed
          final firestoreService = FirestoreService();
          firestoreService.initializeCategories(snapshot.data!.uid);

          // Navigate to category screen
          // We will start on the CategoryScreen by default
          return const CategoryScreen();
        }

        // If user is not logged in, show login screen
        return const LoginScreen();
      },
    );
  }
}