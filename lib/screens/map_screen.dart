import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/quest.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/messaging_service.dart';
import 'ar_view_screen.dart';

/// Map Screen displays a Google Map with quest markers.
///
/// Shows the user's current location and all available quests
/// from the Firestore collection. Allows navigation to AR view
/// when tapping on a quest marker.
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final MessagingService _messagingService = MessagingService();

  Position? _userPosition;
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _initializeMessaging();
  }

  Future<void> _initializeMessaging() async {
    final permissionGranted = await _messagingService.requestPermission();
    if (!permissionGranted) {
      return;
    }

    final token = await _messagingService.getDeviceToken();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (token != null && currentUser != null) {
      await _firestoreService.saveUserDeviceToken(currentUser.uid, token);
    }

    _messagingService.configureForegroundMessageHandling(
      onMessage: (message) {
        if (message.notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.notification?.title ?? 'New notification'),
            ),
          );
        }
      },
    );
  }

  /// Initializes user location and requests permission if needed.
  Future<void> _initializeLocation() async {
    try {
      final hasPermission = await _locationService.checkLocationPermission();
      if (!hasPermission) {
        final granted = await _locationService.requestLocationPermission();
        if (!granted) {
          setState(() {
            _locationError = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      final position = await _locationService.getCurrentPosition();
      setState(() {
        _userPosition = position;
        _isLoadingLocation = false;
      });

      // Start listening to location updates
      _locationService.getPositionStream().listen((position) {
        setState(() {
          _userPosition = position;
        });
      });
    } catch (e) {
      setState(() {
        _locationError = 'Error getting location: $e';
        _isLoadingLocation = false;
      });
    }
  }

  /// Builds markers from quest data.
  Set<Marker> _buildMarkersFromQuests(List<Quest> quests) {
    return quests.map((quest) {
      return Marker(
        markerId: MarkerId(quest.id),
        position: LatLng(quest.lat, quest.lng),
        title: quest.name,
        infoWindow: InfoWindow(
          title: quest.name,
          snippet: quest.description,
          onTap: () => _onMarkerTap(quest),
        ),
        onTap: () => _onMarkerTap(quest),
      );
    }).toSet();
  }

  /// Handles marker tap - navigates to AR view for the quest.
  void _onMarkerTap(Quest quest) {
    if (_userPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ARViewScreen(
          quest: quest,
          userPosition: _userPosition!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARQuest Map'),
        elevation: 0,
      ),
      body: _isLoadingLocation
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _locationError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_locationError!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeLocation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _userPosition == null
                  ? const Center(
                      child: Text('Unable to get location'),
                    )
                  : StreamBuilder<List<Quest>>(
                      stream: _firestoreService.getQuestsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final quests = snapshot.data ?? [];
                        final markers = _buildMarkersFromQuests(quests);

                        return GoogleMap(
                          onMapCreated: (controller) {
                            _mapController = controller;
                            if (_userPosition != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(
                                    _userPosition!.latitude,
                                    _userPosition!.longitude,
                                  ),
                                ),
                              );
                            }
                          },
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _userPosition!.latitude,
                              _userPosition!.longitude,
                            ),
                            zoom: 15,
                          ),
                          markers: markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          scrollGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                        );
                      },
                    ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
