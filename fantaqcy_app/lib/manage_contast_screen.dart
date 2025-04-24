import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For JSON decoding if needed for matches
import 'package:flutter/services.dart'; // For loading assets if needed for matches

class ManageContestsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deleteContest(String contestId) async {
    await _firestore.collection('contests').doc(contestId).delete();
    // Optionally, you might want to delete related user entries,
    // but this can be complex and depends on your app's logic.
  }

  Future<void> _editContest(String contestId, Map<String, dynamic> updatedData) async {
    await _firestore.collection('contests').doc(contestId).update(updatedData);
  }

  // Placeholder for fetching matches if needed for the edit dialog dropdown
  Future<List<String>> _fetchMatchNames() async {
    // Example: Load from JSON or another Firestore collection
    try {
      final String response = await rootBundle.loadString('assets/teams_and_players.json');
      final data = json.decode(response);
      // Assuming your JSON has a structure like {'teams': [{'teamName': 'Team A'}, ...]}
      // and matches are derived or stored elsewhere. Adjust as needed.
      // This is a simplified example; you might have a dedicated 'matches' collection.
      List<String> matches = ["IND vs AUS", "ENG vs NZ"]; // Replace with actual logic
      return matches;
    } catch (e) {
      print("Error fetching match names: $e");
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Contests'),
        backgroundColor: Colors.indigo, // Consistent theme color
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('contests').orderBy('matchName').snapshots(), // Optional: Order contests
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No contests found.', style: TextStyle(fontSize: 16, color: Colors.grey[600])));
          } else {
            final contests = snapshot.data!.docs;

            return ListView.builder(
              padding: EdgeInsets.all(8.0), // Add padding around the list
              itemCount: contests.length,
              itemBuilder: (context, index) {
                final contest = contests[index];
                final contestId = contest.id;
                final data = contest.data() as Map<String, dynamic>? ?? {};

                final contestName = data['contestName'] ?? 'Unnamed Contest';
                final entryFee = data['entryFee'] ?? 0;
                final prize = data['prize'] ?? 0;
                final participantsLimit = data['participants'] ?? 0;
                final matchName = data['matchName'] ?? 'No Match Selected';
                final participantCount = data['participantCount'] ?? 0;
                final matchId = data['matchId'] ?? ''; // Get matchId if available

                // --- Use Card for better structure ---
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
                        SizedBox(height: 6.0),
                        Text(
                          'Match: $matchName',
                          style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Entry: $entryFee Coins', style: TextStyle(fontSize: 14.0)),
                            Text('Prize: $prize Coins', style: TextStyle(fontSize: 14.0)),
                          ],
                        ),
                        SizedBox(height: 8.0),
                        Divider(), // Separator before actions
                        SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out elements
                          children: [
                            // --- Participant Chip ---
                            Chip(
                              avatar: Icon(Icons.people_alt_outlined, size: 18, color: Colors.indigo),
                              label: Text(
                                (participantsLimit > 0 && participantCount >= participantsLimit)
                                    ? 'Full ($participantsLimit)'
                                    : '$participantCount / $participantsLimit', // Show count vs limit or Full
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: (participantsLimit > 0 && participantCount >= participantsLimit) ? Colors.redAccent : Colors.indigo[800]
                                ),
                              ),
                              backgroundColor: Colors.indigo.shade50,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            // --- Action Buttons ---
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blueAccent),
                                  tooltip: 'Edit Contest',
                                  onPressed: () {
                                    // --- Edit Dialog ---
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        // Use StatefulWidget for dialog state if dropdown needs it
                                        final _contestNameController = TextEditingController(text: contestName);
                                        final _entryFeeController = TextEditingController(text: entryFee.toString());
                                        final _prizeController = TextEditingController(text: prize.toString());
                                        final _participantsController = TextEditingController(text: participantsLimit.toString());
                                        // String? _selectedMatch = matchName; // Needs state management if using dropdown

                                        return AlertDialog(
                                          title: Text('Edit Contest'),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                TextField(controller: _contestNameController, decoration: InputDecoration(labelText: 'Contest Name')),
                                                TextField(controller: _entryFeeController, decoration: InputDecoration(labelText: 'Entry Fee'), keyboardType: TextInputType.number),
                                                TextField(controller: _prizeController, decoration: InputDecoration(labelText: 'Prize'), keyboardType: TextInputType.number),
                                                TextField(controller: _participantsController, decoration: InputDecoration(labelText: 'Max Participants'), keyboardType: TextInputType.number),
                                                // TODO: Add Match selection dropdown if needed, requires State management
                                                // FutureBuilder<List<String>>( ... DropdownButton ... )
                                                Padding(padding: EdgeInsets.only(top: 8), child: Text('Match: $matchName (Cannot change match)', style: TextStyle(color: Colors.grey))), // Simple display if not editable
                                              ],
                                            ),
                                          ),
                                          actions: [
                                             TextButton(
                                              child: Text('Cancel'),
                                              onPressed: () => Navigator.of(dialogContext).pop(),
                                            ),
                                            TextButton(
                                              child: Text('Save'),
                                              onPressed: () async {
                                                final updatedData = {
                                                  'contestName': _contestNameController.text,
                                                  'entryFee': int.tryParse(_entryFeeController.text) ?? entryFee,
                                                  'prize': int.tryParse(_prizeController.text) ?? prize,
                                                  'participants': int.tryParse(_participantsController.text) ?? participantsLimit,
                                                  // 'matchName': _selectedMatch, // Update if dropdown is used
                                                };
                                                try {
                                                    await _editContest(contestId, updatedData);
                                                    Navigator.of(dialogContext).pop(); // Close dialog on success
                                                    if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Contest updated'), backgroundColor: Colors.green)
                                                        );
                                                    }
                                                } catch (e) {
                                                    print("Error updating contest: $e");
                                                    // Optionally show error in dialog or SnackBar
                                                    if (dialogContext.mounted) { // Use dialogContext here
                                                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                                                            SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.redAccent)
                                                        );
                                                    }
                                                }
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_forever, color: Colors.redAccent),
                                  tooltip: 'Delete Contest',
                                  onPressed: () async {
                                    // --- Delete Confirmation Dialog ---
                                    bool? confirmDelete = await showDialog<bool>(
                                      context: context, // Provide the context
                                      builder: (BuildContext dialogContext) { // Builder function
                                        return AlertDialog(
                                          title: Text('Confirm Delete'),
                                          content: Text('Are you sure you want to delete the contest "$contestName"? This action cannot be undone.'),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text('Cancel'),
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop(false); // Return false when cancelled
                                              },
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              child: Text('Delete'),
                                              onPressed: () {
                                                Navigator.of(dialogContext).pop(true); // Return true when confirmed
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ); // End showDialog

                                    // --- Perform delete if confirmed ---
                                    if (confirmDelete == true) {
                                      try {
                                          await _deleteContest(contestId);
                                          // Check context availability before showing SnackBar
                                          if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Contest deleted successfully'), backgroundColor: Colors.green),
                                              );
                                          }
                                      } catch (e) {
                                          print("Error deleting contest: $e");
                                          if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Failed to delete contest: $e'), backgroundColor: Colors.redAccent),
                                              );
                                          }
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      // Optional: Add a FloatingActionButton to create new contests
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to a screen or show a dialog to create a new contest
          // Example: Navigator.push(context, MaterialPageRoute(builder: (_) => CreateContestScreen()));
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Create contest functionality not implemented yet.'))
           );
        },
        child: Icon(Icons.add),
        tooltip: 'Create New Contest',
        backgroundColor: Colors.indigo,
      ),
    );
  }
}