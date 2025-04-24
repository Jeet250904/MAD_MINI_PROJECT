import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For JSON decoding
import 'package:flutter/services.dart'; // For loading assets
import 'login_screen.dart';
import 'team_selection_screen.dart'; // Import the TeamSelectionScreen

class UserHomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> _getUserStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore.collection('users').doc(user.uid).snapshots();
    }
    return const Stream.empty();
  }

  Stream<QuerySnapshot> _getContests() {
    // Fetch all contests (you might want to filter/order later)
    return _firestore.collection('contests').snapshots();
  }

  Stream<QuerySnapshot> _getJoinedContests() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('joinedContests')
          .snapshots();
    }
    return const Stream.empty();
  }

  // Function to fetch players for a specific match from the JSON file
  Future<List<String>> _fetchPlayersForMatch(String matchName) async {
    try {
      final String response = await rootBundle.loadString('assets/teams_and_players.json');
      final data = json.decode(response);
      final teams = matchName.split(' vs ');
      if (teams.length != 2) return [];
      final team1 = teams[0];
      final team2 = teams[1];
      final team1Players = List<String>.from(data['teams']
          .firstWhere((team) => team['teamName'] == team1, orElse: () => null)?['players'] ?? []);
      final team2Players = List<String>.from(data['teams']
          .firstWhere((team) => team['teamName'] == team2, orElse: () => null)?['players'] ?? []);
      return [...team1Players, ...team2Players];
    } catch (e) {
      print("Error fetching players for match '$matchName': $e");
      return []; // Return empty list on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FantaQcy Home'), // Updated title
        backgroundColor: Colors.indigo, // Consistent theme
        actions: [
          // --- User Coins Display (Moved to AppBar) ---
          StreamBuilder<DocumentSnapshot>(
            stream: _getUserStream(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                final coins = userData['coins'] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Chip(
                      avatar: Icon(Icons.monetization_on, color: Colors.amber.shade700, size: 18),
                      label: Text('$coins', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[900])),
                      backgroundColor: Colors.white,
                    ),
                  ),
                );
              }
              return SizedBox.shrink(); // Return empty space if no data
            }
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Stream 1: Get all contests
        stream: _getContests(),
        builder: (context, contestSnapshot) {
          if (contestSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (contestSnapshot.hasError) {
            return Center(child: Text('Error loading contests: ${contestSnapshot.error}'));
          }
          if (!contestSnapshot.hasData || contestSnapshot.data!.docs.isEmpty) {
            return Center(child: Text('No contests available right now.', style: TextStyle(fontSize: 16, color: Colors.grey[600])));
          }

          final contests = contestSnapshot.data!.docs;

          // Stream 2: Get the IDs of contests the current user has joined
          return StreamBuilder<QuerySnapshot>(
            stream: _getJoinedContests(),
            builder: (context, joinedSnapshot) {
              // Set of joined contest IDs for quick lookup
              Set<String> joinedContestIds = {};
              if (joinedSnapshot.connectionState == ConnectionState.active && joinedSnapshot.hasData) {
                joinedContestIds = joinedSnapshot.data!.docs.map((doc) => doc.id).toSet();
              }
              // Don't show loading for this inner stream, just use available data

              // --- Build the single list ---
              return ListView.builder(
                padding: EdgeInsets.all(8.0), // Add padding around the list
                itemCount: contests.length,
                itemBuilder: (context, index) {
                  final contest = contests[index];
                  final contestId = contest.id;
                  final data = contest.data() as Map<String, dynamic>? ?? {};

                  final contestName = data['contestName'] ?? 'Unnamed Contest';
                  final matchName = data['matchName'] ?? 'No Match Selected';
                  final entryFee = data['entryFee'] ?? 0;
                  final prize = data['prize'] ?? 0; // Assuming prize exists
                  final participantsLimit = data['participants'] ?? 0;
                  final participantCount = data['participantCount'] ?? 0;

                  // --- Check if the user has joined this contest ---
                  final bool hasJoined = joinedContestIds.contains(contestId);

                  return Card(
                    elevation: 3.0,
                    margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contestName,
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.indigo[800]),
                          ),
                           SizedBox(height: 4.0),
                           Text(
                             'Match: $matchName', // Show match name clearly
                             style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                           ),
                          SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Entry: $entryFee Coins', style: TextStyle(fontSize: 14.0)),
                              Text('Prize: $prize Coins', style: TextStyle(fontSize: 14.0)), // Show prize
                            ],
                          ),
                          SizedBox(height: 8.0),
                          Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               // Show spots left or full status
                               Text(
                                 (participantsLimit > 0 && participantCount >= participantsLimit)
                                    ? 'Spots: Full'
                                    : 'Spots: $participantCount / $participantsLimit',
                                 style: TextStyle(
                                    fontSize: 14.0,
                                    color: (participantsLimit > 0 && participantCount >= participantsLimit) ? Colors.redAccent : Colors.grey[700],
                                    fontWeight: (participantsLimit > 0 && participantCount >= participantsLimit) ? FontWeight.bold : FontWeight.normal,
                                 )
                               ),
                               // --- Conditional Button ---
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasJoined ? Colors.green : Colors.blueAccent, // Different color based on state
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    textStyle: TextStyle(fontSize: 14),
                                  ),
                                  onPressed: () async { // Make onPressed async
                                    try {
                                      // Fetch players needed for the TeamSelectionScreen
                                      final players = await _fetchPlayersForMatch(matchName);

                                      // Check if players were fetched successfully
                                      if (players.isEmpty && matchName != 'No Match Selected') {
                                         print("No players found for match: $matchName");
                                         ScaffoldMessenger.of(context).showSnackBar(
                                           SnackBar(content: Text('Could not load player data for this match.'), backgroundColor: Colors.orangeAccent),
                                         );
                                         return; // Don't navigate if players aren't loaded
                                      }

                                      // Navigate to Team Selection Screen
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TeamSelectionScreen(
                                            // Use matchId from contest data if available, else contestId
                                            matchId: data['matchId'] ?? contestId,
                                            matchName: matchName,
                                            contestId: contestId,
                                            contestName: contestName,
                                            players: players, // Pass the fetched player list
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                       print("Error navigating to team selection: $e");
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         SnackBar(content: Text('An error occurred. Please try again.'), backgroundColor: Colors.redAccent),
                                       );
                                    }
                                  },
                                  child: Text(hasJoined ? 'View/Edit Team' : 'Join'),
                                ),
                             ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}