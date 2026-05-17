import 'package:flutter/material.dart';
import 'topic_list_screen.dart';

class CourseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> courseData;

  const CourseDetailsScreen({
    super.key,
    required this.courseData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF81D4FA),
                  Color(0xFFB2F2BB),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Course Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseData['title'] ?? "Course Title",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Course Code: ${courseData['code'] ?? 'N/A'}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [

                        Row(
                          children: [

                            Expanded(
                              child: _buildCard(
                                context,
                                "Lecture Topics",
                                Icons.play_circle_outline,
                                const [Color(0xFF8E1CD6), Color(0xFF4728A5)],
                                "Lecture",
                              ),
                            ),

                            const SizedBox(width: 20),

                            Expanded(
                              child: _buildCard(
                                context,
                                "Assignment Topics",
                                Icons.assignment_outlined,
                                const [Color(0xFFFFB74D), Color(0xFFF06292)],
                                "Assignment",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 🔥 SAME SIZE FIX (NOT FULL WIDTH CHANGE)
                        Row(
                          children: [
                            Expanded(
                              child: _buildCard(
                                context,
                                "Quiz Topics",
                                Icons.quiz,
                                const [Color(0xFF00E5FF), Color(0xFF1DE9B6)],
                                "Quiz",
                              ),
                            ),
                          ],
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

  Widget _buildCard(
      BuildContext context,
      String title,
      IconData icon,
      List<Color> colors,
      String category,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicListScreen(
              categoryTitle: category,
              themeColors: colors,
              classId: courseData['id'],
            ),
          ),
        );
      },
      child: Container(
        height: 140, // ✅ SAME SIZE FIXED FOR ALL 3
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}