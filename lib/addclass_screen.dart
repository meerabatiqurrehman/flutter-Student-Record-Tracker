import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {

  // Firebase Database Reference
  final DatabaseReference databaseRef =
  FirebaseDatabase.instance.ref("Classes");

  // Dropdown values
  String? selectedDegree;
  String? selectedSemester;
  String? selectedSection;
  String? selectedCreditHours;

  // Text controllers
  final TextEditingController courseCodeController =
  TextEditingController();

  final TextEditingController courseTitleController =
  TextEditingController();

  final TextEditingController departmentController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Class"),
        backgroundColor: Colors.teal,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // Degree Dropdown
            _buildDropdown(
              "Degree",
              selectedDegree,
              ["BS", "ADP", "M.Phil", "Ph.D"],
                  (value) => setState(() => selectedDegree = value),
            ),

            const SizedBox(height: 12),

            // Department
            _buildTextField(
              departmentController,
              "Department",
            ),

            const SizedBox(height: 12),

            // Semester Dropdown
            _buildDropdown(
              "Semester",
              selectedSemester,
              ["S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8"],
                  (value) => setState(() => selectedSemester = value),
            ),

            const SizedBox(height: 12),

            // Section Dropdown
            _buildDropdown(
              "Section",
              selectedSection,
              ["A", "B", "C"],
                  (value) => setState(() => selectedSection = value),
            ),

            const SizedBox(height: 12),

            // Course Code
            _buildTextField(
              courseCodeController,
              "Course Code",
            ),

            const SizedBox(height: 12),

            // Course Title
            _buildTextField(
              courseTitleController,
              "Course Title",
            ),

            const SizedBox(height: 12),

            // Credit Hours Dropdown
            _buildDropdown(
              "Credit Hours",
              selectedCreditHours,
              ["1", "2", "3", "4", "5"],
                  (value) => setState(() => selectedCreditHours = value),
            ),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                onPressed: _saveClass,

                child: const Text(
                  "SAVE CLASS",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SAVE CLASS FUNCTION
  void _saveClass() async {

    if (selectedDegree == null) {
      _showError("Please select Degree");
      return;
    }

    if (departmentController.text.trim().isEmpty) {
      _showError("Please enter Department");
      return;
    }

    if (selectedSemester == null) {
      _showError("Please select Semester");
      return;
    }

    if (selectedSection == null) {
      _showError("Please select Section");
      return;
    }

    if (courseCodeController.text.trim().isEmpty) {
      _showError("Please enter Course Code");
      return;
    }

    if (courseTitleController.text.trim().isEmpty) {
      _showError("Please enter Course Title");
      return;
    }

    if (selectedCreditHours == null) {
      _showError("Please select Credit Hours");
      return;
    }

    try {

      // Generate Unique ID
      String classId = databaseRef.push().key ?? "";

      // Class Data
      Map<String, dynamic> classData = {

        "id": classId,

        "degree": selectedDegree,

        "department":
        departmentController.text.trim(),

        "semester": selectedSemester,

        "section": selectedSection,

        "code":
        courseCodeController.text.trim(),

        "title":
        courseTitleController.text.trim(),

        "credit": selectedCreditHours,
      };

      // Save to Firebase
      await databaseRef
          .child(classId)
          .set(classData);

      // Return data to previous screen
      Navigator.pop(context, classData);

    } catch (e) {

      _showError(
        "Failed to save class",
      );
    }
  }

  // ERROR MESSAGE
  void _showError(String message) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(
        content: Text(message),

        backgroundColor: Colors.red,

        duration: const Duration(seconds: 2),
      ),
    );
  }

  // DROPDOWN WIDGET
  Widget _buildDropdown(
      String label,
      String? value,
      List<String> items,
      Function(String?) onChanged,
      ) {

    return DropdownButtonFormField<String>(

      value: value,

      decoration: InputDecoration(
        labelText: label,

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),
      ),

      items: items
          .map(
            (e) => DropdownMenuItem(
          value: e,
          child: Text(e),
        ),
      )
          .toList(),

      onChanged: onChanged,
    );
  }

  // TEXTFIELD WIDGET
  Widget _buildTextField(
      TextEditingController controller,
      String label, {

        TextInputType keyboardType =
            TextInputType.text,
      }) {

    return TextField(

      controller: controller,

      keyboardType: keyboardType,

      decoration: InputDecoration(

        labelText: label,

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {

    courseCodeController.dispose();

    courseTitleController.dispose();

    departmentController.dispose();

    super.dispose();
  }
}