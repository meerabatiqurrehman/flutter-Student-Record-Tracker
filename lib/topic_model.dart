class TopicEntry {
  final String title;
  final DateTime date;

  TopicEntry({required this.title, required this.date});

  String get formattedDate => "${date.day.toString().padLeft(2,'0')}/"
      "${date.month.toString().padLeft(2,'0')}/${date.year}";
}