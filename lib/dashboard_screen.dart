import 'package:flutter/material.dart';
import 'coursedetails_screen.dart';
import 'studentlist_screen.dart';
import 'attendance_screen.dart';
import 'timetable_screen.dart';
import 'assessment_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> classData;
  final String? className;

  const DashboardScreen({
    super.key,
    required this.classData,
    this.className,
  });

  @override
  Widget build(BuildContext context) {
    String displayTitle = className ??
        "${classData['degree'] ?? ''} ${classData['semester'] ?? ''}";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ORIGINAL TOP GRADIENT (UNCHANGED)
          Container(
            height: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4AC7FA), Color(0xFF5082E5)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Class Detail Dashboard",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${classData['department'] ?? ''} - Section ${classData['section'] ?? ''}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        _buildMenuCard(
                          "Course Details",
                          Icons.list_alt,
                          const [Color(0xFF9D62FD), Color(0xFF2433E4)],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CourseDetailsScreen(courseData: classData),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          "Student List",
                          Icons.people,
                          const [Color(0xFF5CF4AA), Color(0xFF3ABFA4)],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentListScreen(
                                  className: classData['degree'] ?? '',
                                  department: classData['department'] ?? '',
                                  semester: classData['semester'] ?? '',
                                  section: classData['section'] ?? '',
                                ),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          "Attendance",
                          Icons.calendar_month,
                          const [Color(0xFFFFB359), Color(0xFFFF3B29)],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AttendanceScreen(
                                  className: classData['degree'] ?? '',
                                  department: classData['department'] ?? '',
                                  semester: classData['semester'] ?? '',
                                  section: classData['section'] ?? '',
                                  students: const [],
                                ),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          "Timetable",
                          Icons.event_note,
                          const [Color(0xFF2DE1FC), Color(0xFF5082E5)],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TimetableScreen(
                                  className: classData['degree'] ?? '',
                                  department: classData['department'] ?? '',
                                  semester: classData['semester'] ?? '',
                                  section: classData['section'] ?? '',
                                ),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          "Assessment",
                          Icons.edit_note,
                          const [Color(0xFFEB8EFF), Color(0xFFBA2FFF)],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AssessmentScreen(
                                  className: classData['degree'] ?? '',
                                  department: classData['department'] ?? '',
                                  semester: classData['semester'] ?? '',
                                  section: classData['section'] ?? '',
                                  students: const [],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
      String title,
      IconData icon,
      List<Color> colors, {
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}