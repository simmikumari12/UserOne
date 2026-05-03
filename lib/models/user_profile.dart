class UserProfile {
  final String uid;
  final String displayName;
  final int points;
  final int completedQuests;
  final double averageCompletionTime;
  final int missedAttempts;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.points,
    required this.completedQuests,
    required this.averageCompletionTime,
    required this.missedAttempts,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] ?? 'Explorer',
      points: (data['points'] as num?)?.toInt() ?? 0,
      completedQuests: (data['completedQuests'] as num?)?.toInt() ?? 0,
      averageCompletionTime: (data['averageCompletionTime'] as num?)?.toDouble() ?? 0.0,
      missedAttempts: (data['missedAttempts'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'points': points,
      'completedQuests': completedQuests,
      'averageCompletionTime': averageCompletionTime,
      'missedAttempts': missedAttempts,
    };
  }
}
