import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'class_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  bool _isLoading = false;

  Future<void> _loginUser(BuildContext context) async {
    String email = emailController.text.trim().toLowerCase();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage(context, "Please enter email and password", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String sanitizedEmail = email.replaceAll('.', ',');

      final snapshot = await _dbRef.child('users/$sanitizedEmail').get();

      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;

        if (userData['password'] == password) {
          _showMessage(context, "Login Successful!", Colors.green);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ClassScreen()),
          );
        } else {
          _showMessage(context, "Incorrect password", Colors.red);
        }
      } else {
        _showMessage(context, "No account found with this email", Colors.red);
      }
    } catch (e) {
      _showMessage(context, "Error: ${e.toString()}", Colors.red);
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school, size: 90, color: Color(0xff0d3b66)),
                  const SizedBox(height: 10),
                  const Text("SRT Login",
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0d3b66))),
                  const SizedBox(height: 40),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Email",
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _loginUser(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0d3b66),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login",
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen())),
                        child: const Text("Sign Up",
                            style: TextStyle(
                                color: Color(0xff0d3b66),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}