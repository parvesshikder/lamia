import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Widget for user login
class EnterLoginDetails extends StatefulWidget {
  const EnterLoginDetails({super.key});

  @override
  State<EnterLoginDetails> createState() => _EnterLoginDetailsState();
}

class _EnterLoginDetailsState extends State<EnterLoginDetails> {
  // Key for validating the form
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers for capturing email and password inputs
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State variable for showing a loading indicator
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Adds padding around the content
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centers content vertically
          children: [
            // Title of the login screen
            const Text(
              'Log In',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24.0), // Adds space between the title and form

            // Form widget for user input fields
            Form(
              key: formKey,
              child: Column(
                children: [
                  // Email input field
                  _buildTextField(
                    controller: emailController,
                    label: 'Email',
                    isEmail: true,
                  ),
                  const SizedBox(height: 16.0),

                  // Password input field
                  _buildTextField(
                    controller: passwordController,
                    label: 'Password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16.0),

                  // Forgot Password link
                  Align(
                    alignment: Alignment.centerRight, // Aligns the button to the right
                    child: TextButton(
                      onPressed: () {
                        // Trigger password reset when clicked
                        _resetPassword(context, emailController.text.trim());
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Loading spinner or Login button based on the loading state
                  if (isLoading)
                    const CircularProgressIndicator() // Shows a spinner if loading
                  else
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 60,
                        // Login button
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              // Show loading spinner
                              setState(() {
                                isLoading = true;
                              });

                              // Try to log in the user
                              await _loginUser(
                                context,
                                emailController.text.trim(),
                                passwordController.text.trim(),
                              );

                              // Hide loading spinner
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
                            'Login',
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

  // Widget to build input fields with optional email and password validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isEmail = false,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller, // Connects the controller to this input
      decoration: InputDecoration(
        labelText: label, // Display the label for the input
        labelStyle: const TextStyle(fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0), // Rounded corners
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.blue, width: 2.0),
        ),
      ),
      obscureText: isPassword, // Obscures text for password input
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label'; // Ensures input is not empty
        }
        if (isEmail) {
          const pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; // Regex for email validation
          final regExp = RegExp(pattern);
          if (!regExp.hasMatch(value)) {
            return 'Please enter a valid email'; // Ensures valid email format
          }
        }
        return null;
      },
    );
  }

  // Function to handle user login
  Future<void> _loginUser(BuildContext context, String email, String password) async {
    try {
      // Firebase Authentication: Sign in with email and password
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If login is successful, navigate to the home screen
      if (userCredential.user != null) {
        Navigator.pushNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Authentication errors
      String errorMessage = 'Login failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided.';
      }

      // Display error message as a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  // Function to handle password reset
  void _resetPassword(BuildContext context, String email) async {
    if (email.isEmpty) {
      // Show a message if the email field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email to reset password.')),
      );
      return;
    }

    try {
      // Firebase Authentication: Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } on FirebaseAuthException catch (e) {
      // Handle errors during password reset
      String errorMessage = 'Failed to reset password';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      }

      // Show error message as a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }
}
