import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_notes.dart';
import 'view_notes.dart'; // Added for viewing/editing/deleting notes

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('notes')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Error loading notes'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No notes yet'));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              String noteId = doc.id;
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String content = data['content'] ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ViewNotePage(noteId: noteId, content: content),
                    ),
                  );
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      content,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNotesPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
