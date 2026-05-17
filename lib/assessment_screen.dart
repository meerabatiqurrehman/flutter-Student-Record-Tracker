import 'package:flutter/material.dart';

class AssessmentScreen extends StatefulWidget {
  final String className;
  final String department;
  final String semester;
  final String section;
  final List<Map<String, String>> students;

  const AssessmentScreen({
    super.key,
    required this.className,
    required this.department,
    required this.semester,
    required this.section,
    required this.students,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  List<String> assessmentTypes = ["Assignments", "Quizzes", "Presentation", "Midterm", "Final Exam"];

  String selectedAssessment = "Assignments";

  // Store: Assessment -> Student Roll -> {marks: int, submitted: bool}
  Map<String, Map<String, Map<String, dynamic>>> assessmentData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f4f8),
      body: Column(
        children: [
          // Gradient Top Bar
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
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Assessment",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Assessment Type Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xff4AC7FA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Assessment",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: assessmentTypes.length,
                    itemBuilder: (context, index) {
                      String type = assessmentTypes[index];
                      bool isSelected = type == selectedAssessment;
                      return GestureDetector(
                        onTap: () => setState(() => selectedAssessment = type),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(colors: [Color(0xff26A69A), Color(0xff2DE1FC)])
                                : null,
                            color: isSelected ? null : Colors.white24,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Add New Assessment Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _showAddAssessmentDropdown,
              icon: const Icon(Icons.add),
              label: const Text("Add New Assessment Type"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff26A69A),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Students List
          Expanded(
            child: widget.students.isEmpty
                ? const Center(child: Text("No students found. Add students first."))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                String roll = student['roll'] ?? '';
                String name = student['name'] ?? '';

                var data = assessmentData[selectedAssessment]?[roll];
                int marks = data?['marks'] ?? 0;
                bool submitted = data?['submitted'] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text("${index + 1}"),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Roll No: $roll"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _toggleSubmission(roll),
                          child: Chip(
                            label: Text(submitted ? "Submitted" : "Pending"),
                            backgroundColor: submitted ? Colors.green[100] : Colors.orange[100],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: "Marks",
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(text: marks == 0 ? "" : marks.toString()),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                _updateMarks(roll, int.tryParse(value) ?? 0);
                              }
                            },
                          ),
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
    );
  }

  void _showAddAssessmentDropdown() {
    String? newType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Assessment Type"),
        content: DropdownButtonFormField<String>(
          hint: const Text("Select Type"),
          items: const [
            DropdownMenuItem(value: "Assignment", child: Text("Assignment")),
            DropdownMenuItem(value: "Quiz", child: Text("Quiz")),
            DropdownMenuItem(value: "Project", child: Text("Project")),
            DropdownMenuItem(value: "Practical", child: Text("Practical")),
            DropdownMenuItem(value: "Lab Manual", child: Text("Lab Manual")),
          ],
          onChanged: (value) => newType = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (newType != null) {
                String finalName = newType!;
                int count = assessmentTypes.where((e) => e.startsWith(finalName)).length;
                if (count > 0) {
                  finalName = "$finalName ${count + 1}";
                }
                setState(() {
                  assessmentTypes.add(finalName);
                  selectedAssessment = finalName;
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _toggleSubmission(String roll) {
    setState(() {
      assessmentData.putIfAbsent(selectedAssessment, () => {});
      assessmentData[selectedAssessment]!.putIfAbsent(roll, () => {"marks": 0, "submitted": false});
      assessmentData[selectedAssessment]![roll]!['submitted'] =
      !(assessmentData[selectedAssessment]![roll]!['submitted'] ?? false);
    });
  }

  void _updateMarks(String roll, int marks) {
    setState(() {
      assessmentData.putIfAbsent(selectedAssessment, () => {});
      assessmentData[selectedAssessment]!.putIfAbsent(roll, () => {"marks": 0, "submitted": false});
      assessmentData[selectedAssessment]![roll]!['marks'] = marks;
    });
  }
}