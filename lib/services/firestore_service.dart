import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quest.dart';
import '../models/user_profile.dart';

/// Service class for handling all Firestore operations.
///
/// Manages quest data retrieval, user profiles, generated quests, and
/// captured treasure metadata.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches all quests from the /quests collection.
  Stream<List<Quest>> getQuestsStream() {
    return _firestore
        .collection('quests')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Quest.fromFirestore(doc.data(), doc.id))
              .toList();
        })
        .handleError((error) {
          print('Error fetching quests: $error');
          return <Quest>[];
        });
  }

  /// Fetches a single quest by ID.
  Future<Quest?> getQuestById(String questId) async {
    try {
      final doc = await _firestore.collection('quests').doc(questId).get();
      if (doc.exists) {
        return Quest.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching quest: $e');
      return null;
    }
  }

  /// Creates a new quest document in Firestore.
  Future<Quest?> createQuest(Quest quest) async {
    try {
      final docRef = await _firestore.collection('quests').add(quest.toMap());
      return Quest(
        id: docRef.id,
        name: quest.name,
        lat: quest.lat,
        lng: quest.lng,
        modelUrl: quest.modelUrl,
        description: quest.description,
        imageUrl: quest.imageUrl,
        difficulty: quest.difficulty,
        generated: quest.generated,
        createdBy: quest.createdBy,
        createdAt: quest.createdAt,
        templateId: quest.templateId,
      );
    } catch (e) {
      print('Error creating quest: $e');
      return null;
    }
  }

  /// Retrieves or creates a user profile record.
  Future<UserProfile?> ensureUserProfile({
    required User user,
    String? displayName,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    try {
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        return UserProfile.fromFirestore(snapshot.data() as Map<String, dynamic>, user.uid);
      }
      final profile = UserProfile(
        uid: user.uid,
        displayName: displayName ?? user.displayName ?? 'Explorer',
        points: 0,
        completedQuests: 0,
        averageCompletionTime: 0.0,
        missedAttempts: 0,
      );
      await docRef.set(profile.toMap());
      return profile;
    } catch (e) {
      print('Error ensuring user profile: $e');
      return null;
    }
  }

  /// Returns a stream of user profile updates.
  Stream<UserProfile?> userProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return UserProfile.fromFirestore(snapshot.data() as Map<String, dynamic>, uid);
    });
  }

  /// Retrieves a user profile from Firestore.
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc.data() as Map<String, dynamic>, uid);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Saves metadata for a captured treasure and discovery photo.
  Future<String?> saveCapturedTreasure({
    required String questId,
    required String photoUrl,
    required String storagePath,
    required double latitude,
    required double longitude,
    required int rewardPoints,
  }) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      final treasure = CapturedTreasure(
        id: '',
        userId: userId,
        questId: questId,
        photoUrl: photoUrl,
        storagePath: storagePath,
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('captured_treasures')
          .add(treasure.toMap());

      await _updateUserProgress(
        userId: userId,
        pointsEarned: rewardPoints,
        completionTimeSeconds: 0,
      );

      return docRef.id;
    } catch (e) {
      print('Error saving captured treasure: $e');
      return null;
    }
  }

  /// Updates user progress after quest discovery.
  Future<void> _updateUserProgress({
    required String userId,
    required int pointsEarned,
    required int completionTimeSeconds,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        return;
      }
      final current = snapshot.data()!;
      final currentPoints = (current['points'] as num?)?.toInt() ?? 0;
      final completedQuests = (current['completedQuests'] as num?)?.toInt() ?? 0;
      final averageCompletionTime = (current['averageCompletionTime'] as num?)?.toDouble() ?? 0.0;
      final totalTime = averageCompletionTime * completedQuests + completionTimeSeconds;
      final nextCompleted = completedQuests + 1;
      final nextAverage = nextCompleted > 0 ? totalTime / nextCompleted : averageCompletionTime;

      transaction.update(userRef, {
        'points': currentPoints + pointsEarned,
        'completedQuests': nextCompleted,
        'averageCompletionTime': nextAverage,
      });
    });
  }

  /// Saves the current user's FCM device token.
  Future<void> saveUserDeviceToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'notificationEnabled': true,
      });
    } catch (e) {
      print('Error saving device token: $e');
    }
  }

  /// Retrieves the current authenticated user.
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Returns the leaderboard sorted by total points.
  Future<List<UserProfile>> getLeaderboard({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('points', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error loading leaderboard: $e');
      return [];
    }
  }
}
