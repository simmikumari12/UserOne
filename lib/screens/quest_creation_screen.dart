import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/quest.dart';
import '../services/quest_generator_service.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import 'map_screen.dart';

class QuestCreationScreen extends StatefulWidget {
  const QuestCreationScreen({Key? key}) : super(key: key);

  @override
  State<QuestCreationScreen> createState() => _QuestCreationScreenState();
}

class _QuestCreationScreenState extends State<QuestCreationScreen> {
  final QuestGeneratorService _questGenerator = QuestGeneratorService();
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  Position? _currentPosition;
  bool _isGenerating = false;
  String _selectedDifficulty = 'Easy';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _generateQuest() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final quest = await _questGenerator.generateQuest(
        userPosition: _currentPosition!,
        difficulty: _selectedDifficulty,
      );

      if (quest != null) {
        await _firestoreService.createQuest(quest);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quest created successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create quest')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quest'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate a new quest based on your location',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (_currentPosition != null)
              Text(
                'Current Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
              )
            else
              const Text('Getting location...'),
            const SizedBox(height: 16),
            const Text('Select Difficulty:'),
            DropdownButton<String>(
              value: _selectedDifficulty,
              items: ['Easy', 'Medium', 'Hard'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDifficulty = newValue!;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateQuest,
              child: _isGenerating
                  ? const CircularProgressIndicator()
                  : const Text('Generate Quest'),
            ),
          ],
        ),
      ),
    );
  }
}