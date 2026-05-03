import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/quest.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
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
  late GoogleMapController _mapController;
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  Position? _userPosition;
  Set<Marker> _markers = {};
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
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

      // Animate map to user location
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );

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
  void _updateMarkersFromQuests(List<Quest> quests) {
    final newMarkers = <Marker>{};

    for (final quest in quests) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(quest.id),
          position: LatLng(quest.lat, quest.lng),
          title: quest.name,
          infoWindow: InfoWindow(
            title: quest.name,
            snippet: quest.description,
            onTap: () => _onMarkerTap(quest),
          ),
          onTap: () => _onMarkerTap(quest),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
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
                        _updateMarkersFromQuests(quests);

                        return GoogleMap(
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _userPosition!.latitude,
                              _userPosition!.longitude,
                            ),
                            zoom: 15,
                          ),
                          markers: _markers,
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
    _mapController.dispose();
    super.dispose();
  }
}
