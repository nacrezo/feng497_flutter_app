import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DroneStatus {
  preparing,
  dispatched,
  inTransit,
  approaching,
  arrived,
  delivered,
}

class DroneState {
  final DroneStatus status;
  final double latitude;
  final double longitude;
  final double distance; // km
  final int estimatedArrivalMinutes;
  final DateTime? dispatchedAt;
  final DateTime? estimatedArrival;

  DroneState({
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.estimatedArrivalMinutes,
    this.dispatchedAt,
    this.estimatedArrival,
  });

  DroneState copyWith({
    DroneStatus? status,
    double? latitude,
    double? longitude,
    double? distance,
    int? estimatedArrivalMinutes,
    DateTime? dispatchedAt,
    DateTime? estimatedArrival,
  }) {
    return DroneState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
    );
  }
}

class DroneService {
  Timer? _updateTimer;
  final Random _random = Random();
  
  // User location (will be set from device GPS)
  double? _userLat;
  double? _userLon;
  
  // Drone base location (dynamically set near user location)
  double? _baseLat;
  double? _baseLon;
  double _initialDistance = 0.0; // Store initial distance for progress-based calculation
  
  // Getters for user location
  double? get userLat => _userLat;
  double? get userLon => _userLon;
  
  // Getters for base location
  double? get baseLat => _baseLat;
  double? get baseLon => _baseLon;
  
  // Set user location and calculate nearby base location
  void setUserLocation(double lat, double lon) {
    _userLat = lat;
    _userLon = lon;
    
    // Set base location ~1.5 km away from user (simulating a nearby drone station)
    // Add ~0.0135 degrees (roughly 1.5 km) in north-east direction
    // This ensures consistent base location relative to user
    _baseLat = lat + 0.0135; // ~1.5 km north
    _baseLon = lon + 0.0135; // ~1.5 km east
  }
  
  // Check if user location is set
  bool get hasUserLocation => _userLat != null && _userLon != null;

  DroneState _currentState = DroneState(
    status: DroneStatus.preparing,
    latitude: 0,
    longitude: 0,
    distance: 0,
    estimatedArrivalMinutes: 0,
  );

  final _stateController = StreamController<DroneState>.broadcast();

