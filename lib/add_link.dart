// add_link.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddLinkPage extends StatefulWidget {
  const AddLinkPage({super.key});
  @override
  State<AddLinkPage> createState() => _AddLinkPageState();
}

class _AddLinkPageState extends State<AddLinkPage> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  Future<void> _saveLink() async {
    String name = _nameController.text.trim();
    String url = _urlController.text.trim();
    if (name.isEmpty || url.isEmpty) return;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('links')
        .add({'name': name, 'url': url});
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Link')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Link Name'),
            ),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveLink,
              child: const Text('Save Link'),
            ),
          ],
        ),
      ),
    );
  }
}
