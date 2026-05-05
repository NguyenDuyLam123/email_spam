import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'email_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  Future<void> _handleLogin(BuildContext context) async {
    final AuthService auth = AuthService();

    await auth.signIn();
    String? token = await auth.getAccessToken();

    if (token == null) return;

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => EmailScreen(token: token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO + TITLE
            Column(
              children: [
                Image.asset('assets/images/logo.jpg', height: 80),
                const SizedBox(height: 12),
                const Text(
                  "SafeInbox",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // LOGIN BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 2,
                ),
                icon: Image.network(
                  "https://cdn-icons-png.flaticon.com/512/281/281764.png",
                  height: 24,
                ),
                label: const Text("Đăng nhập với Google"),
                onPressed: () => _handleLogin(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
