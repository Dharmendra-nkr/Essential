import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditNotePage extends StatefulWidget {
  final String noteId;
  final String initialContent;

  const EditNotePage({
    super.key,
    required this.noteId,
    required this.initialContent,
  });

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  Future<void> _updateNote() async {
    String newContent = _controller.text.trim();
    if (newContent.isEmpty) return;

    String uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc(widget.noteId)
        .update({'content': newContent});

    // Go back to the first screen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // prevent keyboard overflow
      appBar: AppBar(title: const Text('Edit Note')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Edit your note',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null, // allows unlimited lines
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateNote,
                child: const Text('Update Note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
