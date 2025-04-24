import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends StatelessWidget {
  Future<int> _getUserCount() async {
    // Fetch the total number of users from Firestore
    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    return usersSnapshot.docs.length;
  }

  Future<int> _getContestCount() async {
    // Fetch the total number of contests from Firestore
    QuerySnapshot contestsSnapshot = await FirebaseFirestore.instance.collection('contests').get();
    return contestsSnapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports and Analytics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            FutureBuilder<int>(
              future: _getUserCount(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Show loading indicator while fetching data
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  int userCount = snapshot.data ?? 0;
                  return Text(
                    'Total Users: $userCount',
                    style: TextStyle(fontSize: 18),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            FutureBuilder<int>(
              future: _getContestCount(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Show loading indicator while fetching data
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  int contestCount = snapshot.data ?? 0;
                  return Text(
                    'Total Contests: $contestCount',
                    style: TextStyle(fontSize: 18),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            // Add more report data here if needed
          ],
        ),
      ),
    );
  }
}