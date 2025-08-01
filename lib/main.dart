import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// MODEL
class Task {
  String title;
  String priority;
  bool isDone;

  Task({required this.title, this.priority = 'Low', this.isDone = false});

  Map<String, dynamic> toJson() =>
      {'title': title, 'priority': priority, 'isDone': isDone};

  factory Task.fromJson(Map<String, dynamic> json) => Task(
      title: json['title'],
      priority: json['priority'],
      isDone: json['isDone'] ?? false);
}

void main() {
  runApp(const FocusTreeApp());
}

// MAIN APP
class FocusTreeApp extends StatelessWidget {
  const FocusTreeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Focus Timer',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.green[50],
        fontFamily: 'Playfair', // Using your font from yaml
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.green),
        ),
      ),
      home: const RootScreen(),
    );
  }
}

// ROOT with Bottom Navigation and Logo
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  // Tasks shared between screens
  final List<Task> tasks = [];

  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('tasks') ?? [];
    setState(() {
      tasks.clear();
      tasks.addAll(saved
          .map((e) => Task.fromJson(
          Map<String, dynamic>.from(Uri.splitQueryString(e))))
          .toList());
    });
  }

  Future<void> _saveTasks() async {
    final encoded = tasks
        .map((t) =>
    'title=${Uri.encodeComponent(t.title)}&priority=${Uri.encodeComponent(t.priority)}&isDone=${t.isDone}')
        .toList();
    await prefs.setStringList('tasks', encoded);
  }

  void _addTask(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      tasks.add(Task(title: title.trim()));
      _saveTasks();
    });
  }

  void _updateTaskPriority(int index, String newPriority) {
    setState(() {
      tasks[index].priority = newPriority;
      _saveTasks();
    });
  }

  void _toggleTaskDone(int index, bool? val) {
    setState(() {
      tasks[index].isDone = val ?? false;
      _saveTasks();
    });
  }

  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
      _saveTasks();
    });
  }

  static const List<Widget> _screens = [];

  @override
  Widget build(BuildContext context) {
    // Screen widgets passing tasks and handlers
    final List<Widget> screens = [
      TimerScreen(),
      TasksScreen(
        tasks: tasks,
        onAdd: _addTask,
        onUpdatePriority: _updateTaskPriority,
        onToggleDone: _toggleTaskDone,
        onDelete: _deleteTask,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo.png',
          height: 160, // bigger size
          width: 160,
          fit: BoxFit.contain,
        ),
      ),

      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[900],
        unselectedItemColor: Colors.green[300],
        backgroundColor: Colors.green[50],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}

// TIMER SCREEN
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int focusSeconds = 25 * 60;
  int secondsLeft = 25 * 60;
  Timer? timer;
  bool isRunning = false;

  int seedStage = 1; // 1 to 5

  final focusTimeController = TextEditingController(text: '25');

  void startTimer() {
    if (isRunning) return;
    setState(() => isRunning = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft == 0) {
        timer?.cancel();
        setState(() {
          isRunning = false;
          seedStage = 5;
        });
      } else {
        setState(() {
          secondsLeft--;
          seedStage = ((1 + (4 * (focusSeconds - secondsLeft) / focusSeconds))
              .clamp(1, 5))
              .toInt();
        });
      }
    });
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      secondsLeft = focusSeconds;
      isRunning = false;
      seedStage = 1;
    });
  }

  String formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer?.cancel();
    focusTimeController.dispose();
    super.dispose();
  }

  String seedImage() => 'assets/images/seed$seedStage.png';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.green[100],
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set Focus Time (minutes)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: focusTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          focusSeconds = parsed * 60;
                          secondsLeft = focusSeconds;
                          seedStage = 1;
                          resetTimer();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset(
                  seedImage(),
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  formatTime(secondsLeft),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: startTimer,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700]),
                      child: const Text('Start'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: resetTimer,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400]),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// TASKS SCREEN
class TasksScreen extends StatefulWidget {
  final List<Task> tasks;
  final void Function(String) onAdd;
  final void Function(int, String) onUpdatePriority;
  final void Function(int, bool?) onToggleDone;
  final void Function(int) onDelete;

  const TasksScreen({
    super.key,
    required this.tasks,
    required this.onAdd,
    required this.onUpdatePriority,
    required this.onToggleDone,
    required this.onDelete,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  Color priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent.shade400;
      case 'Medium':
        return Colors.orangeAccent.shade400;
      default:
        return Colors.greenAccent.shade400;
    }
  }

  final addController = TextEditingController();

  @override
  void dispose() {
    addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AddTaskWidget(
            controller: addController,
            onAdd: (val) {
              widget.onAdd(val);
              addController.clear();
              FocusScope.of(context).unfocus();
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.tasks.isEmpty
                ? const Center(
              child: Text(
                'No tasks yet. Add one!',
                style: TextStyle(color: Colors.green),
              ),
            )
                : ListView.builder(
              itemCount: widget.tasks.length,
              itemBuilder: (context, index) {
                final task = widget.tasks[index];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: task.isDone
                      ? Colors.green[100]
                      : priorityColor(task.priority).withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.isDone,
                      onChanged: (val) =>
                          widget.onToggleDone(index, val),
                      activeColor: Colors.green[800],
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: Colors.green[900],
                          fontWeight: FontWeight.w600),
                    ),
                    trailing: DropdownButton<String>(
                      value: task.priority,
                      dropdownColor: Colors.green[50],
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: 'Low',
                            child: Text('Low',
                                style: TextStyle(color: Colors.green))),
                        DropdownMenuItem(
                            value: 'Medium',
                            child: Text('Medium',
                                style: TextStyle(color: Colors.orange))),
                        DropdownMenuItem(
                            value: 'High',
                            child: Text('High',
                                style: TextStyle(color: Colors.red))),
                      ],
                      onChanged: (val) {
                        if (val != null) widget.onUpdatePriority(index, val);
                      },
                    ),
                    onLongPress: () => widget.onDelete(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Add Task Input
class AddTaskWidget extends StatelessWidget {
  final void Function(String) onAdd;
  final TextEditingController controller;

  const AddTaskWidget({
    super.key,
    required this.onAdd,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Add new task...',
            fillColor: Colors.green[50],
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: () {
          onAdd(controller.text);
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
        child: const Icon(Icons.add),
      ),
    ]);
  }
}
