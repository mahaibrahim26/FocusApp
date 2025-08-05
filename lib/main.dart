import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FocusTreeApp());
}

class FocusTreeApp extends StatelessWidget {
  const FocusTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Focus Timer',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.green[50],
        fontFamily: 'Playfair',
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.green)),
      ),
      home: const RootScreen(),
    );
  }
}

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

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;
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
          .map((e) => Task.fromJson(Map<String, dynamic>.from(Uri.splitQueryString(e))))
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

  @override
  Widget build(BuildContext context) {
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
        title: Image.asset('assets/images/logo.png', height: 160, width: 160),
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[900],
        unselectedItemColor: Colors.green[300],
        backgroundColor: Colors.green[50],
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Tasks'),
        ],
      ),
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with SingleTickerProviderStateMixin {
  bool isRunning = false;
  bool isPomodoro = false;
  int remainingSeconds = 1500;
  int totalSeconds = 1500;
  Timer? timer;
  final customController = TextEditingController();
  late AnimationController orbitController;

  @override
  void initState() {
    super.initState();
    orbitController = AnimationController(
      vsync: this,
      duration: Duration(seconds: remainingSeconds),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    orbitController.dispose();
    super.dispose();
  }

  void startTimer() {
    if (isRunning) return;
    setState(() => isRunning = true);

    orbitController.duration = Duration(seconds: totalSeconds);
    orbitController.forward(from: 1 - (remainingSeconds / totalSeconds)); // ✅ syncs dot with time

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds == 0) {
        stopTimer();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }


  void stopTimer() {
    timer?.cancel();
    orbitController.stop();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    timer?.cancel();
    orbitController.reset();
    setState(() {
      isRunning = false;
      remainingSeconds = totalSeconds;
    });
  }

  void togglePomodoro(bool value) {
    setState(() {
      isPomodoro = value;
      totalSeconds = isPomodoro ? 1500 : 0;
      remainingSeconds = totalSeconds;
      orbitController.reset();
      timer?.cancel();
      isRunning = false;
    });
  }

  void setCustomTime() {
    final entered = int.tryParse(customController.text);
    if (entered == null || entered <= 0) return;
    setState(() {
      totalSeconds = entered * 60;
      remainingSeconds = totalSeconds;
      orbitController.duration = Duration(seconds: totalSeconds);
      orbitController.reset();
      isRunning = false;
      timer?.cancel();
    });
  }

  String get seedImage {
    double percent = remainingSeconds / totalSeconds;
    if (percent > 0.8) return 'assets/images/seed1.png';
    if (percent > 0.6) return 'assets/images/seed2.png';
    if (percent > 0.4) return 'assets/images/seed3.png';
    if (percent > 0.2) return 'assets/images/seed4.png';
    return 'assets/images/seed5.png';
  }

  String formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        SwitchListTile(
          value: isPomodoro,
          onChanged: togglePomodoro,
          title: const Text("Pomodoro Mode"),
          activeColor: Colors.green[800],
        ),
        if (!isPomodoro)
          Row(children: [
            Expanded(
              child: TextField(
                controller: customController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter minutes...',
                  filled: true,
                  fillColor: Colors.green[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                setCustomTime();
                FocusScope.of(context).unfocus(); // ✅ This dismisses the keyboard
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              child: const Text("Set"),
            )

          ]),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: orbitController,
                    builder: (context, child) => CustomPaint(
                      size: const Size(260, 260),
                      painter: OrbitPainter(orbitController.value),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween<double>(begin: 0, end: 1).animate(orbitController),
                    child: Transform.translate(
                      offset: const Offset(0, -115),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Image.asset(seedImage, height: 180),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(formatTime(remainingSeconds),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: startTimer, style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]), child: const Text("Start")),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: stopTimer, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600]), child: const Text("Pause")),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: resetTimer, style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]), child: const Text("Reset")),
          ],
        )
      ]),
    );
  }
}

class OrbitPainter extends CustomPainter {
  final double progress;

  OrbitPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..color = Colors.green.shade100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final Paint progressPaint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * 3.1415926535897932 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535897932 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class TasksScreen extends StatelessWidget {
  final List<Task> tasks;
  final void Function(String) onAdd;
  final void Function(int, String) onUpdatePriority;
  final void Function(int, bool?) onToggleDone;
  final void Function(int) onDelete;

  const TasksScreen({super.key, required this.tasks, required this.onAdd, required this.onUpdatePriority, required this.onToggleDone, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final TextEditingController addController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: addController,
                decoration: InputDecoration(
                  hintText: 'Add new task...',
                  fillColor: Colors.green[50],
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                onAdd(addController.text);
                addController.clear();
                FocusScope.of(context).unfocus();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              child: const Icon(Icons.add),
            ),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No tasks yet. Add one!', style: TextStyle(color: Colors.green)))
                : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: task.isDone ? Colors.green[100] : Colors.greenAccent.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.isDone,
                      onChanged: (val) => onToggleDone(index, val),
                      activeColor: Colors.green[800],
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                          color: Colors.green[900],
                          fontWeight: FontWeight.w600),
                    ),
                    trailing: DropdownButton<String>(
                      value: task.priority,
                      dropdownColor: Colors.green[50],
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'Low', child: Text('Low', style: TextStyle(color: Colors.green))),
                        DropdownMenuItem(value: 'Medium', child: Text('Medium', style: TextStyle(color: Colors.orange))),
                        DropdownMenuItem(value: 'High', child: Text('High', style: TextStyle(color: Colors.red))),
                      ],
                      onChanged: (val) => val != null ? onUpdatePriority(index, val) : null,
                    ),
                    onLongPress: () => onDelete(index),
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
