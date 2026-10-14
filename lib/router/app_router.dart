import 'package:flutter/material.dart';

import '../screens/auth/auth_gate.dart';
import '../screens/history/history_screen.dart';
import '../screens/transaction/add_transaction_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRouter {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => const AuthGate(),

    '/register': (context) => const RegisterScreen(),

    '/history': (context) =>
        const HistoryScreen(),

    '/transaction/add': (context) =>
        const AddTransactionScreen(),
    
    '/profile': (context) => const ProfileScreen(),
  };
}