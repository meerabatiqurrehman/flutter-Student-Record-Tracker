import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'topic_model.dart';

class TopicListScreen extends StatefulWidget {
  final String categoryTitle;
  final List<Color> themeColors;
  final String classId;           // Old parameter (for backward compatibility)
  final String? classKey;         // ← New (Strong Unique Key)

  const TopicListScreen({
    super.key,
    required this.categoryTitle,
    required this.themeColors,
    required this.classId,
    this.classKey,
  });

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  late DatabaseReference ref;

  final List<TopicEntry> _items = [];

  @override
  void initState() {
    super.initState();
    _setupFirebaseRef();
    _loadData();
  }

  // ==================== STRONG CLASS KEY SUPPORT ====================
  void _setupFirebaseRef() {
    String finalKey = widget.classKey?.isNotEmpty == true
        ? widget.classKey!
        : widget.classId;

    ref = FirebaseDatabase.instance
        .ref("Classes")
        .child(finalKey)
        .child(widget.categoryTitle);
  }

  @override
  void didUpdateWidget(covariant TopicListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.classId != widget.classId ||
        oldWidget.classKey != widget.classKey) {
      _setupFirebaseRef();
      _items.clear();
      _loadData();
    }
  }

  void _loadData() {
    ref.onValue.listen((event) {
      final data = event.snapshot.value;

      _items.clear();

      if (data != null) {
        Map map = data as Map;

        map.forEach((key, value) {
          _items.add(
            TopicEntry(
              title: value['title'],
              date: DateTime.parse(value['date']),
            ),
          );
        });
      }

      if (mounted) setState(() {});
    });
  }

  void _showAddDialog() {
    final TextEditingController titleController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add ${widget.categoryTitle} Topic"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Topic Name",
                    ),
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Select Date"),
                    subtitle: Text(
                      selectedDate == null
                          ? "No date selected"
                          : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || selectedDate == null) return;

                    String id = ref.push().key!;

                    await ref.child(id).set({
                      "title": titleController.text.trim(),
                      "date": selectedDate!.toIso8601String(),
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteTopic(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this topic?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final snapshot = await ref.get();
              if (snapshot.exists) {
                Map data = snapshot.value as Map;
                data.forEach((key, value) {
                  if (value['title'] == title) {
                    ref.child(key).remove();
                  }
                });
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Deleted successfully"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("${widget.categoryTitle} Topics"),
        backgroundColor: widget.themeColors[0],
      ),
      body: _items.isEmpty
          ? const Center(child: Text("No Topics Yet"))
          : ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(item.title),
            subtitle: Text(item.formattedDate),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTopic(item.title),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.themeColors[0],
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}