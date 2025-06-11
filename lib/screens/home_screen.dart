import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../providers/theme_provider.dart'; // Import ThemeProvider Anda

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final uuid = const Uuid();
  final user = FirebaseAuth.instance.currentUser!;

  CollectionReference get todosRef => FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('todos');

  Map<DateTime, List<Todo>> _groupedTodos = {};

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  void _loadTodos() {
    todosRef.snapshots().listen((snapshot) {
      Map<DateTime, List<Todo>> grouped = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final todo = Todo(
          id: doc.id,
          title: data['title'],
          description: data['description'],
          date: DateTime.parse(data['date']),
          isCompleted: data['isCompleted'] ?? false,
        );
        final date = DateTime(todo.date.year, todo.date.month, todo.date.day);
        if (grouped[date] == null) {
          grouped[date] = [todo];
        } else {
          grouped[date]!.add(todo);
        }
      }
      setState(() => _groupedTodos = grouped);
    });
  }

  // Fungsi untuk mengubah status selesai/belum selesai
  void _toggleTodoStatus(Todo todo) async {
    await todosRef.doc(todo.id).update({'isCompleted': !todo.isCompleted});
  }

  List<Todo> _getAllTodos() {
    return _groupedTodos.values.expand((e) => e).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Todo> _getTodosForDay(DateTime day) {
    return _groupedTodos[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _addOrEditTodo({Todo? existingTodo}) {
    final titleController = TextEditingController(text: existingTodo?.title);
    final descController = TextEditingController(
      text: existingTodo?.description,
    );

    // Akses tema saat ini dari Theme.of(context)
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          existingTodo == null ? 'Tambah Kegiatan' : 'Edit Kegiatan',
          style: TextStyle(
            color: colorScheme.primary,
          ), // Gunakan primary color dari ColorScheme
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Judul',
                border: const OutlineInputBorder(),
                labelStyle: textTheme.bodyLarge, // Gunakan gaya teks dari tema
              ),
              style: textTheme.bodyMedium, // Gunakan gaya teks dari tema
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Deskripsi',
                border: const OutlineInputBorder(),
                labelStyle: textTheme.bodyLarge, // Gunakan gaya teks dari tema
              ),
              style: textTheme.bodyMedium, // Gunakan gaya teks dari tema
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: colorScheme.primary),
            ), // Gunakan primary color
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ), // Gunakan primary color
            onPressed: () async {
              final title = titleController.text.trim();
              final desc = descController.text.trim();
              if (title.isEmpty || desc.isEmpty) return;

              final todoData = {
                'title': title,
                'description': desc,
                'date': _selectedDate.toIso8601String(),
                'isCompleted': existingTodo?.isCompleted ?? false,
              };

              if (existingTodo == null) {
                await todosRef.add(todoData);
              } else {
                await todosRef.doc(existingTodo.id).update(todoData);
              }

              Navigator.pop(context);
            },
            child: const Text(
              // Teks tombol akan menggunakan warna kontras otomatis dari ElevatedButton
              // berdasarkan primary color tema
              'Simpan',
              style: TextStyle(
                color: Colors.white,
              ), // Tetap putih untuk kontras yang baik
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final allTodos = _getAllTodos();
    // Dapatkan ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Dapatkan data tema saat ini dari Theme.of(context)
    final currentTheme = Theme.of(context);
    final colorScheme = currentTheme.colorScheme;
    final textTheme = currentTheme.textTheme;

    return Scaffold(
      backgroundColor: currentTheme
          .scaffoldBackgroundColor, // Gunakan warna latar belakang scaffold dari tema
      appBar: AppBar(
        backgroundColor: colorScheme.primary, // Gunakan primary color dari tema
        title: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Lottie.asset(
                'assets/animations/splash.json',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'TaskFlow',
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ), // Sesuaikan warna teks judul App Bar
            ),
          ],
        ),
        actions: [
          // Tombol Pengalih Tema
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () {
              // Panggil toggleTheme dengan nilai bool
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDate,
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
            onDaySelected: (selected, focused) =>
                setState(() => _selectedDate = selected),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(
                  0.4,
                ), // Gunakan primary color
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary, // Gunakan primary color
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              // Sesuaikan gaya teks untuk kalender agar sesuai dengan tema
              defaultTextStyle: textTheme.bodyMedium!,
              weekendTextStyle: textTheme.bodyMedium!,
              selectedTextStyle: const TextStyle(color: Colors.white),
              todayTextStyle: const TextStyle(color: Colors.white),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: textTheme.titleMedium!.copyWith(
                color: textTheme.bodyMedium?.color,
              ), // Sesuaikan warna judul header
            ),
            daysOfWeekHeight: 20,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle:
                  textTheme.bodySmall!, // Sesuaikan warna teks hari kerja
              weekendStyle:
                  textTheme.bodySmall!, // Sesuaikan warna teks akhir pekan
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final todos = _getTodosForDay(day);
                if (todos.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: allTodos.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada kegiatan.',
                      style: textTheme.bodyMedium,
                    ),
                  ) // Terapkan gaya teks
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: allTodos.length,
                    itemBuilder: (ctx, i) {
                      final todo = allTodos[i];

                      return Card(
                        color: currentTheme
                            .cardColor, // Terapkan warna latar belakang kartu dari tema
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: todo.isCompleted,
                                onChanged: (value) {
                                  _toggleTodoStatus(todo);
                                },
                                activeColor: colorScheme
                                    .primary, // Gunakan primary color
                                checkColor: Colors.white, // Warna tanda centang
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      todo.title,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: todo.isCompleted
                                            ? Colors.grey
                                            : textTheme
                                                  .titleMedium
                                                  ?.color, // Sesuaikan warna
                                        decoration: todo.isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      todo.description,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: todo.isCompleted
                                            ? Colors.grey
                                            : textTheme.bodyMedium?.color
                                                  ?.withOpacity(
                                                    0.7,
                                                  ), // Sesuaikan warna
                                        decoration: todo.isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: colorScheme
                                              .primary, // Gunakan primary color
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Deadline: ${_formatDate(todo.date)}",
                                          style: textTheme.bodySmall?.copyWith(
                                            color: textTheme.bodySmall?.color
                                                ?.withOpacity(
                                                  0.8,
                                                ), // Sesuaikan warna
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () =>
                                    _addOrEditTodo(existingTodo: todo),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => todosRef.doc(todo.id).delete(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary, // Gunakan primary color
        onPressed: () => _addOrEditTodo(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ), // Pastikan ikon terlihat
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
