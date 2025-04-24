import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamSelectionScreen extends StatefulWidget {
  final String matchId;
  final String matchName;
  final String contestId;
  final String contestName;
  final List<String> players;

  TeamSelectionScreen({
    required this.matchId,
    required this.matchName,
    required this.contestId,
    required this.contestName,
    required this.players,
  });

  @override
  _TeamSelectionScreenState createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  List<String> _players = [];
  List<String> _selectedPlayers = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
    _loadExistingTeamIfAny();
  }

  Future<void> _loadExistingTeamIfAny() async {
     final user = FirebaseAuth.instance.currentUser;
     if (user != null) {
        try {
          final joinedContestDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('joinedContests')
              .doc(widget.contestId)
              .get();
          if (mounted && joinedContestDoc.exists) {
             final data = joinedContestDoc.data();
             if (data != null && data.containsKey('selectedTeam')) {
                setState(() {
                   _selectedPlayers = List<String>.from(data['selectedTeam']);
                });
             }
          }
        } catch (e) {
          print("Error loading existing team: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not load existing team data.'), backgroundColor: Colors.orangeAccent),
            );
          }
        }
     }
     // Ensure loading state is turned off even if user is null or error occurs
     if (mounted) {
        setState(() { _isLoading = false; });
     }
  }

  Future<void> _fetchPlayers() async {
    // Assign players passed from the previous screen
    if (widget.players.isEmpty) {
       print("Warning: Player list passed to TeamSelectionScreen is empty for match ${widget.matchName}");
    }
    // No need to set loading state here as initState handles it
    setState(() {
      _players = widget.players;
      // _isLoading = false; // Moved to _loadExistingTeamIfAny's finally block
    });
  }

  Future<void> _saveSelectedTeam() async {
    if (_isSaving) return;

    if (_selectedPlayers.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select exactly 11 players.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not logged in. Please log in again.'), backgroundColor: Colors.redAccent));
       return;
    }

    setState(() { _isSaving = true; });

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final joinedContestRef = userRef.collection('joinedContests').doc(widget.contestId);
    final contestRef = FirebaseFirestore.instance.collection('contests').doc(widget.contestId);

    String? transactionFailureReason;
    const String reasonContestFull = 'CONTEST_FULL';
    const String reasonInsufficientCoins = 'INSUFFICIENT_COINS';
    const String reasonContestNotFound = 'CONTEST_NOT_FOUND';
    const String reasonUserNotFound = 'USER_NOT_FOUND';

    try {
      String? transactionResult;
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transactionFailureReason = null; // Reset reason at the start of each attempt

        final joinedSnapshot = await transaction.get(joinedContestRef);
        final userSnapshot = await transaction.get(userRef);
        final contestSnapshot = await transaction.get(contestRef);
        final bool alreadyJoined = joinedSnapshot.exists;

        if (!userSnapshot.exists) {
          transactionFailureReason = reasonUserNotFound; throw Exception('Aborting: User not found');
        }
        if (!contestSnapshot.exists) {
          transactionFailureReason = reasonContestNotFound; throw Exception('Aborting: Contest not found');
        }

        // --- Save/Update Team ---
        // This is the data being written/updated
        final teamData = {
          'contestId': widget.contestId,
          'matchId': widget.matchId,
          'matchName': widget.matchName,
          'contestName': widget.contestName,
          'selectedTeam': _selectedPlayers, // The list of selected players
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        // --- Logic for first time join ---
        if (!alreadyJoined) {
          final userData = userSnapshot.data() as Map<String, dynamic>?;
          final contestData = contestSnapshot.data() as Map<String, dynamic>?;
          final currentCoins = userData?['coins'] ?? 0;
          final entryFee = contestData?['entryFee'] ?? 100;
          final participantLimit = contestData?['participants'] ?? 0;
          final currentParticipantCount = contestData?['participantCount'] ?? 0;

          if (participantLimit > 0 && currentParticipantCount >= participantLimit) {
             transactionFailureReason = reasonContestFull; throw Exception('Aborting: Contest full');
          }
          if (currentCoins < entryFee) {
            transactionFailureReason = reasonInsufficientCoins; throw Exception('Aborting: Insufficient coins');
          }

          // Set the team data for the first time
          transaction.set(joinedContestRef, teamData);
          // Update user coins and contest participant count
          final updatedCoins = currentCoins - entryFee;
          transaction.update(userRef, {'coins': updatedCoins});
          transaction.update(contestRef, {'participantCount': FieldValue.increment(1)});
          transactionResult = "Team created and joined! Coins deducted.";
        } else {
          // --- Logic for updating existing team ---
          // Update the existing document with new team data
          transaction.update(joinedContestRef, teamData); // Use update, not set
          transactionResult = "Team updated successfully!";
        }
      }); // --- End of Transaction ---

      // --- Success Case ---
      if (transactionResult != null) {
         print("Transaction successful: $transactionResult");
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(transactionResult!), backgroundColor: Colors.green));
             Navigator.pop(context); // Navigate back only on complete success
         }
      }

    } catch (e) {
      // --- Error Handling ---
      print("Transaction failed. Reason: $transactionFailureReason, Error: $e");
      print("Error type: ${e.runtimeType}");

      String errorMessage;
      if (transactionFailureReason == reasonContestFull) {
          errorMessage = 'Sorry, this contest is already full.';
      } else if (transactionFailureReason == reasonInsufficientCoins) {
          errorMessage = 'Insufficient coins to join this contest.';
      } else if (transactionFailureReason == reasonContestNotFound) {
          errorMessage = 'Contest details could not be found.';
      } else if (transactionFailureReason == reasonUserNotFound) {
          errorMessage = 'User details could not be found.';
      }
      else if (e is FirebaseException) {
        if (e.code == 'unauthenticated' || e.code == 'permission-denied') {
           errorMessage = 'Authentication failed. Please log in again.';
        } else if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
           errorMessage = 'Network error. Please check your connection and try again.';
        }
         else {
          errorMessage = 'An error occurred (${e.code}). Please try again.';
          print("Unhandled FirebaseException: Code=${e.code}, Message=${e.message}");
        }
      }
      else {
         print("Caught unexpected error type during transaction: ${e.runtimeType}");
         print("Unexpected error details: $e");
         errorMessage = 'An unexpected error occurred. Please check connection or log in again.';
      }

      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
          );
      }

    } finally {
       if (mounted) {
          setState(() { _isSaving = false; });
       }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Team (${_selectedPlayers.length}/11)'),
            Text(widget.contestName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _players.isEmpty
              ? Center(child: Text('No players available for this match.', style: TextStyle(fontSize: 16, color: Colors.grey[600])))
              : ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    final isSelected = _selectedPlayers.contains(player);

                    return Card(
                       elevation: 1.5,
                       margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                       color: isSelected ? Colors.green.shade50 : null,
                       child: ListTile(
                         contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                         title: Text(player, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                         trailing: Icon(
                           isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                           color: isSelected ? Colors.green : Colors.grey.shade400,
                           size: 26.0,
                         ),
                         onTap: () {
                           setState(() {
                             if (isSelected) {
                               _selectedPlayers.remove(player);
                             } else if (_selectedPlayers.length < 11) {
                               _selectedPlayers.add(player);
                             } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('You can only select 11 players.'), duration: Duration(seconds: 2), backgroundColor: Colors.orangeAccent),
                                );
                             }
                           });
                         },
                       ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSelectedTeam,
        tooltip: 'Save Team',
        isExtended: true,
        icon: _isSaving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0)) : Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Team'),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}