import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/quest.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';

/// Service that generates location-aware quests based on templates and user history.
class QuestGeneratorService {
  final FirestoreService _firestoreService = FirestoreService();
  final Random _random = Random();

  static const List<Map<String, dynamic>> _templates = [
    {
      'templateId': 'forest_rune',
      'name': 'Forest Rune',
      'description': 'Locate the hidden rune among ancient trees.',
      'modelUrl': 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb',
      'difficulty': 'Easy',
      'latOffset': 0.0003,
      'lngOffset': 0.0002,
    },
    {
      'templateId': 'street_art',
      'name': 'Street Art Hunt',
      'description': 'Find the urban treasure hidden near local art.',
      'modelUrl': 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb',
      'difficulty': 'Medium',
      'latOffset': -0.00025,
      'lngOffset': 0.00015,
    },
    {
      'templateId': 'river_beacon',
      'name': 'River Beacon',
      'description': 'Seek the glowing beacon by the water.',
      'modelUrl': 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb',
      'difficulty': 'Hard',
      'latOffset': 0.0004,
      'lngOffset': -0.0003,
    },
  ];

  /// Recommends a difficulty based on player history.
  String recommendDifficulty(UserProfile profile) {
    if (profile.completedQuests < 2) {
      return 'Easy';
    }

    if (profile.missedAttempts > 3 || profile.averageCompletionTime > 300) {
      return 'Easy';
    }

    if (profile.averageCompletionTime < 180 && profile.completedQuests >= 4) {
      return 'Hard';
    }

    return 'Medium';
  }

  /// Generates a new quest near the player's current location.
  Future<Quest?> generateQuest({
    required Position userPosition,
    required String difficulty,
  }) async {
    final template = _templates.firstWhere(
      (entry) => entry['difficulty'] == difficulty,
      orElse: () => _templates.first,
    );

    final latOffset = (template['latOffset'] as double) * (_random.nextBool() ? 1 : -1);
    final lngOffset = (template['lngOffset'] as double) * (_random.nextBool() ? 1 : -1);

    final generatedQuest = Quest(
      id: '',
      name: '${template['name']} Challenge',
      lat: userPosition.latitude + latOffset,
      lng: userPosition.longitude + lngOffset,
      modelUrl: template['modelUrl'] as String,
      description: template['description'] as String,
      difficulty: difficulty,
      templateId: template['templateId'] as String,
      createdBy: 'generated',
      createdAt: DateTime.now(),
      generated: true,
    );

    return generatedQuest;
  }
}
