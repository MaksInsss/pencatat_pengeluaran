import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'services/api_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Saat server membalas 401 (token dicabut/tidak valid), token lokal sudah
  // dihapus oleh ApiService. Kembali ke '/', lalu AuthGate melihat tidak ada
  // token dan menampilkan layar login.
  ApiService.onUnauthorized = () {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Keuangan Saya',
      theme: ThemeData(
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: AppRouter.routes,
    );
  }
}