  Stream<DroneState> get droneState => _stateController.stream;

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  void dispatchDrone() {
    if (!hasUserLocation || _baseLat == null || _baseLon == null) {
      throw Exception('User location not set. Please get user location first.');
    }
    
    final now = DateTime.now();
    
    // Calculate initial distance
    final initialDistance = _calculateDistance(_baseLat!, _baseLon!, _userLat!, _userLon!);
    
    // Fixed 1 minute delivery time (for testing - emergency response)
    const fixedEtaMinutes = 1;
    final estimatedArrival = now.add(const Duration(minutes: fixedEtaMinutes));
    
    _currentState = DroneState(
      status: DroneStatus.dispatched,
      latitude: _baseLat!,
      longitude: _baseLon!,
      distance: initialDistance,
      estimatedArrivalMinutes: fixedEtaMinutes,
      dispatchedAt: now,
      estimatedArrival: estimatedArrival,
    );
    
    // Store initial distance for progress-based distance calculation
    _initialDistance = initialDistance;
    
    _stateController.add(_currentState);
    
    // Start simulation - update more frequently for smoother movement
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _simulateDroneMovement();
    });
  }

  void _simulateDroneMovement() {
    if (_currentState.status == DroneStatus.delivered || !hasUserLocation) {
      _updateTimer?.cancel();
      return;
    }

    double newLat = _currentState.latitude;
    double newLon = _currentState.longitude;
    DroneStatus newStatus = _currentState.status;
    int newEta = _currentState.estimatedArrivalMinutes;

    // Move drone towards user location
    // Calculate TOTAL difference from base to user (fixed vector)
    final latDiff = _userLat! - _baseLat!;
    final lonDiff = _userLon! - _baseLon!;
    
    // Calculate total distance to travel
    final totalDistance = _calculateDistance(_baseLat!, _baseLon!, _userLat!, _userLon!);
    
    // Calculate how much time has passed since dispatch
    final timeElapsed = _currentState.dispatchedAt != null
        ? DateTime.now().difference(_currentState.dispatchedAt!).inSeconds
        : 0;
    
    // Total time for delivery: 1 minute (60 seconds) - for testing
    const totalTimeSeconds = 60;
    
    // Calculate progress (0.0 to 1.0) - use precise calculation
    final progress = (timeElapsed / totalTimeSeconds).clamp(0.0, 1.0);
    
    // Always move drone based on progress (linear interpolation)
    // This ensures smooth movement from base to user location
    newLat = _baseLat! + (latDiff * progress);
    newLon = _baseLon! + (lonDiff * progress);

    // Calculate distance based on progress (not actual position)
    // This ensures distance always decreases smoothly without fluctuations
    final newDistance = _initialDistance * (1.0 - progress);
    
    // Calculate remaining ETA (based on fixed 1 minute delivery)
    final remainingSeconds = totalTimeSeconds - timeElapsed;
    newEta = max(0, (remainingSeconds / 60).round());
    
    // Update status based on progress only (not distance to avoid fluctuations)
    // This prevents status changes from affecting position calculation
    if (progress >= 1.0) {
      // Time elapsed - ensure exact position match
      newStatus = DroneStatus.arrived;
      newEta = 0;
      newLat = _userLat!;
      newLon = _userLon!;
    } else if (progress > 0.85) { // 85% of the way
      newStatus = DroneStatus.approaching;
    } else if (progress > 0.3) { // 30% of the way
      newStatus = DroneStatus.inTransit;
    } else {
      newStatus = DroneStatus.inTransit;
    }

    // Update estimated arrival time (fixed 1 minute from dispatch)
    final now = DateTime.now();
    final updatedEstimatedArrival = _currentState.dispatchedAt != null
        ? _currentState.dispatchedAt!.add(const Duration(minutes: 1))
        : now.add(const Duration(minutes: 1));

    _currentState = _currentState.copyWith(
      status: newStatus,
      latitude: newLat,
      longitude: newLon,
      distance: newDistance,
      estimatedArrivalMinutes: newEta,
      estimatedArrival: updatedEstimatedArrival,
    );

    _stateController.add(_currentState);
  }

  void markAsDelivered() {
    _currentState = _currentState.copyWith(
      status: DroneStatus.delivered,
      distance: 0,
      estimatedArrivalMinutes: 0,
    );
    _stateController.add(_currentState);
    _updateTimer?.cancel();
  }

  void cancelDispatch() {
    _updateTimer?.cancel();
    _currentState = DroneState(
      status: DroneStatus.preparing,
      latitude: _baseLat ?? 0,
      longitude: _baseLon ?? 0,
      distance: 0,
      estimatedArrivalMinutes: 0,
    );
    _stateController.add(_currentState);
  }

  void reset() {
    _updateTimer?.cancel();
    final distance = (hasUserLocation && _baseLat != null && _baseLon != null)
        ? _calculateDistance(_baseLat!, _baseLon!, _userLat!, _userLon!)
        : 0.0;
    _currentState = DroneState(
      status: DroneStatus.preparing,
      latitude: _baseLat ?? 0,
      longitude: _baseLon ?? 0,
      distance: distance,
      estimatedArrivalMinutes: 0,
    );
    _stateController.add(_currentState);
  }

  void dispose() {
    _updateTimer?.cancel();
    _stateController.close();
  }
}

final droneServiceProvider = Provider<DroneService>((ref) {
  final service = DroneService();
  ref.onDispose(() => service.dispose());
  return service;
});

final droneStateProvider = StreamProvider<DroneState>((ref) {
  final service = ref.watch(droneServiceProvider);
  return service.droneState;
});

