import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserProfile> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final leaderboard = await _firestoreService.getLeaderboard();
    setState(() {
      _leaderboard = leaderboard;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboard.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: _leaderboard.length,
                  itemBuilder: (context, index) {
                    final profile = _leaderboard[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(profile.displayName),
                      subtitle: Text('Points: ${profile.points}'),
                      trailing: Text('${profile.completedQuests} quests'),
                    );
                  },
                ),
    );
  }
}