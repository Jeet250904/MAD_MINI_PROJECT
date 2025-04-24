import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_home_screen.dart';
import 'user_home_screen.dart';
import 'register_screen.dart'; // Ensure this import is correct

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance for Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Instance for Firestore
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Validate the form first
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do nothing
    }

    // Start loading indicator
    if (mounted) { // Check if widget is still mounted
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Attempt to sign in
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(), // Trim whitespace
        password: _passwordController.text.trim(), // Trim whitespace
      );

      // If sign-in is successful, check the role
      if (userCredential.user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        // Check if user document exists in Firestore
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?; // Safely cast data
          String role = data?['role'] ?? 'user'; // Default to 'user' if role is missing

          // Navigate based on role (check if mounted before navigation)
          if (mounted) {
            if (role == 'admin') {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => AdminHomeScreen()),
                (route) => false, // Clear all previous routes
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => UserHomeScreen()),
                (route) => false, // Clear all previous routes
              );
            }
          }
        } else {
          // Handle case where user exists in Auth but not Firestore
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('User data not found. Please contact support.'),
                 backgroundColor: Colors.orangeAccent,
               ),
             );
          }
          await _auth.signOut(); // Sign out the user
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      String message;
      print("Login Error Code: ${e.code}"); // Log the error code for debugging

      // Updated Error Handling for invalid-credential
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Invalid email or password.'; // Combined message
      } else if (e.code == 'invalid-email') {
         message = 'The email address format is invalid.';
      } else if (e.code == 'user-disabled') {
         message = 'This user account has been disabled.';
      } else if (e.code == 'too-many-requests') {
         message = 'Too many login attempts. Please try again later.';
      } else {
        message = 'An authentication error occurred. Please try again.'; // Generic auth error
        print("Unhandled FirebaseAuthException: ${e.message}");
      }
      // Show error message in a SnackBar (check if mounted)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent, // Use red for errors
          ),
        );
      }
    } catch (e) {
      // Handle any other unexpected errors
      print("Unexpected Login Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      // Stop loading indicator (check if mounted)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Optional: Add AppBar if desired
      // appBar: AppBar(title: Text('Login')),
      body: Center( // Center content vertically
        child: SingleChildScrollView( // Allow scrolling on small screens
          child: Padding(
            padding: const EdgeInsets.all(24.0), // Increased padding
            child: Form( // Wrap content in a Form widget
              key: _formKey, // Assign the key
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons stretch
                children: [
                  // Optional: Add an App Logo or Image here
                  // Image.asset('assets/logo.png', height: 80),
                  // SizedBox(height: 30),
                  Text(
                    'Welcome Back!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo), // Adjusted style
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Login to your account',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600), // Adjusted style
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40), // Increased spacing
                  TextFormField( // Use TextFormField for validation
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email address',
                      prefixIcon: Icon(Icons.email_outlined), // Use outlined icons
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0), // Rounded corners
                      ),
                      filled: true, // Add background color
                      fillColor: Colors.grey.shade100,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) { // Email validation
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                         return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16), // Consistent spacing
                  TextFormField( // Use TextFormField for validation
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_outline), // Use outlined icons
                      border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(12.0), // Rounded corners
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      // Optional: Add suffix icon to toggle password visibility
                      // suffixIcon: IconButton(
                      //   icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      //   onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      // ),
                    ),
                    obscureText: true, // Keep obscureText true for password
                    validator: (value) { // Password validation
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      // Optional: Add minimum length check
                      // if (value.length < 6) {
                      //   return 'Password must be at least 6 characters';
                      // }
                      return null;
                    },
                  ),
                  SizedBox(height: 24), // Spacing before button
                  _isLoading
                      ? Center(child: CircularProgressIndicator()) // Center the indicator
                      : ElevatedButton(
                          onPressed: _login,
                          child: Text('Login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo, // Use theme color
                            foregroundColor: Colors.white, // Text color
                            padding: EdgeInsets.symmetric(vertical: 16), // Taller button
                            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder( // Rounded button
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 3, // Add subtle shadow
                          ),
                        ),
                  SizedBox(height: 20), // Spacing before text button
                  TextButton(
                    onPressed: _isLoading ? null : () { // Disable button while loading
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Don\'t have an account? Sign up',
                      style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600), // Adjusted style
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
}