import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Import your Firebase options
import 'login_screen.dart';
import 'user_home_screen.dart';
import 'admin_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Widget> _getLandingPage() async {
    User? user = _auth.currentUser;
    if (user == null) {
      return LoginScreen();
    } else {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          final role = data?['role'] ?? 'user';
          if (role == 'admin') {
            return AdminHomeScreen();
          } else {
            return UserHomeScreen();
          }
        } else {
          // User exists in Auth but not Firestore, treat as logged out
          await _auth.signOut();
          return LoginScreen();
        }
      } catch (e) {
        // Error fetching user data, treat as logged out
        print("Error fetching user role: $e");
        await _auth.signOut();
        return LoginScreen();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FantaQcy App',
      theme: ThemeData(
        primarySwatch: Colors.indigo, // Or your preferred theme color
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // --- Add this line to remove the debug banner ---
      debugShowCheckedModeBanner: false,
      // --- End of change ---
      home: FutureBuilder<Widget>(
        future: _getLandingPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while checking auth state and role
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasError) {
            // Handle error state, maybe show login screen
            print("Error in FutureBuilder: ${snapshot.error}");
            return LoginScreen(); // Fallback to login screen on error
          } else if (snapshot.hasData) {
            // Return the determined landing page
            return snapshot.data!;
          } else {
            // Default fallback, should ideally not be reached
            return LoginScreen();
          }
        },
      ),
    );
  }
}