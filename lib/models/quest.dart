/// Quest model representing a scavenger hunt quest.
///
/// Each quest contains geolocation data, a 3D model URL, and metadata
/// for the AR scavenger hunt experience.
class Quest {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String modelUrl;
  final String description;
  final String? imageUrl;
  final String difficulty;
  final bool generated;
  final String createdBy;
  final DateTime createdAt;
  final String? templateId;

  const Quest({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.modelUrl,
    required this.description,
    this.imageUrl,
    this.difficulty = 'Easy',
    this.generated = false,
    this.createdBy = '',
    required this.createdAt,
    this.templateId,
  });

  /// Creates a Quest instance from Firestore document data.
  factory Quest.fromFirestore(Map<String, dynamic> data, String docId) {
    return Quest(
      id: docId,
      name: data['name'] ?? 'Unknown Quest',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      modelUrl: data['modelUrl'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      difficulty: data['difficulty'] ?? 'Easy',
      generated: data['generated'] ?? false,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      templateId: data['templateId'],
    );
  }

  /// Converts Quest to a map for Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'modelUrl': modelUrl,
      'description': description,
      'imageUrl': imageUrl,
      'difficulty': difficulty,
      'generated': generated,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'templateId': templateId,
    };
  }
}

/// Captured treasure model for storing user photo submissions.
///
/// Uses Firebase Storage for the captured photo and Firestore for metadata.
class CapturedTreasure {
  final String id;
  final String userId;
  final String questId;
  final String? photoUrl;
  final String? storagePath;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;

  const CapturedTreasure({
    required this.id,
    required this.userId,
    required this.questId,
    this.photoUrl,
    this.storagePath,
    this.latitude,
    this.longitude,
    required this.timestamp,
  });

  /// Creates a CapturedTreasure instance from Firestore document data.
  factory CapturedTreasure.fromFirestore(Map<String, dynamic> data, String docId) {
    return CapturedTreasure(
      id: docId,
      userId: data['userId'] ?? '',
      questId: data['questId'] ?? '',
      photoUrl: data['photoUrl'],
      storagePath: data['storagePath'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts CapturedTreasure to a map for Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'questId': questId,
      'photoUrl': photoUrl,
      'storagePath': storagePath,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }
}
