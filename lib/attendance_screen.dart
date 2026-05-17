import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  final String className;
  final String department;
  final String semester;
  final String section;
  final List<Map<String, String>> students;

  const AttendanceScreen({
    super.key,
    required this.className,
    required this.department,
    required this.semester,
    required this.section,
    required this.students,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  int selectedLectureIndex = 0;
  List<String> lectures = ["Lect 1"]; // Dynamic lectures

  // Attendance Record: LectureIndex -> {RollNo: Status}
  Map<int, Map<String, String>> attendanceRecord = {};

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
      ),
      body: Column(
        children: [
          // Header with Date Picker
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
              ],
            ),
          ),

          // Lecture Tabs + Add Lecture Button
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

          // Student List Header
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

          // Students List
          Expanded(
            child: widget.students.isEmpty
                ? const Center(child: Text("No students found. Add students first from Student List."))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                String roll = student['roll'] ?? '';
                String name = student['name'] ?? '';
                String status = attendanceRecord[selectedLectureIndex]?[roll] ?? 'P';

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

          // Short Attendance Notification (Dynamic)
          _buildShortAttendance(),

          // Total Attendance Summary (Dynamic)
          _buildAttendanceSummary(),
        ],
      ),
    );
  }

  // Date Picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  void _addNewLecture() {
    setState(() {
      lectures.add("Lect ${lectures.length + 1}");
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

  void _markAttendance(String roll, String status) {
    setState(() {
      if (!attendanceRecord.containsKey(selectedLectureIndex)) {
        attendanceRecord[selectedLectureIndex] = {};
      }
      attendanceRecord[selectedLectureIndex]![roll] = status;
    });
  }

  // Dynamic Short Attendance
  Widget _buildShortAttendance() {
    List<Map<String, dynamic>> shortStudents = _getShortAttendanceStudents();

    if (shortStudents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
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
            "Short Attendance Notification (<75%)",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          ...shortStudents.map((s) => Text(
            "${s['roll']} | ${s['name']} | ${s['percentage']}%",
            style: const TextStyle(color: Colors.red),
          )),
        ],
      ),
    );
  }

  // Dynamic Summary
  Widget _buildAttendanceSummary() {
    if (widget.students.isEmpty) return const SizedBox.shrink();

    double average = _calculateClassAverage();
    int totalStudents = widget.students.length;
    int shortCount = _getShortAttendanceStudents().length;

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
          Icon(Icons.speed, size: 55, color: average > 75 ? Colors.teal : Colors.orange),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Class Average: ${average.toStringAsFixed(0)}%",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text("$shortCount Students Short, ${totalStudents - shortCount} On Track"),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateClassAverage() {
    if (widget.students.isEmpty) return 0.0;
    int totalPresent = 0;
    int totalStudents = widget.students.length;

    for (var student in widget.students) {
      String roll = student['roll'] ?? '';
      String status = attendanceRecord[selectedLectureIndex]?[roll] ?? 'P';
      if (status == 'P') totalPresent++;
    }
    return (totalPresent / totalStudents) * 100;
  }

  List<Map<String, dynamic>> _getShortAttendanceStudents() {
    List<Map<String, dynamic>> shortList = [];
    for (var student in widget.students) {
      String roll = student['roll'] ?? '';
      String name = student['name'] ?? '';
      String status = attendanceRecord[selectedLectureIndex]?[roll] ?? 'P';
      double percentage = status == 'P' ? 100.0 : 0.0;

      if (percentage < 75) {
        shortList.add({
          'roll': roll,
          'name': name,
          'percentage': percentage.toStringAsFixed(0),
        });
      }
    }
    return shortList;
  }
}