import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'login_page.dart';
import 'owner_page.dart';
import 'customer_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _initialPage = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final auth = AuthService();
    final user = await auth.getStoredUser();

    if (user != null) {
      final userId = user['user_id'];
      final role = user['role'];

      if (role == 'owner') {
        setState(() {
          _initialPage = OwnerPage(ownerId: userId!);
        });
      } else {
        setState(() {
          _initialPage = CustomerPage(customerId: userId!);
        });
      }
    } else {
      setState(() {
        _initialPage = const LoginPage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _initialPage,
    );
  }
}
