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

class LoginScreen extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SafeInbox")),
      body: Center(
        child: ElevatedButton(
          child: Text("Login with Google"),
          onPressed: () async {
            await _auth.signIn();
            String? token = await _auth.getAccessToken();

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EmailScreen(token: token!)),
            );
          },
        ),
      ),
    );
  }
}

class EmailScreen extends StatefulWidget {
  final String token;

  EmailScreen({required this.token});

  @override
  _EmailScreenState createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final GmailService _gmail = GmailService();
  List emails = [];

  @override
  void initState() {
    super.initState();
    loadEmails();
  }

  void loadEmails() async {
    final data = await _gmail.fetchEmails(widget.token);

    List spamEmails = [];

    for (var e in data) {
      var detail = await _gmail.getEmailDetail(e['id'], widget.token);

      String snippet = detail['snippet'] ?? "";

      if (SpamDetector.isSpam(snippet)) {
        spamEmails.add({'id': e['id'], 'snippet': snippet});
      }
    }

    setState(() {
      emails = spamEmails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Spam Emails")),
      body: ListView.builder(
        itemCount: emails.length,
        itemBuilder: (context, index) {
          var email = emails[index];

          return ListTile(
            title: Text(email['snippet']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.undo),
                  onPressed: () {
                    setState(() {
                      emails.removeAt(index);
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      emails.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
