import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_contast_screen.dart';
import 'manage_contast_screen.dart';
import 'view_users_screen.dart';
import 'report_screen.dart';
import 'login_screen.dart';
import 'admin_team_selection_screen.dart'; // Import the AdminTeamSelectionScreen

class AdminHomeScreen extends StatelessWidget {
  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Redirect to LoginScreen
      (route) => false, // Clear all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Generate a unique matchId (e.g., using a timestamp or UUID)
                final matchId = DateTime.now().millisecondsSinceEpoch.toString();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminTeamSelectionScreen(matchId: matchId),
                  ),
                );
              },
              child: Text('Select Teams for Match'),
            ),
            SizedBox(height: 20), // Add spacing between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageContestsScreen()),
                );
              },
              child: Text('Manage Contests'),
            ),
            SizedBox(height: 20), // Add spacing between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewUsersScreen()),
                );
              },
              child: Text('View Users'),
            ),
            SizedBox(height: 20), // Add spacing between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportsScreen()),
                );
              },
              child: Text('Reports and Analytics'),
            ),
          ],
        ),
      ),
    );
  }
}