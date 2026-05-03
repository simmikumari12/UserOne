import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quest.dart';

/// Service class for handling all Firestore operations.
///
/// Manages quest data retrieval and captured treasure submissions
/// while adhering to Firebase Spark Plan constraints.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches all quests from the /quests collection.
  ///
  /// Returns a stream of Quest lists for real-time updates.
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
  ///
  /// Returns null if the quest does not exist.
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

  /// Saves a captured treasure to the /captured_treasures collection.
  ///
  /// The image is stored as Base64 to comply with Spark Plan limitations
  /// (no Firebase Storage access).
  ///
  /// Returns the document ID if successful, null otherwise.
  Future<String?> saveCapturedTreasure({
    required String questId,
    required String base64Image,
  }) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      
      final treasure = CapturedTreasure(
        id: '', // Will be set by Firestore
        userId: userId,
        questId: questId,
        base64Image: base64Image,
        timestamp: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('captured_treasures')
          .add(treasure.toMap());

      return docRef.id;
    } catch (e) {
      print('Error saving captured treasure: $e');
      return null;
    }
  }

  /// Retrieves all captured treasures for a specific quest.
  ///
  /// Useful for viewing all submissions for a particular quest.
  Future<List<CapturedTreasure>> getCapturedTreasuresByQuest(String questId) async {
    try {
      final snapshot = await _firestore
          .collection('captured_treasures')
          .where('questId', isEqualTo: questId)
          .get();

      return snapshot.docs
          .map((doc) =>
              CapturedTreasure.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching captured treasures: $e');
      return [];
    }
  }

  /// Retrieves all captured treasures for the current user.
  ///
  /// Returns an empty list if the user is not authenticated.
  Future<List<CapturedTreasure>> getCapturedTreasuresByUser() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('captured_treasures')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) =>
              CapturedTreasure.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching user treasures: $e');
      return [];
    }
  }

  /// Anonymous authentication for users who haven't signed in.
  ///
  /// Enables core functionality without requiring user account creation.
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  /// Gets the current authenticated user.
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
