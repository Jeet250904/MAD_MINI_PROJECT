import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateContestScreen extends StatefulWidget {
  final String matchId;

  CreateContestScreen({required this.matchId});

  @override
  _CreateContestScreenState createState() => _CreateContestScreenState();
}

class _CreateContestScreenState extends State<CreateContestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contestNameController = TextEditingController();
  final TextEditingController _entryFeeController = TextEditingController();
  final TextEditingController _prizeController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();
  String? _matchName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMatchDetails();
  }

 Future<void> _fetchMatchDetails() async {
  try {
    final matchDoc = await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).get();
    if (matchDoc.exists) {
      setState(() {
        _matchName = matchDoc['matchName'] ?? "No Match Selected";
      });
    } else {
      setState(() {
        _matchName = "No Match Selected";
      });
    }
  } catch (e) {
    print("Error fetching match details: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to fetch match details.')),
    );
    setState(() {
      _matchName = "No Match Selected";
    });
  }
}

  void _createContest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('contests').add({
        'matchId': widget.matchId,
        'matchName': _matchName ?? 'No Match Selected',
        'contestName': _contestNameController.text,
        'entryFee': int.parse(_entryFeeController.text),
        'prize': int.parse(_prizeController.text),
        'participants': int.parse(_participantsController.text),
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contest created successfully!')),
      );

      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      print("Error creating contest: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create contest. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Contest'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Match: ${_matchName ?? "Loading..."}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _contestNameController,
                decoration: InputDecoration(labelText: 'Contest Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a contest name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _entryFeeController,
                decoration: InputDecoration(labelText: 'Entry Fee'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an entry fee';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _prizeController,
                decoration: InputDecoration(labelText: 'Prize Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a prize amount';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _participantsController,
                decoration: InputDecoration(labelText: 'Total Participants'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of participants';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createContest,
                      child: Text('Create Contest'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}