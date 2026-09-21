import 'package:flutter/material.dart';
import 'router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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