import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TimetableScreen extends StatefulWidget {
  final String className;
  final String department;
  final String semester;
  final String section;

  const TimetableScreen({
    super.key,
    required this.className,
    required this.department,
    required this.semester,
    required this.section,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<String> timeSlots = [
    "8:00 AM", "9:00 AM", "10:00 AM", "11:00 AM", "12:00 PM",
    "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM", "5:00 PM"
  ];

  final List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

  Map<String, Map<String, Map<String, String>>> schedule = {};

  String? selectedDay;
  String? selectedTime;
  final TextEditingController roomController = TextEditingController();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // ==================== UPDATED CLASS KEY ====================
  String get _classKey {
    final degree = (widget.className ?? "").trim().isNotEmpty
        ? widget.className!
        : "unknown";

    return "${degree}_${widget.department}_${widget.semester}_${widget.section}"
        .replaceAll(" ", "_")
        .replaceAll("-", "_")
        .toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    try {
      final snapshot = await _dbRef.child('classes/$_classKey/timetable').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          schedule.clear();
          data.forEach((dayKey, timeMap) {
            String day = dayKey.toString();
            schedule[day] = {};

            if (timeMap is Map) {
              (timeMap as Map).forEach((timeKey, lectureData) {
                String time = timeKey.toString();
                if (lectureData is Map) {
                  schedule[day]![time] = {
                    "subject": lectureData['subject']?.toString() ?? "${widget.semester} Class",
                    "room": lectureData['room']?.toString() ?? '',
                  };
                }
              });
            }
          });
        });
      }
    } catch (e) {
      print("Error loading timetable: $e");
    }
  }

  void _showAddLectureForm() {
    selectedDay = days[0];
    selectedTime = timeSlots[0];
    roomController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Add Lecture", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: "Day"),
                  items: days.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                  onChanged: (value) => setState(() => selectedDay = value),
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTime,
                  decoration: const InputDecoration(labelText: "Time"),
                  items: timeSlots.map((time) => DropdownMenuItem(value: time, child: Text(time))).toList(),
                  onChanged: (value) => setState(() => selectedTime = value),
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: "Room No.", border: OutlineInputBorder()),
                ),

                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff26A69A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _saveLecture,
                    child: const Text("Save Lecture", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveLecture() async {
    if (selectedDay == null || selectedTime == null) return;

    final lectureData = {
      "subject": "${widget.semester} Class",
      "room": roomController.text.trim(),
      "addedAt": ServerValue.timestamp,
    };

    try {
      await _dbRef.child('classes/$_classKey/timetable/$selectedDay/$selectedTime').set(lectureData);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lecture added successfully!")));
      _loadTimetable();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _clearLecture(String day, String time) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Lecture"),
        content: const Text("Are you sure you want to delete this lecture?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dbRef.child('classes/$_classKey/timetable/$day/$time').remove();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lecture deleted successfully")),
                );

                _loadTimetable();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Delete failed: $e")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff4AC7FA), Color(0xff26A69A)],
              ),
            ),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 8),
                const Text("Weekly Class Schedule", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xff26A69A), Color(0xff2DE1FC)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: _showAddLectureForm,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Add Lecture", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                  defaultColumnWidth: const FixedColumnWidth(130),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xff26A69A)),
                      children: [
                        const Padding(padding: EdgeInsets.all(12), child: Text("Day / Time", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                        ...timeSlots.map((time) => Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                        )),
                      ],
                    ),
                    ...days.map((day) => TableRow(
                      children: [
                        Container(color: const Color(0xfff0f4f8), padding: const EdgeInsets.all(12), child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold))),
                        ...timeSlots.map((time) {
                          final lecture = schedule[day]?[time];
                          final room = lecture?['room'] ?? '';

                          return GestureDetector(
                            onLongPress: lecture != null ? () => _clearLecture(day, time) : null,
                            child: Container(
                              height: 85,
                              padding: const EdgeInsets.all(8),
                              color: lecture != null ? const Color(0xff26A69A).withOpacity(0.15) : null,
                              child: lecture != null
                                  ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(lecture['subject'] ?? "${widget.semester} Class", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                                  if (room.isNotEmpty) Text("Room: $room", style: const TextStyle(fontSize: 11)),
                                ],
                              )
                                  : const Center(child: Text("-", style: TextStyle(fontSize: 24, color: Colors.grey))),
                            ),
                          );
                        }),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: const Text("Click and hold cell to delete the class", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}