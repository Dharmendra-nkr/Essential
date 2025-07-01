import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _subtaskControllers = [
    TextEditingController(),
  ];
  final List<FocusNode> _subtaskFocusNodes = [FocusNode()];
  final ScrollController _scrollController = ScrollController();

  DateTime? _dueDate;

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.subtract(const Duration(days: 365)),
      lastDate: initial.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _addSubtaskField() {
    if (_subtaskControllers.length < 100) {
      setState(() {
        _subtaskControllers.add(TextEditingController());
        _subtaskFocusNodes.add(FocusNode());
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        FocusScope.of(context).requestFocus(_subtaskFocusNodes.last);
      });
    }
  }

  Future<void> _saveTask() async {
    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task name is required.')));
      return;
    }

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date.')),
      );
      return;
    }

    List<String> subtasks =
        _subtaskControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Adding the task with the due date field stored as Timestamp
    DocumentReference taskRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .add({
          'title': title,
          'description': description,
          'due': Timestamp.fromDate(
            _dueDate!,
          ), // Store the due date as Timestamp
        });

    for (String subtask in subtasks) {
      await taskRef.collection('subtasks').add({
        'content': subtask,
        'completed': false,
      });
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _subtaskControllers) {
      controller.dispose();
    }
    for (var focusNode in _subtaskFocusNodes) {
      focusNode.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
        backgroundColor: isDarkMode ? Colors.black87 : theme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Task Name',
                labelStyle: TextStyle(color: isDarkMode ? Colors.white : null),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: isDarkMode ? Colors.white : null),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: _scrollController,
                children: [
                  const Text('Subtasks:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  ..._subtaskControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    TextEditingController controller = entry.value;
                    FocusNode focusNode = _subtaskFocusNodes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Subtask ${index + 1}',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : null,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickDate,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                            isDarkMode
                                ? Colors.deepPurpleAccent
                                : const Color.fromARGB(255, 244, 206, 255),
                          ),
                        ),
                        child: const Text('Select Due Date'),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate == null
                            ? 'No date chosen'
                            : _dueDate!.toLocal().toString().split(' ')[0],
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addSubtaskField,
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              isDarkMode
                                  ? Colors.green
                                  : const Color.fromARGB(255, 221, 255, 211),
                            ),
                          ),
                          child: const Text('Add Subtask'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveTask,
                          child: const Text('Save Task'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
