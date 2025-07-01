// add_notes.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNotesPage extends StatefulWidget {
  const AddNotesPage({super.key});
  @override
  State<AddNotesPage> createState() => _AddNotesPageState();
}

class _AddNotesPageState extends State<AddNotesPage> {
  final _noteController = TextEditingController();

  Future<void> _saveNote() async {
    String content = _noteController.text.trim();
    if (content.isEmpty) return;
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .add({'content': content});
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Note')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: null,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveNote,
              child: const Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}
