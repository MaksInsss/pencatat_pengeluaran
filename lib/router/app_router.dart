import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/transaction/add_transaction_screen.dart';

class AppRouter {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => const HomeScreen(),

    '/history': (context) =>
        const HistoryScreen(),

    '/transaction/add': (context) =>
        const AddTransactionScreen(),
  };
}