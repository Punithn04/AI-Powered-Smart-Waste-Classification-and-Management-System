import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  void signup() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    if (password != confirmPassword) {
      showMessage("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'email': user.email,
          'name': "$firstName $lastName",
          'firstName': firstName,
          'lastName': lastName,
          'role': 'user',
          'points': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    } catch (e) {
      showMessage("Signup failed");
    }

    setState(() => isLoading = false);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                SizedBox(height: 30),

                Text("Create Account",
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),

                SizedBox(height: 6),

                Text("Join and start earning rewards",
                    style: TextStyle(color: Colors.grey)),

                SizedBox(height: 30),

                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    hintText: "First Name",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),

                SizedBox(height: 12),

                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    hintText: "Last Name",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                SizedBox(height: 12),

                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                ),

                SizedBox(height: 12),

                TextField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() => showPassword = !showPassword);
                      },
                    ),
                  ),
                ),

                SizedBox(height: 12),

                TextField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirmPassword,
                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() =>
                            showConfirmPassword = !showConfirmPassword);
                      },
                    ),
                  ),
                ),

                SizedBox(height: 20),

                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: signup,
                          child: Text("Create Account"),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}