import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class StudentListScreen extends StatefulWidget {
  final String className;
  final String department;
  final String semester;
  final String section;

  const StudentListScreen({
    super.key,
    required this.className,
    required this.department,
    required this.semester,
    required this.section,
  });

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];

  // Form Controllers
  final TextEditingController rollController = TextEditingController();
  final TextEditingController regController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController fatherController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String? editingKey; // Firebase key for editing

  @override
  void initState() {
    super.initState();
    filteredStudents = students;
    searchController.addListener(_filterStudents);
    _loadStudents();   // Load data from Firebase
  }

  // Generate unique class key
  String get _classKey => "${widget.department}_${widget.semester}_${widget.section}".replaceAll(" ", "_").toLowerCase();

  Future<void> _loadStudents() async {
    try {
      final snapshot = await _dbRef.child('classes/$_classKey/students').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          students = data.entries.map((entry) {
            final student = Map<String, dynamic>.from(entry.value);
            student['key'] = entry.key; // Save firebase key
            return student;
          }).toList();
          filteredStudents = students;
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
                      backgroundColor: const Color(0xff6A1B9A),
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
        // Update existing
        await _dbRef.child('classes/$_classKey/students/$editingKey').update(studentData);
      } else {
        // Add new
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

      _loadStudents(); // Refresh list
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
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff4AC7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Student List",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xff4AC7FA),
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Registered Students",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  classInfo,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _showAddStudentForm(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff26C6DA), Color(0xff4AC7FA)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.person_add, size: 40, color: Colors.white),
                    const SizedBox(height: 8),
                    const Text(
                      "Add New Student",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tap to add new record",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: filteredStudents.isEmpty
                ? const Center(
              child: Text(
                "No students added yet",
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colors[index % colors.length],
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      student["name"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${student["roll"]} | ${student["reg"]}\n"
                          "Father: ${student["father"] ?? '-'}\n"
                          "CNIC: ${student["cnic"] ?? '-'}",
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddStudentForm(key: student['key']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteStudent(student['key']),
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