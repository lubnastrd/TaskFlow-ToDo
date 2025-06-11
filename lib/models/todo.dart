class Todo {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final bool isCompleted; // <-- TAMBAHKAN INI

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.isCompleted = false, // <-- TAMBAHKAN DEFAULT VALUE
  });
}
