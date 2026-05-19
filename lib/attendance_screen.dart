import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  final String className;
  final String department;
  final String semester;
  final String section;
  final String? classKey;

  const AttendanceScreen({
    super.key,
    required this.className,
    required this.department,
    required this.semester,
    required this.section,
    this.classKey,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  int selectedLectureIndex = 0;
  List<String> lectures = [];

  Map<int, Map<String, String>> attendanceRecord = {};
  List<Map<String, dynamic>> students = [];

  Map<String, int> totalLecturesPerStudent = {};
  Map<String, int> presentCountPerStudent = {};

  bool isHoliday = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // ==================== STRONG CLASS KEY ====================
  String get _classKey {
    if (widget.classKey != null && widget.classKey!.isNotEmpty) {
      return widget.classKey!;
    }
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
    _reloadAllData();
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.className != widget.className ||
        oldWidget.department != widget.department ||
        oldWidget.semester != widget.semester ||
        oldWidget.section != widget.section ||
        oldWidget.classKey != widget.classKey) {
      _reloadAllData();
    }
  }

  void _reloadAllData() {
    lectures.clear();
    attendanceRecord.clear();
    students.clear();
    totalLecturesPerStudent.clear();
    presentCountPerStudent.clear();
    selectedLectureIndex = 0;
    isHoliday = false;

    _loadStudents();
    _loadAttendanceForDate();
    _loadOverallSemesterData();
  }

  Future<void> _loadStudents() async {
    try {
      final snapshot = await _dbRef.child('classes/$_classKey/students').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
        setState(() {
          students = data.entries.map((entry) {
            final student = Map<String, dynamic>.from(entry.value);
            student['key'] = entry.key;
            return student;
          }).toList();
        });
      } else {
        setState(() => students = []);
      }
    } catch (e) {
      print("Error loading students: $e");
    }
  }

  Future<void> _loadAttendanceForDate() async {
    String dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    try {
      final holidaySnap = await _dbRef.child('classes/$_classKey/holidays/$dateStr').get();
      isHoliday = holidaySnap.exists;

      final snapshot = await _dbRef.child('classes/$_classKey/attendance/$dateStr').get();

      lectures.clear();
      attendanceRecord.clear();

      if (snapshot.exists) {
        final lecturesMap = snapshot.value as Map<dynamic, dynamic>;
        int index = 0;
        for (var entry in lecturesMap.entries) {
          lectures.add(entry.key.toString());
          attendanceRecord[index] = Map<String, String>.from(entry.value as Map);
          index++;
        }
      }

      if (lectures.isEmpty) lectures = ["Lect 1"];

      setState(() {
        selectedLectureIndex = 0;
      });
    } catch (e) {
      print("Error loading attendance: $e");
      lectures = ["Lect 1"];
      setState(() {});
    }
  }

  Future<void> _loadOverallSemesterData() async {
    try {
      final snapshot = await _dbRef.child('classes/$_classKey/attendance').get();
      if (!snapshot.exists) return;

      totalLecturesPerStudent.clear();
      presentCountPerStudent.clear();

      final allDates = snapshot.value as Map<dynamic, dynamic>;

      for (var dateEntry in allDates.entries) {
        final lecturesMap = dateEntry.value as Map<dynamic, dynamic>;
        for (var lectEntry in lecturesMap.entries) {
          final attendanceMap = lectEntry.value as Map<dynamic, dynamic>;
          for (var studentEntry in attendanceMap.entries) {
            String roll = studentEntry.key;
            String status = studentEntry.value.toString();

            totalLecturesPerStudent[roll] = (totalLecturesPerStudent[roll] ?? 0) + 1;
            if (status == 'P') {
              presentCountPerStudent[roll] = (presentCountPerStudent[roll] ?? 0) + 1;
            }
          }
        }
      }
      setState(() {});
    } catch (e) {
      print("Error loading semester data: $e");
    }
  }

  void _markAttendance(String roll, String status) {
    if (isHoliday) return;
    setState(() {
      if (!attendanceRecord.containsKey(selectedLectureIndex)) {
        attendanceRecord[selectedLectureIndex] = {};
      }
      attendanceRecord[selectedLectureIndex]![roll] = status;
    });
  }

  Widget _statusChip(String label, Color color, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleHoliday() async {
    String dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    if (isHoliday) {
      await _dbRef.child('classes/$_classKey/holidays/$dateStr').remove();
    } else {
      await _dbRef.child('classes/$_classKey/holidays/$dateStr').set(true);
    }
    setState(() => isHoliday = !isHoliday);
  }

  Future<void> _deleteLecture(int index) async {
    if (lectures.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("At least one lecture is required")));
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Lecture"),
        content: Text("Delete '${lectures[index]}' and its attendance?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    String dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    try {
      await _dbRef.child('classes/$_classKey/attendance/$dateStr/${lectures[index]}').remove();

      setState(() {
        lectures.removeAt(index);
        attendanceRecord.remove(index);

        Map<int, Map<String, String>> newRecord = {};
        for (int i = 0; i < lectures.length; i++) {
          newRecord[i] = attendanceRecord[i + (i >= index ? 1 : 0)] ?? {};
        }
        attendanceRecord = newRecord;

        if (selectedLectureIndex >= lectures.length) selectedLectureIndex = lectures.length - 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${lectures[index]} deleted")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
    }
  }

  Future<void> _saveAttendance() async {
    if (students.isEmpty || isHoliday) return;

    String dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    try {
      for (int lectIndex = 0; lectIndex < lectures.length; lectIndex++) {
        if (attendanceRecord.containsKey(lectIndex)) {
          String path = 'classes/$_classKey/attendance/$dateStr/${lectures[lectIndex]}';
          await _dbRef.child(path).set(attendanceRecord[lectIndex]);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Attendance saved successfully!")));
      await _loadOverallSemesterData();
      await _loadAttendanceForDate();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      await _loadAttendanceForDate();
    }
  }

  void _addNewLecture() {
    setState(() {
      lectures.add("Lect ${lectures.length + 1}");
      selectedLectureIndex = lectures.length - 1;
    });
  }

  // ==================== BUILD METHOD ====================
  @override
  Widget build(BuildContext context) {
    String classTitle = "${widget.className} - ${widget.semester} ${widget.section}";

    return Scaffold(
      backgroundColor: const Color(0xfff0f4f8),
      appBar: AppBar(
        backgroundColor: const Color(0xff26A69A),
        elevation: 0,
        title: const Text("Class Attendance"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveAttendance,
          ),
          IconButton(
            icon: Icon(isHoliday ? Icons.event_busy : Icons.event_available, color: Colors.white),
            onPressed: _toggleHoliday,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xff26A69A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      classTitle,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Use Save Button to Save Attendance\nUse Holiday Button to Mark/Unmark Holiday\nLong press Lecture Button to Delete it",
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                if (isHoliday)
                  const Text(
                    "This date is marked as Holiday",
                    style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),

          SizedBox(
            height: 70,
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: lectures.length,
                    itemBuilder: (context, index) {
                      bool isSelected = selectedLectureIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => selectedLectureIndex = index),
                        onLongPress: () => _deleteLecture(index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xff00796B) : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xff00796B)),
                          ),
                          child: Text(
                            lectures[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xff00796B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xff00796B), size: 32),
                  onPressed: _addNewLecture,
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text("Roll No", style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Expanded(
            child: isHoliday
                ? const Center(child: Text("This is a Holiday.\nNo attendance required.", style: TextStyle(fontSize: 16)))
                : students.isEmpty
                ? const Center(child: Text("No students found.\nAdd students first."))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                String roll = student['roll'] ?? '';
                String name = student['name'] ?? '';
                String status = attendanceRecord[selectedLectureIndex]?[roll] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Text(roll, style: const TextStyle(fontWeight: FontWeight.bold)),
                    title: Text(name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _statusChip("P", Colors.teal, status == "P", () => _markAttendance(roll, "P")),
                        const SizedBox(width: 6),
                        _statusChip("A", Colors.red, status == "A", () => _markAttendance(roll, "A")),
                        const SizedBox(width: 6),
                        _statusChip("L", Colors.orange, status == "L", () => _markAttendance(roll, "L")),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          _buildShortAttendance(),
          _buildAttendanceSummary(),
        ],
      ),
    );
  }

  Widget _buildShortAttendance() {
    List<Map<String, dynamic>> shortStudents = _getSemesterShortStudents();
    if (shortStudents.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showShortStudentsDetail(shortStudents),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Short Attendance Students (<75% Semester) - Tap for details",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            ...shortStudents.take(3).map((s) => Text(
              "${s['roll']} | ${s['name']} | ${s['percentage']}%",
              style: const TextStyle(color: Colors.red),
            )),
            if (shortStudents.length > 3)
              const Text("... and more", style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  void _showShortStudentsDetail(List<Map<String, dynamic>> shortStudents) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Short Attendance Details"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: shortStudents.length,
            itemBuilder: (context, index) {
              final s = shortStudents[index];
              return ListTile(
                title: Text("${s['roll']} - ${s['name']}"),
                subtitle: Text("Overall Attendance: ${s['percentage']}%"),
                trailing: const Icon(Icons.info_outline),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSemesterShortStudents() {
    List<Map<String, dynamic>> shortList = [];
    for (var student in students) {
      String roll = student['roll'] ?? '';
      String name = student['name'] ?? '';

      int totalLect = totalLecturesPerStudent[roll] ?? 0;
      int present = presentCountPerStudent[roll] ?? 0;

      if (totalLect > 0) {
        double percentage = (present / totalLect) * 100;
        if (percentage < 75) {
          shortList.add({
            'roll': roll,
            'name': name,
            'percentage': percentage.toStringAsFixed(1),
          });
        }
      }
    }
    return shortList;
  }

  Widget _buildAttendanceSummary() {
    if (students.isEmpty) return const SizedBox.shrink();

    double overallAverage = _calculateOverallSemesterAverage();
    int totalStudents = students.length;
    int shortCount = _getSemesterShortStudents().length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(Icons.school, size: 55, color: overallAverage > 75 ? Colors.teal : Colors.orange),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Semester Average: ${overallAverage.toStringAsFixed(1)}%",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text("Based on all lectures & dates"),
              const SizedBox(height: 4),
              Text(
                "$shortCount Students are Short | Total: $totalStudents",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateOverallSemesterAverage() {
    if (students.isEmpty) return 0.0;
    double totalPercentage = 0.0;
    int count = 0;

    for (var student in students) {
      String roll = student['roll'] ?? '';
      int totalLect = totalLecturesPerStudent[roll] ?? 0;
      int present = presentCountPerStudent[roll] ?? 0;

      if (totalLect > 0) {
        double perc = (present / totalLect) * 100;
        totalPercentage += perc;
        count++;
      }
    }
    return count > 0 ? totalPercentage / count : 0.0;
  }
}