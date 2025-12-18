import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import '../services/drone_service.dart';
import '../services/mock_glucose_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';

class DroneTrackingScreen extends ConsumerStatefulWidget {
  const DroneTrackingScreen({super.key});

  @override
  ConsumerState<DroneTrackingScreen> createState() => _DroneTrackingScreenState();
}

class _DroneTrackingScreenState extends ConsumerState<DroneTrackingScreen> {
  GoogleMapController? _mapController;
  late final BitmapDescriptor _droneIcon;
  late final BitmapDescriptor _userIcon;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    // Initialize with default markers
    _droneIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
    _userIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    
    // Get user location and dispatch drone
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getLocationAndDispatch();
    });
  }

  Future<void> _getLocationAndDispatch() async {
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No internet connection. Please check your network.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
             action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _getLocationAndDispatch(),
            ),
          ),
        );
      }
      return;
    }

    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentLocation();
    
    if (position != null) {
      // Debug: Print location info
      print('📍 User Location: ${position.latitude}, ${position.longitude}');
      print('📍 Accuracy: ${position.accuracy}m');
      print('📍 Timestamp: ${position.timestamp}');
      
      // Set user location in drone service
      ref.read(droneServiceProvider).setUserLocation(
        position.latitude,
        position.longitude,
      );
      
      final droneService = ref.read(droneServiceProvider);
      print('📍 Base Location: ${droneService.baseLat}, ${droneService.baseLon}');
      
      // Dispatch drone
      ref.read(droneServiceProvider).dispatchDrone();
      
      // Initialize markers after location is set
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeMarkers();
      });
    } else {
      // Show error if location not available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Konum alınamadı. Lütfen konum iznini verin.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: () => _getLocationAndDispatch(),
            ),
          ),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Initialize markers after map is created
    _initializeMarkers();
  }

  void _initializeMarkers() {
    final droneStateAsync = ref.read(droneStateProvider);
    final droneService = ref.read(droneServiceProvider);
    
    droneStateAsync.whenData((droneState) {
      if (!droneService.hasUserLocation || droneService.baseLat == null) return;
      
      _updateMarkers(droneState);
    });
  }

  void _updateMarkers(DroneState droneState) {
    final droneService = ref.read(droneServiceProvider);
    
    if (!droneService.hasUserLocation || droneService.baseLat == null) return;
    
    final dronePosition = LatLng(droneState.latitude, droneState.longitude);
    final userPosition = LatLng(droneService.userLat!, droneService.userLon!);
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('drone'),
          position: dronePosition,
          icon: _droneIcon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: 'Drone',
            snippet: '${(droneState.distance * 1000).toStringAsFixed(0)} m away',
          ),
        ),
        Marker(
          markerId: const MarkerId('user'),
          position: userPosition,
          icon: _userIcon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: '${droneService.userLat!.toStringAsFixed(6)}, ${droneService.userLon!.toStringAsFixed(6)}',
          ),
        ),
      };
      
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [dronePosition, userPosition],
          color: Colors.cyanAccent,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    });
  }


  double _calculateZoomLevel(double distance) {
    // Adjust zoom based on distance
    if (distance < 0.1) return 17.0; // Very close - more zoom
    if (distance < 0.5) return 16.0; // Close
    if (distance < 1.0) return 15.0; // Medium
    if (distance < 2.0) return 14.5; // Medium-far
    return 14.0; // Far
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final droneStateAsync = ref.watch(droneStateProvider);
    final glucoseAsync = ref.watch(glucoseProvider);

    // Listen to drone state changes and update markers
    ref.listen<AsyncValue<DroneState>>(droneStateProvider, (previous, next) {
      next.whenData((droneState) {
        if (mounted) {
          _updateMarkers(droneState);
        }
      });
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        
        // Check if drone is dispatched or in transit
        final currentState = droneStateAsync.valueOrNull;
        final shouldShowDialog = currentState != null &&
            (currentState.status == DroneStatus.dispatched ||
             currentState.status == DroneStatus.inTransit ||
             currentState.status == DroneStatus.approaching);
        
        if (shouldShowDialog) {
          _showExitConfirmationDialog(context).then((shouldPop) {
            if (shouldPop && mounted) {
              // Cancel drone dispatch
              ref.read(droneServiceProvider).cancelDispatch();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          });
        } else {
          // No active dispatch, allow normal pop
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0E21),
                Color(0xFF1A237E),
              ],
            ),
          ),
          child: SafeArea(
            child: droneStateAsync.when(
              data: (droneState) => _buildTrackingContent(droneState, glucoseAsync),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error: $err',
                  style: GoogleFonts.outfit(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingContent(DroneState droneState, AsyncValue<List<GlucoseReading>> glucoseAsync) {
    final currentGlucose = glucoseAsync.valueOrNull
        ?.where((r) => !r.isPrediction)
        .last
        .value ?? 110.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Ensure scroll works
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  // Use the same logic as PopScope
                  final droneStateAsync = ref.read(droneStateProvider);
                  final currentState = droneStateAsync.valueOrNull;
                  final shouldShowDialog = currentState != null &&
                      (currentState.status == DroneStatus.dispatched ||
                       currentState.status == DroneStatus.inTransit ||
                       currentState.status == DroneStatus.approaching);
                  
                  if (shouldShowDialog) {
                    final shouldPop = await _showExitConfirmationDialog(context);
                    if (shouldPop && mounted) {
                      // Cancel drone dispatch
                      ref.read(droneServiceProvider).cancelDispatch();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  } else {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Response',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Drone Tracking',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 30),

          // Emergency Alert Card
          _buildEmergencyCard(currentGlucose),
          const SizedBox(height: 20),

           // Call Emergency Contact Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _callEmergencyContact(),
              icon: const Icon(Icons.phone_in_talk, color: Colors.white),
              label: Text(
                'CALL EMERGENCY CONTACT',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // Red for emergency
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Drone Status Card
          _buildDroneStatusCard(droneState),
          const SizedBox(height: 30),

          // Map/Visualization Area
          _buildMapVisualization(droneState),
          const SizedBox(height: 30),

          // Details Card
          _buildDetailsCard(droneState),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(double glucose) {
    final isCritical = glucose < 70 || glucose > 250;
    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      blur: 10,
      border: Border.all(
        color: Colors.redAccent.withOpacity(0.5),
        width: 2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CRITICAL ALERT',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current Glucose: ${glucose.toStringAsFixed(0)} mg/dL',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    isCritical
                        ? 'Emergency supplies dispatched'
                        : 'Monitoring active',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDroneStatusCard(DroneState droneState) {
    final statusInfo = _getStatusInfo(droneState.status);
    
    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      blur: 10,
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusInfo.icon,
                    color: statusInfo.color,
                    size: 32,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2000.ms, color: statusInfo.color.withOpacity(0.3)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusInfo.title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        statusInfo.subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (droneState.estimatedArrivalMinutes > 0) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Distance',
                    '${(droneState.distance * 1000).toStringAsFixed(0)} m',
                    Icons.location_on,
                  ),
                  _buildStatItem(
                    'ETA',
                    '${droneState.estimatedArrivalMinutes} min',
                    Icons.access_time,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildMapVisualization(DroneState droneState) {
    final droneService = ref.read(droneServiceProvider);
    
    if (!droneService.hasUserLocation || droneService.baseLat == null || droneService.baseLon == null) {
      return GlassContainer(
        height: 300,
        width: double.infinity,
        borderRadius: BorderRadius.circular(20),
        blur: 10,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.white.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Konum alınıyor...',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Markers will be updated automatically via ref.listen in build method

    return GlassContainer(
      height: 300,
      width: double.infinity,
      borderRadius: BorderRadius.circular(20),
      blur: 10,
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Builder(
          builder: (context) {
            try {
              return Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        (droneState.latitude + droneService.userLat!) / 2,
                        (droneState.longitude + droneService.userLon!) / 2,
                      ),
                      zoom: _calculateZoomLevel(droneState.distance),
                      tilt: 0,
                      bearing: 0,
                    ),
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    compassEnabled: true,
                    mapType: MapType.normal,
                    style: _getMapStyle(),
                    markers: droneState.status != DroneStatus.delivered ? {
                      // Drone marker - show even when arrived, only hide when delivered
                      Marker(
                        markerId: const MarkerId('drone'),
                        position: LatLng(droneState.latitude, droneState.longitude),
                        icon: droneState.status == DroneStatus.arrived
                            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                            : _droneIcon,
                        anchor: const Offset(0.5, 1.0), // Bottom center of marker aligns with position
                        infoWindow: InfoWindow(
                          title: droneState.status == DroneStatus.arrived ? 'Drone - Arrived' : 'Drone',
                          snippet: droneState.status == DroneStatus.arrived
                              ? 'At your location'
                              : '${(droneState.distance * 1000).toStringAsFixed(0)} m away',
                        ),
                      ),
                      // User marker - always show
                      Marker(
                        markerId: const MarkerId('user'),
                        position: LatLng(droneService.userLat!, droneService.userLon!),
                        icon: _userIcon,
                        anchor: const Offset(0.5, 1.0), // Bottom center of marker aligns with position
                        infoWindow: InfoWindow(
                          title: 'Your Location',
                          snippet: '${droneService.userLat!.toStringAsFixed(6)}, ${droneService.userLon!.toStringAsFixed(6)}',
                        ),
                      ),
                    } : {
                      // When delivered, only show user marker
                      Marker(
                        markerId: const MarkerId('user'),
                        position: LatLng(droneService.userLat!, droneService.userLon!),
                        icon: _userIcon,
                        anchor: const Offset(0.5, 1.0),
                        infoWindow: InfoWindow(
                          title: 'Your Location',
                          snippet: '${droneService.userLat!.toStringAsFixed(6)}, ${droneService.userLon!.toStringAsFixed(6)}',
                        ),
                      ),
                    },
                    polylines: droneState.status != DroneStatus.delivered ? {
                      // Route line - show even when arrived (distance might be 0)
                      // Only hide when delivered
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: [
                          LatLng(droneState.latitude, droneState.longitude),
                          LatLng(droneService.userLat!, droneService.userLon!),
                        ],
                        color: droneState.status == DroneStatus.arrived 
                            ? Colors.greenAccent 
                            : Colors.cyanAccent,
                        width: 3,
                        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                      ),
                    } : {},
                  ),
                  // Overlay with title (use IgnorePointer to allow map gestures to pass through)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, color: Colors.cyanAccent, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Live Tracking',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } catch (e) {
              // Fallback UI if Google Maps fails (e.g., no API key)
              return _buildMapPlaceholder(droneState);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(DroneState droneState) {
    return Stack(
      children: [
        // Background
        Container(
          color: const Color(0xFF1A1F38),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Live Tracking',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Google Maps API key required',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Drone position indicator (simplified)
        Positioned(
          left: 50 + (droneState.distance * 100),
          top: 150,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyanAccent, width: 2),
            ),
            child: const Icon(
              Icons.flight,
              color: Colors.cyanAccent,
              size: 24,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
              .scale(duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
              .then()
              .scale(duration: 1000.ms, begin: const Offset(1.2, 1.2), end: const Offset(1, 1)),
        ),
        // User position indicator
        Positioned(
          right: 50,
          top: 150,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  String _getMapStyle() {
    // Dark theme map style
    return '''
    [
      {
        "elementType": "geometry",
        "stylers": [{"color": "#1d2c4d"}]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#8ec3b9"}]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#1a3646"}]
      },
      {
        "featureType": "administrative.country",
        "elementType": "geometry.stroke",
        "stylers": [{"color": "#4b6878"}]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#0e1626"}]
      }
    ]
    ''';
  }

  Widget _buildDetailsCard(DroneState droneState) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      blur: 10,
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Details',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Dispatched At',
              droneState.dispatchedAt != null
                  ? '${droneState.dispatchedAt!.hour}:${droneState.dispatchedAt!.minute.toString().padLeft(2, '0')}'
                  : 'N/A',
              Icons.send,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Estimated Arrival',
              droneState.estimatedArrival != null
                  ? '${droneState.estimatedArrival!.hour}:${droneState.estimatedArrival!.minute.toString().padLeft(2, '0')}'
                  : 'Calculating...',
              Icons.schedule,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Drone Coordinates',
              '${droneState.latitude.toStringAsFixed(4)}, ${droneState.longitude.toStringAsFixed(4)}',
              Icons.flight,
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final droneService = ref.read(droneServiceProvider);
                if (droneService.hasUserLocation) {
                  return _buildDetailRow(
                    'Your Location',
                    '${droneService.userLat!.toStringAsFixed(4)}, ${droneService.userLon!.toStringAsFixed(4)}',
                    Icons.person_pin_circle,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            if (droneState.status == DroneStatus.arrived ||
                droneState.status == DroneStatus.delivered) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(droneServiceProvider).markAsDelivered();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Delivery confirmed!',
                          style: GoogleFonts.outfit(),
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'CONFIRM DELIVERY',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => GlassContainer(
        blur: 10,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        borderRadius: BorderRadius.circular(20),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
              const SizedBox(width: 10),
              Text(
                'Cancel Dispatch?',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'If you exit now, the drone dispatch will be cancelled. Are you sure?',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'No, Continue',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Yes, Cancel',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  ({String title, String subtitle, IconData icon, Color color}) _getStatusInfo(DroneStatus status) {
    switch (status) {
      case DroneStatus.preparing:
        return (
          title: 'Preparing',
          subtitle: 'Drone is being prepared',
          icon: Icons.build,
          color: Colors.orangeAccent,
        );
      case DroneStatus.dispatched:
        return (
          title: 'Dispatched',
          subtitle: 'Drone has been sent',
          icon: Icons.send,
          color: Colors.blueAccent,
        );
      case DroneStatus.inTransit:
        return (
          title: 'In Transit',
          subtitle: 'Drone is on the way',
          icon: Icons.flight,
          color: Colors.cyanAccent,
        );
      case DroneStatus.approaching:
        return (
          title: 'Approaching',
          subtitle: 'Drone is near your location',
          icon: Icons.near_me,
          color: Colors.purpleAccent,
        );
      case DroneStatus.arrived:
        return (
          title: 'Arrived',
          subtitle: 'Drone has reached your location',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      case DroneStatus.delivered:
        return (
          title: 'Delivered',
          subtitle: 'Emergency supplies delivered',
          icon: Icons.verified,
          color: Colors.green,
        );
    }
  }

  Future<void> _callEmergencyContact() async {
    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile == null) return;

    final List<dynamic>? contactsList = userProfile['emergencyContacts'];
    final String? legacyNumber = userProfile['emergencyContactNumber'] as String?;

    // Collect all valid contacts
    final List<Map<String, String>> validContacts = [];
    
    if (contactsList != null) {
      for (var c in contactsList) {
        if (c is Map && c['number'] != null && (c['number'] as String).isNotEmpty) {
           validContacts.add({'name': c['name'] ?? 'Contact', 'number': c['number']});
        }
      }
    } else if (legacyNumber != null && legacyNumber.isNotEmpty) {
       validContacts.add({'name': 'Emergency Contact', 'number': legacyNumber});
    }

    if (validContacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('No emergency contact number found.', style: GoogleFonts.outfit()),
            backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Add',
                textColor: Colors.white,
                onPressed: () {
                   context.push('/emergency-contact');
                },
              )
          ),
        );
      }
      return;
    }

    if (validContacts.length == 1) {
      await _launchCaller(validContacts.first['number']!);
    } else {
      // Show selection dialog
      if (mounted) {
        showDialog(
          context: context, 
          builder: (context) => GlassContainer(
            blur: 10,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(20),
            child: AlertDialog(
               backgroundColor: Colors.black.withOpacity(0.8),
               title: Text('Select Contact', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
               content: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: validContacts.map((c) => ListTile(
                   leading: const Icon(Icons.phone, color: Colors.cyanAccent),
                   title: Text(c['name']!, style: GoogleFonts.outfit(color: Colors.white)),
                   subtitle: Text(c['number']!, style: GoogleFonts.outfit(color: Colors.white70)),
                   onTap: () {
                     Navigator.pop(context);
                     _launchCaller(c['number']!);
                   },
                 )).toList(),
               ),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.pop(context),
                   child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white70)),
                 ),
               ],
            ),
          )
        );
      }
    }
  }

  Future<void> _launchCaller(String number) async {
      final sanitizedNumber = number.replaceAll(RegExp(r'\s+'), '');
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: sanitizedNumber,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch dialer for $number', style: GoogleFonts.outfit()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
  }
}

