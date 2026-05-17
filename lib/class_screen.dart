import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'addclass_screen.dart';

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> filteredClasses = [];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredClasses = classes;
    searchController.addListener(_filterClasses);
  }

  void _filterClasses() {
    String query = searchController.text.trim().toLowerCase();
    setState(() {
      filteredClasses = query.isEmpty
          ? classes
          : classes
          .where((classItem) =>
          classItem['displayName']
              .toString()
              .toLowerCase()
              .contains(query))
          .toList();
    });
  }

  void _openAddClassScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddClassScreen()), // Fixed: const is okay here
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        String displayName =
            "${result['degree']} ${result['department']} - ${result['semester']} ${result['section']} | ${result['code']} ${result['title']}";

        setState(() {
          classes.add({
            ...result,
            'displayName': displayName,
          });
          filteredClasses = classes;
        });
      }
    });
  }

  // Delete Class with Confirmation
  void _deleteClass(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Class"),
        content: const Text("Are you sure you want to delete this class? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                classes.removeAt(index);
                filteredClasses = classes;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Class deleted successfully"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Classes"),
        backgroundColor: const Color(0xff0d3b66),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffdff3ff), Color(0xff8ecdf5)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search Classes...",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => searchController.clear(),
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Add Class Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _openAddClassScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0d3b66),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Add Class",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Classes List
              Expanded(
                child: filteredClasses.isEmpty
                    ? const Center(
                  child: Text(
                    "No Classes Found",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
                    : ListView.builder(
                  itemCount: filteredClasses.length,
                  itemBuilder: (context, index) {
                    final classItem = filteredClasses[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DashboardScreen(
                              classData: classItem,
                              className: classItem['displayName'],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.school,
                            color: Color(0xff0d3b66),
                          ),
                          title: Text(
                            classItem['displayName'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteClass(index),
                              ),
                              const Icon(Icons.arrow_forward_ios),
                            ],
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
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}