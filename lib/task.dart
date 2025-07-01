import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_task.dart';
import 'notes.dart';
import 'links.dart';
import 'view_task.dart';
import 'login.dart';

class TaskPage extends StatefulWidget {
  final bool fromSignup;
  const TaskPage({super.key, this.fromSignup = false});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser!;
  String _username = 'User';
  bool _isDarkTheme = false; // <-- Add this

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  Future<void> _getUserName() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (userDoc.exists) {
      setState(() {
        _username = userDoc['username'] ?? 'User';
      });
    }
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('App information'),
            content: const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Developed by ',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                  TextSpan(
                    text: 'Dharmendra NKR\n\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'Essential is a simple yet powerful task management app designed to help you stay organized and productive.\n\n',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                  TextSpan(
                    text:
                        'This app allows you to efficiently manage your tasks by tracking the completion of individual subtasks. It also includes additional features like note-taking and link storage (coming in a future update).\n',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                  TextSpan(
                    text: '[Right swipe a task/subtask to delete]\n\n',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),

                  TextSpan(
                    text: 'Version: 1.1.0\n\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'Thank you for using Essential!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TaskTab(key: UniqueKey()),
      const NotesTab(),
      const LinksTab(),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Hello $_username!'),
          actions: [
            // Toggle theme
            IconButton(
              icon: Icon(_isDarkTheme ? Icons.dark_mode : Icons.light_mode),
              onPressed: _toggleTheme,
              tooltip: 'Toggle Theme',
            ),
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: _showAppInfoDialog,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
            ),
          ],
        ),
        body: pages[_selectedIndex],
        floatingActionButton:
            _selectedIndex == 0
                ? FloatingActionButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddTaskPage()),
                      ),
                  child: const Icon(Icons.add),
                )
                : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.check_box), label: 'Tasks'),
            NavigationDestination(icon: Icon(Icons.note), label: 'Notes'),
            NavigationDestination(icon: Icon(Icons.link), label: 'Links'),
          ],
        ),
      ),
    );
  }
}

// ✅ Changed TaskTab to StatefulWidget
class TaskTab extends StatefulWidget {
  const TaskTab({super.key});

  @override
  State<TaskTab> createState() => _TaskTabState();
}

class _TaskTabState extends State<TaskTab> {
  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('tasks')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text('Error loading tasks'));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No tasks yet'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String title = data['title'] ?? '';
            bool done = data['done'] ?? false;

            Timestamp? dueTimestamp = data['due'];
            String dueStatement = 'No due date';
            Color dueColor = const Color.fromARGB(255, 202, 9, 220);
            String formattedDueDate = '';

            if (dueTimestamp != null) {
              try {
                DateTime dueDate = dueTimestamp.toDate();
                formattedDueDate = DateFormat('dd MMM yyyy').format(dueDate);
                DateTime now = DateTime.now();
                DateTime today = DateTime(now.year, now.month, now.day);
                DateTime due = DateTime(
                  dueDate.year,
                  dueDate.month,
                  dueDate.day,
                );
                int difference = due.difference(today).inDays;

                if (difference == 0) {
                  dueStatement = 'Due today';
                  dueColor = Colors.orange;
                } else if (difference < 0) {
                  dueStatement = 'Overdue by ${difference.abs()}d';
                  dueColor = Colors.red;
                } else {
                  dueStatement = 'Due in $difference d';
                  dueColor = Colors.blue;
                }
              } catch (e) {
                print('Error processing due date: $e');
              }
            }

            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.startToEnd,
              confirmDismiss: (_) async {
                return await showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Delete Task'),
                        content: const Text(
                          'Are you sure you want to delete this task?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
              onDismissed: (_) async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('tasks')
                    .doc(doc.id)
                    .delete();
              },
              background: Container(
                padding: const EdgeInsets.only(left: 20),
                alignment: Alignment.centerLeft,
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                decoration: BoxDecoration(
                  color:
                      done
                          ? const Color.fromARGB(
                            255,
                            177,
                            248,
                            147,
                          ) // Fixed color for completed tasks
                          : const Color(
                            0xFFFFFFFF,
                          ), // Fixed color for incomplete tasks
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewTaskPage(taskId: doc.id),
                        ),
                      );
                      setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    decoration:
                                        done
                                            ? TextDecoration.lineThrough
                                            : null,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color:
                                        Colors
                                            .black, // Fixed text color for title
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDueDate.isNotEmpty
                                      ? formattedDueDate
                                      : 'No due date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: const Color.fromARGB(
                                      255,
                                      180,
                                      26,
                                      208,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dueStatement,
                                  style: TextStyle(
                                    color: dueColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FutureBuilder<QuerySnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .collection('tasks')
                                    .doc(doc.id)
                                    .collection('subtasks')
                                    .get(),
                            builder: (context, subtaskSnapshot) {
                              if (subtaskSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(width: 16);
                              }

                              if (subtaskSnapshot.hasError ||
                                  !subtaskSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final subtaskDocs = subtaskSnapshot.data!.docs;
                              if (subtaskDocs.isEmpty) {
                                return const Text('0%');
                              }

                              int completedCount =
                                  subtaskDocs.where((doc) {
                                    return (doc.data()
                                            as Map<
                                              String,
                                              dynamic
                                            >)['completed'] ==
                                        true;
                                  }).length;

                              double percent =
                                  (completedCount / subtaskDocs.length) * 100;
                              return Text(
                                '${percent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(
                              done
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: done ? Colors.green : Colors.grey,
                            ),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('tasks')
                                  .doc(doc.id)
                                  .update({'done': !done});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
