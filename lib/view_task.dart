import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ViewTaskPage extends StatefulWidget {
  final String taskId;

  const ViewTaskPage({super.key, required this.taskId});

  @override
  State<ViewTaskPage> createState() => _ViewTaskPageState();
}

class _ViewTaskPageState extends State<ViewTaskPage> {
  late DocumentReference taskRef;
  late CollectionReference subtasksRef;
  String title = '';
  String description = '';
  DateTime? dueDate;
  List<Map<String, dynamic>> subtasks = [];

  @override
  void initState() {
    super.initState();
    String uid = FirebaseAuth.instance.currentUser!.uid;
    taskRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(widget.taskId);

    subtasksRef = taskRef.collection('subtasks');
    fetchTask();
  }

  void fetchTask() async {
    final snapshot = await taskRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        title = data['title'] ?? '';
        description = data['description'] ?? '';
        if (data['date'] != null) {
          try {
            dueDate = DateTime.parse(data['date']);
          } catch (e) {
            print("Error parsing date: $e");
            dueDate = null;
          }
        } else {
          dueDate = null;
        }
      });
    }

    final subtaskSnapshot = await subtasksRef.get();
    setState(() {
      subtasks =
          subtaskSnapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'title': doc['content'] ?? '',
              'done': doc['completed'] ?? false,
            };
          }).toList();
    });
  }

  void updateSubtask(int index, bool? value) async {
    setState(() {
      subtasks[index]['done'] = value ?? false;
    });

    await subtasksRef.doc(subtasks[index]['id']).update({
      'completed': subtasks[index]['done'],
    });
  }

  Future<void> showAddSubtaskDialog() async {
    String newSubtask = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Subtask"),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
              newSubtask = value;
            },
            decoration: const InputDecoration(hintText: "Enter subtask name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (newSubtask.trim().isNotEmpty) {
                  final docRef = await subtasksRef.add({
                    'content': newSubtask.trim(),
                    'completed': false,
                  });
                  setState(() {
                    subtasks.add({
                      'id': docRef.id,
                      'title': newSubtask.trim(),
                      'done': false,
                    });
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Widget buildDueDateInfo() {
    if (dueDate == null) return const SizedBox();

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy MM dd').format(dueDate!);

    Color color;
    String label;

    if (dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day) {
      color = Colors.green;
      label = 'Today';
    } else if (dueDate!.isAfter(DateTime(now.year, now.month, now.day))) {
      color = Colors.blue;
      label = formattedDate;
    } else {
      color = Colors.red;
      label = formattedDate;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Due: $label', style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int total = subtasks.length;
    int completed = subtasks.where((s) => s['done'] == true).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            title.isEmpty && description.isEmpty && subtasks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(description, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(
                      '$completed/$total SUBTASKS COMPLETED',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 234, 0, 255),
                      ),
                    ),
                    buildDueDateInfo(),
                    // Adjusted padding here
                    const SizedBox(
                      height: 30,
                    ), // Adds space before subtasks section
                    const Text('Subtasks:', style: TextStyle(fontSize: 18)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: subtasks.length,
                        itemBuilder: (context, index) {
                          var sub = subtasks[index];

                          return Dismissible(
                            key: Key(sub['id']),
                            direction: DismissDirection.startToEnd,
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Deletion'),
                                    content: Text(
                                      'Delete subtask "${sub['title']}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) async {
                              await subtasksRef.doc(sub['id']).delete();
                              setState(() {
                                subtasks.removeAt(index);
                              });
                            },
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: CheckboxListTile(
                              title: Text(sub['title'] ?? ''),
                              value: sub['done'] ?? false,
                              onChanged: (val) => updateSubtask(index, val),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddSubtaskDialog,
        tooltip: 'Add Subtask',
        child: const Icon(Icons.add),
      ),
    );
  }
}
