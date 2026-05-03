import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import '../models/quest.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../services/photo_service.dart';
import '../services/storage_service.dart';

/// AR View Screen displays a 3D model and handles proximity detection.
///
/// Shows the user's distance to the quest and displays an "Enter AR Hunt"
/// button when within 20 meters. Allows photo capture and submission.
class ARViewScreen extends StatefulWidget {
  final Quest quest;
  final Position userPosition;

  const ARViewScreen({
    Key? key,
    required this.quest,
    required this.userPosition,
  }) : super(key: key);

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;

  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final PhotoService _photoService = PhotoService();
  final StorageService _storageService = StorageService();

  bool _isWithinProximity = false;
  double _distanceToQuest = 0;
  bool _isLoading = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeAR();
    _startLocationTracking();
  }

  /// Initializes the AR session.
  void _initializeAR() {
    arSessionManager = ARSessionManager();
    arObjectManager = ARObjectManager();
    arAnchorManager = ARAnchorManager();
  }

  /// Starts tracking user location to detect proximity.
  void _startLocationTracking() {
    _locationService.getPositionStream().listen((position) {
      setState(() {
        _currentPosition = position;
        _distanceToQuest = _locationService.calculateDistance(
          userLat: position.latitude,
          userLng: position.longitude,
          targetLat: widget.quest.lat,
          targetLng: widget.quest.lng,
        );

        _isWithinProximity = _locationService.isWithinProximity(
          userLat: position.latitude,
          userLng: position.longitude,
          targetLat: widget.quest.lat,
          targetLng: widget.quest.lng,
        );
      });
    });
  }

  /// Handles AR view tap - takes a photo and saves it.
  Future<void> _onARViewTap(ARHitTestResult hit) async {
    if (!_isWithinProximity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be within 20m to capture')),
      );
      return;
    }

    await _captureAndSavePhoto();
  }

  /// Captures photo, uploads it to Firebase Storage, and saves metadata in Firestore.
  Future<void> _captureAndSavePhoto() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _photoService.initializeCamera();
      final photoFile = await _photoService.capturePhoto();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be signed in to save captures');
      }

      final uploadResult = await _storageService.uploadDiscoveryPhoto(
        file: photoFile,
        userId: currentUser.uid,
        questId: widget.quest.id,
      );

      if (uploadResult == null) {
        throw Exception('Photo upload failed');
      }

      final photoUrl = uploadResult['downloadUrl']!;
      final storagePath = uploadResult['storagePath']!;

      final documentId = await _firestoreService.saveCapturedTreasure(
        questId: widget.quest.id,
        photoUrl: photoUrl,
        storagePath: storagePath,
        latitude: _currentPosition?.latitude ?? widget.userPosition.latitude,
        longitude: _currentPosition?.longitude ?? widget.userPosition.longitude,
        rewardPoints: 50,
      );

      if (documentId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo captured and saved!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save photo'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Builds the proximity indicator UI.
  Widget _buildProximityIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Distance: ${_distanceToQuest.toStringAsFixed(1)}m',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_distanceToQuest / 50).clamp(0, 1),
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isWithinProximity ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isWithinProximity ? '✓ Within Range' : 'Getting Closer',
            style: TextStyle(
              color: _isWithinProximity ? Colors.green : Colors.orange,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the action buttons.
  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isWithinProximity)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _captureAndSavePhoto,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt),
            label: const Text('Capture & Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Move Closer to Capture',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Map'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quest.name),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // AR View or placeholder
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.view_in_ar,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.quest.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Model: ${widget.quest.modelUrl}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Proximity Indicator
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildProximityIndicator(),
          ),
          // Action Buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    arSessionManager.dispose();
    _photoService.disposeCamera();
    super.dispose();
  }
}
