import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Main widget for user registration
class EnterRegisterDetails extends StatefulWidget {
  const EnterRegisterDetails({super.key});

  @override
  State<EnterRegisterDetails> createState() => _EnterRegisterDetailsState();
}

class _EnterRegisterDetailsState extends State<EnterRegisterDetails> {
  // GlobalKey is used to validate the form
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers for text fields to capture user inputs
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State variable to track whether the app is loading
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add some space around the content
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            // Title of the screen
            const Text(
              'Register',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24.0), // Space between title and form

            // Form widget to handle input fields and validation
            Form(
              key: formKey,
              child: Column(
                children: [
                  // Input field for the user's name
                  _buildTextField(
                    controller: nameController,
                    label: 'Name',
                  ),
                  const SizedBox(height: 16.0),

                  // Input field for the user's email
                  _buildTextField(
                    controller: emailController,
                    label: 'Email',
                    isEmail: true,
                  ),
                  const SizedBox(height: 16.0),

                  // Input field for the user's password
                  _buildTextField(
                    controller: passwordController,
                    label: 'Password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 24.0),

                  // Display a loading spinner when isLoading is true
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 60,
                        // Register button
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              // Start loading indicator
                              setState(() {
                                isLoading = true;
                              });

                              // Attempt to register the user
                              await _registerUser(
                                context,
                                nameController.text.trim(),
                                emailController.text.trim(),
                                passwordController.text.trim(),
                              );

                              // Stop loading indicator
                              setState(() {
                                isLoading = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent,
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build text fields with optional email and password validation
  Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  bool isEmail = false,
  bool isPassword = false,
}) {
  return TextFormField(
    controller: controller, // Bind the controller to the input field
    decoration: InputDecoration(
      labelText: label, // Display the label for the input field
      labelStyle: const TextStyle(fontSize: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0), // Rounded corners for input field
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.blue, width: 2.0), // Highlight on focus
      ),
    ),
    obscureText: isPassword, // Hide text for password fields
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter your $label'; // Validate required input
      }
      if (isEmail) {
        const pattern =
            r'^[a-zA-Z0-9._%+-]+@live\.iium\.edu\.my$'; // Email regex for the specific domain
        final regExp = RegExp(pattern);
        if (!regExp.hasMatch(value)) {
          return 'Please enter a valid live.iium.edu.my email'; // Custom error for invalid email
        }
      }
      return null;
    },
  );
}


  // Function to handle user registration
  Future<void> _registerUser(
    BuildContext context,
    String name,
    String email,
    String password,
  ) async {
    try {
      // Firebase Authentication: Create a new user with email and password
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user details to Firestore with UID as document ID
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'uid': userCredential.user!.uid,
      });

      // Show a success message on registration
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );

      // Navigate to the home page and clear navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = 'An error occurred. Please try again.';
      }

      // Show error message as a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      // Catch-all for any other errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }
}
