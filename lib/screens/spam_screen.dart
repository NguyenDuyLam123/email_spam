import 'package:flutter/material.dart';
import '../utils/spam_detector.dart';
import '../services/gmail_service.dart';

class SpamScreen extends StatefulWidget {
  final List emails;
  final String token;

  SpamScreen({required this.emails, required this.token});

  @override
  _SpamScreenState createState() => _SpamScreenState();
}

class _SpamScreenState extends State<SpamScreen> {
  List spamEmails = [];

  @override
  void initState() {
    super.initState();
    filterSpam();
  }

  void filterSpam() {
    List result = [];

    for (var e in widget.emails) {
      if (SpamDetector.isSpam(e['snippet'])) {
        result.add(e);
      }
    }

    setState(() {
      spamEmails = result;
    });
  }

  void deleteOne(int index) async {
    bool confirmed = await confirmDelete(
      "Bạn có chắc muốn chuyển email này vào thùng rác Gmail?",
    );

    if (!confirmed) return;

    var email = spamEmails[index];

    try {
      await GmailService().moveToTrash(email['id'], widget.token);

      setState(() {
        spamEmails.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email đã được chuyển vào thùng rác")),
      );
    } catch (e) {
      print("Delete error: $e");
    }
  }

  void deleteAll() async {
    bool confirmed = await confirmDelete(
      "Bạn có chắc muốn xóa toàn bộ email spam?",
    );

    if (!confirmed) return;

    try {
      for (var e in spamEmails) {
        await GmailService().moveToTrash(e['id'], widget.token);
      }

      setState(() {
        spamEmails.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã chuyển toàn bộ email vào thùng rác")),
      );
    } catch (e) {
      print("Delete all error: $e");
    }
  }

  Future<bool> confirmDelete(String message) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Xác nhận"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Xóa"),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh sách Email Spam"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), //quay lại
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: spamEmails.isEmpty
                ? Center(child: Text("Không có email spam"))
                : ListView.builder(
                    itemCount: spamEmails.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(spamEmails[index]['subject'] ?? ""),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(spamEmails[index]['from']),
                            Text(spamEmails[index]['snippet']),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deleteOne(index),
                        ),
                      );
                    },
                  ),
          ),

          // DELETE ALL
          if (spamEmails.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: deleteAll,
                  child: Text("Xóa toàn bộ email spam"),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
