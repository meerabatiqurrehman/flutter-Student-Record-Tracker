import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AssessmentScreen extends StatefulWidget {
  final String className;
  final String department;
  final String semester;
  final String section;
  final String? classKey;        // ← New

  const AssessmentScreen({
    super.key,
    required this.className,
    required this.department,
    required this.semester,
    required this.section,
    this.classKey,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  // Default assessments (Cannot be deleted)
  final List<String> defaultAssessmentTypes = ["Assignments", "Quizzes", "Presentation", "Midterm", "Final Exam"];

  List<String> assessmentTypes = [];

  String selectedAssessment = "Assignments";

  Map<String, Map<String, Map<String, dynamic>>> assessmentData = {};

  List<Map<String, dynamic>> students = [];

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
    assessmentTypes = List.from(defaultAssessmentTypes);
    _reloadAllData();
  }

  @override
  void didUpdateWidget(covariant AssessmentScreen oldWidget) {
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
    assessmentData.clear();
    students.clear();
    _loadStudents();
    _loadAssessmentTypes();
    _loadAssessments();
  }

  Future<void> _loadAssessmentTypes() async {
    try {
      final snapshot = await _dbRef.child('classes/$_classKey/assessmentTypes').get();
      if (snapshot.exists) {
        final savedTypes = (snapshot.value as List<dynamic>? ?? []).cast<String>();
        setState(() {
          for (var type in savedTypes) {
            if (!assessmentTypes.contains(type)) {
              assessmentTypes.add(type);
            }
          }
        });
      }
    } catch (e) {
      print("Error loading assessment types: $e");
    }
  }

  Future<void> _saveAssessmentTypes() async {
    final userAdded = assessmentTypes.where((type) => !defaultAssessmentTypes.contains(type)).toList();
    await _dbRef.child('classes/$_classKey/assessmentTypes').set(userAdded);
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

  Future<void> _loadAssessments() async {
    try {
      final snapshot = await _dbRef.child('classes/$_classKey/assessments').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
        setState(() {
          assessmentData = {};
          data.forEach((key, value) {
            assessmentData[key.toString()] = {};
            (value as Map<dynamic, dynamic>).forEach((roll, record) {
              assessmentData[key.toString()]![roll] = Map<String, dynamic>.from(record);
            });
          });
        });
      }
    } catch (e) {
      print("Error loading assessments: $e");
    }
  }

  Future<void> _saveAssessment() async {
    try {
      await _dbRef.child('classes/$_classKey/assessments').set(assessmentData);
      await _saveAssessmentTypes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Assessment saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffdff3ff), Color(0xff8ecdf5)],
          ),
        ),
        child: Column(
          children: [
            // Top Bar
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
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  const Text("Assessment", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.save, color: Colors.white), onPressed: _saveAssessment),
                ],
              ),
            ),

            // Assessment Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xff4AC7FA),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Assessment", style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: assessmentTypes.length,
                      itemBuilder: (context, index) {
                        String type = assessmentTypes[index];
                        bool isSelected = type == selectedAssessment;
                        bool isDefault = defaultAssessmentTypes.contains(type);

                        return GestureDetector(
                          onTap: () => setState(() => selectedAssessment = type),
                          onLongPress: isDefault ? null : () => _deleteAssessmentType(type),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: isSelected ? const LinearGradient(colors: [Color(0xff26A69A), Color(0xff2DE1FC)]) : null,
                              color: isSelected ? null : Colors.white24,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              type,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _showAddAssessmentDropdown,
                icon: const Icon(Icons.add),
                label: const Text("Add New Assessment Type"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff26A69A), minimumSize: const Size(double.infinity, 50)),
              ),
            ),

            const SizedBox(height: 16),

            // Students List
            Expanded(
              child: students.isEmpty
                  ? const Center(child: Text("No students found.\nAdd students first.", style: TextStyle(color: Colors.black54)))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  String roll = student['roll'] ?? '';
                  String name = student['name'] ?? '';

                  var data = assessmentData[selectedAssessment]?[roll];
                  int marks = data?['marks'] ?? 0;
                  bool submitted = data?['submitted'] ?? false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(backgroundColor: Colors.teal, radius: 18, child: Text("${index + 1}", style: const TextStyle(color: Colors.white))),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("Roll No: $roll", style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _toggleSubmission(roll),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: submitted ? Colors.green[100] : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    submitted ? "Submitted" : "Pending",
                                    style: TextStyle(color: submitted ? Colors.green[900] : Colors.orange[900], fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: TextField(
                                    enabled: submitted,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: submitted ? "Enter Marks" : "Submit first",
                                      border: const OutlineInputBorder(),
                                      filled: !submitted,
                                      fillColor: !submitted ? Colors.grey[200] : null,
                                    ),
                                    controller: TextEditingController(text: marks == 0 ? "" : marks.toString()),
                                    onChanged: (value) {
                                      if (submitted) _updateMarks(roll, int.tryParse(value) ?? 0);
                                    },
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  // ====================== Functions ======================

  void _toggleSubmission(String roll) {
    setState(() {
      assessmentData.putIfAbsent(selectedAssessment, () => {});
      assessmentData[selectedAssessment]!.putIfAbsent(roll, () => {"marks": 0, "submitted": false});
      assessmentData[selectedAssessment]![roll]!['submitted'] = !(assessmentData[selectedAssessment]![roll]!['submitted'] ?? false);
    });
  }

  void _updateMarks(String roll, int marks) {
    setState(() {
      assessmentData.putIfAbsent(selectedAssessment, () => {});
      assessmentData[selectedAssessment]!.putIfAbsent(roll, () => {"marks": 0, "submitted": false});
      assessmentData[selectedAssessment]![roll]!['marks'] = marks;
    });
  }

  Future<void> _deleteAssessmentType(String type) async {
    if (defaultAssessmentTypes.contains(type)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Default assessments (Midterm, Final, etc.) cannot be deleted")),
      );
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Assessment"),
        content: Text("Delete '$type' and all its marks?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      assessmentData.remove(type);
      assessmentTypes.remove(type);
      if (selectedAssessment == type) {
        selectedAssessment = assessmentTypes.first;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$type' deleted successfully")));
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
            DropdownMenuItem(value: "Presentation", child: Text("Presentation")),
            DropdownMenuItem(value: "Viva", child: Text("Viva")),
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
                if (count > 0) finalName = "$finalName ${count + 1}";

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
}