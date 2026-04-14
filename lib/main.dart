import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/gmail_service.dart';
import '../utils/spam_detector.dart';
import '../screens/email_screen.dart';
import '../screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: LoginScreen());
  }
}
