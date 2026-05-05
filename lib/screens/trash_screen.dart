import 'package:flutter/material.dart';
import '../services/gmail_service.dart';

class TrashScreen extends StatefulWidget {
  final String token;

  const TrashScreen({super.key, required this.token});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final GmailService _gmail = GmailService();
  List emails = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTrash();
  }

  void loadTrash() async {
    final data = await _gmail.fetchTrashEmails(widget.token);

    final futures = data.map((e) {
      return _gmail.getEmailDetail(e['id'], widget.token);
    }).toList();

    final fullEmails = await Future.wait(futures);

    if (!mounted) return;

    setState(() {
      emails = fullEmails;
      isLoading = false;
    });
  }

  void restoreEmail(String id) async {
    await _gmail.restoreEmail(id, widget.token);

    // Reload lại danh sách Trash
    loadTrash();

    // Thông báo
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Đã khôi phục email")));
  }

  void confirmRestore(String id) async {
    bool? result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có muốn khôi phục email này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Khôi phục"),
          ),
        ],
      ),
    );

    if (result == true) {
      restoreEmail(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thùng rác")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: emails.length,
              itemBuilder: (_, i) {
                var e = emails[i];

                return ListTile(
                  title: Text(e['subject'] ?? "(No subject)"),
                  subtitle: Text(e['from'] ?? ""),
                  trailing: IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    onPressed: () => confirmRestore(e['id']),
                  ),
                );
              },
            ),
    );
  }
}
