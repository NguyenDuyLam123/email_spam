import 'package:flutter/material.dart';
import '../services/gmail_service.dart';
import '../utils/spam_detector.dart';

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
