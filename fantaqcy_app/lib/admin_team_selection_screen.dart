import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_contast_screen.dart';

class AdminTeamSelectionScreen extends StatefulWidget {
  final String matchId;

  AdminTeamSelectionScreen({required this.matchId});

  @override
  _AdminTeamSelectionScreenState createState() => _AdminTeamSelectionScreenState();
}

class _AdminTeamSelectionScreenState extends State<AdminTeamSelectionScreen> {
  final List<String> _iplTeams = [
    "Chennai Super Kings",
    "Mumbai Indians",
    "Royal Challengers Bangalore",
    "Kolkata Knight Riders",
    "Punjab Kings",
    "Delhi Capitals",
    "Rajasthan Royals",
    "Sunrisers Hyderabad",
    "Lucknow Super Giants",
    "Gujarat Titans"
  ];

  List<String> _selectedTeams = [];

 void _saveTeamsAndProceed() async {
  if (_selectedTeams.length != 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select exactly 2 teams.')),
    );
    return;
  }

  try {
    final matchName = "${_selectedTeams[0]} vs ${_selectedTeams[1]}";

    // Save the selected teams and matchName in Firestore
    await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).set({
      'team1': _selectedTeams[0],
      'team2': _selectedTeams[1],
      'matchName': matchName,
    });

    // Navigate to CreateContestScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateContestScreen(matchId: widget.matchId),
      ),
    );
  } catch (e) {
    print("Error saving teams: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save teams. Please try again.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Teams for Match'),
      ),
      body: ListView.builder(
        itemCount: _iplTeams.length,
        itemBuilder: (context, index) {
          final team = _iplTeams[index];
          final isSelected = _selectedTeams.contains(team);

          return ListTile(
            title: Text(team),
            trailing: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedTeams.remove(team);
                } else if (_selectedTeams.length < 2) {
                  _selectedTeams.add(team);
                }
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTeamsAndProceed,
        child: Icon(Icons.arrow_forward),
      ),
    );
  }
}