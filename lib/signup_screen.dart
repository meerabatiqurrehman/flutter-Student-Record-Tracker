import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  bool _isLoading = false;

  Future<void> _signupUser(BuildContext context) async {
    String name = nameController.text.trim();
    String email = emailController.text.trim().toLowerCase();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage(context, "Please fill all fields", Colors.red);
      return;
    }

    if (password != confirmPassword) {
      _showMessage(context, "Passwords do not match", Colors.red);
      return;
    }

    if (password.length < 6) {
      _showMessage(context, "Password must be at least 6 characters", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String sanitizedEmail = email.replaceAll('.', ',');

      print("🔄 Checking email...");

      final snapshot = await _dbRef.child('users/$sanitizedEmail').get()
          .timeout(const Duration(seconds: 40));

      if (snapshot.exists) {
        _showMessage(context, "This email is already registered.", Colors.orange);
        return;
      }

      print("🔄 Saving user...");

      await _dbRef.child('users/$sanitizedEmail').set({
        'name': name,
        'email': email,
        'password': password,
        'createdAt': ServerValue.timestamp,
      }).timeout(const Duration(seconds: 30));

      print("✅ Signup Successful!");

      _showMessage(context, "Account created successfully! Please login.", Colors.green);

      nameController.clear();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      print("❌ Error: $e");
      _showMessage(context, "Signup failed. Check internet & try again.", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffdff3ff), Color(0xff8ecdf5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  const Icon(Icons.person_add, size: 90, color: Color(0xff0d3b66)),
                  const SizedBox(height: 10),
                  const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xff0d3b66)),
                  ),
                  const SizedBox(height: 40),

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: "Full Name",
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Email",
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Confirm Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _signupUser(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0d3b66),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(color: Color(0xff0d3b66), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}