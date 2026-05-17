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

  List<Map<String, String>> students = [];
  List<Map<String, String>> filteredStudents = [];

  // Form Controllers
  final TextEditingController rollController = TextEditingController();
  final TextEditingController regController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController fatherController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredStudents = students;
    searchController.addListener(_filterStudents);
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

  void _showAddStudentForm() {
    rollController.clear();
    regController.clear();
    nameController.clear();
    fatherController.clear();
    cnicController.clear();

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
                const Text(
                  "Add New Student",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                    child: const Text(
                      "Submit Record",
                      style: TextStyle(fontSize: 16, color: Colors.white),
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

  void _submitStudent() {
    if (nameController.text.trim().isEmpty ||
        rollController.text.trim().isEmpty ||
        regController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill Roll No, Reg No & Name")),
      );
      return;
    }

    setState(() {
      students.add({
        "roll": rollController.text.trim(),
        "reg": regController.text.trim(),
        "name": nameController.text.trim(),
        "father": fatherController.text.trim(),
        "cnic": cnicController.text.trim(),
      });
      filteredStudents = students;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Student added successfully!")),
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
          // Header
          Container(
            padding: const EdgeInsets.all(25),
            margin: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xff4AC7FA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25)
              ),
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

          // Search Bar
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

          // Add New Student Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _showAddStudentForm,
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

          // Students List
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
                        "${index + 1}",           // ← Serial Number (1, 2, 3...)
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