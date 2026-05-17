import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dashboard_screen.dart';
import 'addclass_screen.dart';

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {

  // Firebase Reference
  final DatabaseReference databaseRef =
  FirebaseDatabase.instance.ref("Classes");

  // Lists
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> filteredClasses = [];

  // Search Controller
  final TextEditingController searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();

    filteredClasses = classes;

    searchController.addListener(_filterClasses);

    // Load Firebase Data
    _loadClasses();
  }

  // LOAD CLASSES FROM FIREBASE
  void _loadClasses() {

    databaseRef.onValue.listen((event) {

      final data = event.snapshot.value;

      classes.clear();

      if (data != null) {

        Map<dynamic, dynamic> loadedData =
        data as Map<dynamic, dynamic>;

        loadedData.forEach((key, value) {

          Map<String, dynamic> classData =
          Map<String, dynamic>.from(value);

          String displayName =
              "${classData['degree']} "
              "${classData['department']} - "
              "${classData['semester']} "
              "${classData['section']} | "
              "${classData['code']} "
              "${classData['title']}";

          classes.add({
            ...classData,
            "displayName": displayName,
          });
        });
      }

      if (mounted) {
        setState(() {
          filteredClasses = classes;
        });
      }
    });
  }

  // SEARCH FILTER
  void _filterClasses() {

    String query =
    searchController.text.trim().toLowerCase();

    setState(() {

      filteredClasses = query.isEmpty
          ? classes
          : classes.where((classItem) {

        return classItem['displayName']
            .toString()
            .toLowerCase()
            .contains(query);

      }).toList();
    });
  }

  // OPEN ADD CLASS SCREEN
  void _openAddClassScreen() {

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) =>
        const AddClassScreen(),
      ),
    );
  }

  // DELETE CLASS
  void _deleteClass(int index) {

    String classId =
    filteredClasses[index]['id'];

    showDialog(
      context: context,

      builder: (context) => AlertDialog(

        title: const Text("Delete Class"),

        content: const Text(
          "Are you sure you want to delete this class?",
        ),

        actions: [

          TextButton(
            onPressed: () =>
                Navigator.pop(context),

            child: const Text("Cancel"),
          ),

          TextButton(

            onPressed: () async {

              try {

                await databaseRef
                    .child(classId)
                    .remove();

                if (mounted) {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(
                      content: Text(
                        "Class deleted successfully",
                      ),

                      backgroundColor: Colors.red,
                    ),
                  );
                }

              } catch (e) {

                if (mounted) {

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(

                    const SnackBar(
                      content: Text(
                        "Failed to delete class",
                      ),
                    ),
                  );
                }
              }
            },

            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
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

        backgroundColor:
        const Color(0xff0d3b66),
      ),

      body: Container(

        decoration: const BoxDecoration(

          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,

            colors: [
              Color(0xffdff3ff),
              Color(0xff8ecdf5),
            ],
          ),
        ),

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [

              // SEARCH BAR
              TextField(

                controller: searchController,

                decoration: InputDecoration(

                  hintText: "Search Classes...",

                  filled: true,

                  fillColor: Colors.white,

                  prefixIcon:
                  const Icon(Icons.search),

                  suffixIcon:
                  searchController.text.isNotEmpty

                      ? IconButton(
                    icon: const Icon(Icons.clear),

                    onPressed: () {

                      searchController.clear();
                    },
                  )

                      : null,

                  border: OutlineInputBorder(

                    borderRadius:
                    BorderRadius.circular(15),

                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ADD CLASS BUTTON
              SizedBox(

                width: double.infinity,
                height: 50,

                child: ElevatedButton(

                  onPressed: _openAddClassScreen,

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                    const Color(0xff0d3b66),

                    shape: RoundedRectangleBorder(

                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                  ),

                  child: const Text(

                    "Add Class",

                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // CLASS LIST
              Expanded(

                child: filteredClasses.isEmpty

                    ? const Center(

                  child: Text(

                    "No Classes Found",

                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                )

                    : ListView.builder(

                  itemCount:
                  filteredClasses.length,

                  itemBuilder: (context, index) {

                    final classItem =
                    filteredClasses[index];

                    return GestureDetector(

                      onTap: () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (context) =>
                                DashboardScreen(

                                  classData: classItem,

                                  className:
                                  classItem['displayName'],
                                ),
                          ),
                        );
                      },

                      child: Card(

                        shape: RoundedRectangleBorder(

                          borderRadius:
                          BorderRadius.circular(15),
                        ),

                        elevation: 5,

                        margin:
                        const EdgeInsets.only(
                          bottom: 12,
                        ),

                        child: ListTile(

                          leading: const Icon(
                            Icons.school,

                            color:
                            Color(0xff0d3b66),
                          ),

                          title: Text(

                            classItem['displayName'] ??
                                "Class",

                            style: const TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          trailing: Row(

                            mainAxisSize:
                            MainAxisSize.min,

                            children: [

                              IconButton(

                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),

                                onPressed: () =>
                                    _deleteClass(index),
                              ),

                              const Icon(
                                Icons.arrow_forward_ios,
                              ),
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