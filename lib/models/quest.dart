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

  const Quest({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.modelUrl,
    required this.description,
    this.imageUrl,
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
    };
  }
}

/// Captured treasure model for storing user photo submissions.
/// 
/// Uses Base64 encoding for image data to work within Spark Plan limitations.
class CapturedTreasure {
  final String id;
  final String userId;
  final String questId;
  final String base64Image;
  final DateTime timestamp;

  const CapturedTreasure({
    required this.id,
    required this.userId,
    required this.questId,
    required this.base64Image,
    required this.timestamp,
  });

  /// Creates a CapturedTreasure instance from Firestore document data.
  factory CapturedTreasure.fromFirestore(Map<String, dynamic> data, String docId) {
    return CapturedTreasure(
      id: docId,
      userId: data['userId'] ?? '',
      questId: data['questId'] ?? '',
      base64Image: data['base64Image'] ?? '',
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts CapturedTreasure to a map for Firestore operations.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'questId': questId,
      'base64Image': base64Image,
      'timestamp': timestamp,
    };
  }
}
