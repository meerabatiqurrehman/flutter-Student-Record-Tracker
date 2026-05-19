import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class StudentListScreen extends StatefulWidget {
  final String className;
  final String department;
  final String semester;
  final String section;
  final String? classKey;

  const StudentListScreen({
    super.key,
    required this.className,
    required this.department,
    required this.semester,
    required this.section,
    this.classKey,
  });

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];

  final TextEditingController rollController = TextEditingController();
  final TextEditingController regController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController fatherController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String? editingKey;

  @override
  void initState() {
    super.initState();
    filteredStudents = students;
    searchController.addListener(_filterStudents);
    _loadStudents();
  }

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
          filteredStudents = students;
        });
      } else {
        setState(() {
          students = [];
          filteredStudents = [];
        });
      }
    } catch (e) {
      print("Error loading students: $e");
    }
  }

  void _filterStudents() {
    String query = searchController.text.toLowerCase().trim();
    setState(() {
      filteredStudents = students.where((student) {
        return student["name"]!.toLowerCase().contains(query) ||
            student["roll"]!.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showAddStudentForm({String? key}) {
    editingKey = key;

    if (key != null) {
      final student = students.firstWhere((s) => s['key'] == key);
      rollController.text = student["roll"] ?? '';
      regController.text = student["reg"] ?? '';
      nameController.text = student["name"] ?? '';
      fatherController.text = student["father"] ?? '';
      cnicController.text = student["cnic"] ?? '';
    } else {
      rollController.clear();
      regController.clear();
      nameController.clear();
      fatherController.clear();
      cnicController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  editingKey == null ? "Add New Student" : "Edit Student",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _buildFormField("Roll No.", rollController),
                _buildFormField("Registration No.", regController),
                _buildFormField("Student Name", nameController),
                _buildFormField("Father's Name", fatherController),
                _buildFormField("CNIC No.", cnicController),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0d3b66),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitStudent,
                    child: Text(
                      editingKey == null ? "Submit Record" : "Update Record",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _submitStudent() async {
    if (nameController.text.trim().isEmpty ||
        rollController.text.trim().isEmpty ||
        regController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill Roll No, Reg No & Name")),
      );
      return;
    }

    final studentData = {
      "roll": rollController.text.trim(),
      "reg": regController.text.trim(),
      "name": nameController.text.trim(),
      "father": fatherController.text.trim(),
      "cnic": cnicController.text.trim(),
      "addedAt": ServerValue.timestamp,
    };

    try {
      if (editingKey != null) {
        await _dbRef.child('classes/$_classKey/students/$editingKey').update(studentData);
      } else {
        await _dbRef.child('classes/$_classKey/students').push().set(studentData);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editingKey == null
              ? "Student added successfully!"
              : "Student updated successfully!"),
        ),
      );

      _loadStudents();
      editingKey = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _deleteStudent(String key) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Student"),
        content: const Text("Are you sure you want to delete this student?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dbRef.child('classes/$_classKey/students/$key').remove();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Student deleted successfully")),
                );
                _loadStudents();
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
    String classInfo = "${widget.semester} - Section ${widget.section}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0d3b66),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Student List",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
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
            // Resized Header Card Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              margin: const EdgeInsets.only(left: 50, right: 50, top: 12, bottom: 8),
              decoration: const BoxDecoration(
                color: Color(0xff4AC7FA),
                borderRadius: BorderRadius.all(Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Registered Students",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classInfo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Search Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search Student by Name or Roll No.",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Optimized Add New Student Button Card Layout Width/Padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 8),
              child: GestureDetector(
                onTap: () => _showAddStudentForm(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xff4AC7FA),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add, size: 42, color: Colors.white),
                      const SizedBox(height: 6),
                      const Text(
                        "Add New Student",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tap to add new record",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // List View section
            Expanded(
              child: filteredStudents.isEmpty
                  ? const Center(
                child: Text(
                  "No students added yet",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final colors = [
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                  ];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Student avatar
                          CircleAvatar(
                            backgroundColor: colors[index % colors.length],
                            radius: 22,
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // 2. Student Details Box Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student["name"] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${student["roll"] ?? ''} | ${student["reg"] ?? ''}",
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Father: ${student["father"] ?? '-'}",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "CNIC: ${student["cnic"] ?? '-'}",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. Edit & Delete Compact Action Layout Column
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showAddStudentForm(key: student['key']),
                              ),
                              const SizedBox(height: 4),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteStudent(student['key']),
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

  @override
  void dispose() {
    searchController.dispose();
    rollController.dispose();
    regController.dispose();
    nameController.dispose();
    fatherController.dispose();
    cnicController.dispose();
    super.dispose();
  }
}