import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMatchScreen extends StatefulWidget {
  @override
  _AddMatchScreenState createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  final TextEditingController _team1Controller = TextEditingController();
  final TextEditingController _team2Controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _addMatch() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance.collection('matches').add({
        'team1': _team1Controller.text,
        'team2': _team2Controller.text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Match added successfully')),
      );
      _team1Controller.clear();
      _team2Controller.clear();
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add match')),
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
        title: Text('Add Match'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _team1Controller,
              decoration: InputDecoration(labelText: 'Team 1'),
            ),
            TextField(
              controller: _team2Controller,
              decoration: InputDecoration(labelText: 'Team 2'),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _addMatch,
                    child: Text('Add Match'),
                  ),
          ],
        ),
      ),
    );
  }
}