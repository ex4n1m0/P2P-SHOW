import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/device_position.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionSubscription;
  String _statusMessage = 'Location tracking inactive';

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  String get statusMessage => _statusMessage;

  /// Request location permissions
  Future<bool> requestPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _statusMessage = 'Location services are disabled';
      notifyListeners();
      return false;
    }

    // Request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _statusMessage = 'Location permissions denied';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _statusMessage = 'Location permissions permanently denied';
      notifyListeners();
      return false;
    }

    _statusMessage = 'Location permissions granted';
    notifyListeners();
    return true;
  }

  /// Start tracking location
  Future<void> startTracking() async {
    if (_isTracking) return;

    bool hasPermission = await requestPermissions();
    if (!hasPermission) return;

    _isTracking = true;
    _statusMessage = 'Tracking location...';
    notifyListeners();

    // Get initial position
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Error getting location: $e';
      notifyListeners();
    }

    // Start listening to position updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentPosition = position;
        _statusMessage = 'Location updated: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        notifyListeners();
      },
      onError: (error) {
        _statusMessage = 'Location error: $error';
        notifyListeners();
      },
    );
  }

  /// Stop tracking location
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    _statusMessage = 'Location tracking stopped';
    notifyListeners();
  }

  /// Calculate distance between two positions in meters
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if a device is within 1km range
  bool isWithinRange(DevicePosition devicePosition, {double rangeInMeters = 1000}) {
    if (_currentPosition == null) return false;
    
    double distance = calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      devicePosition.latitude,
      devicePosition.longitude,
    );
    
    return distance <= rangeInMeters;
  }

  /// Filter devices within 1km range
  List<DevicePosition> filterDevicesInRange(
    List<DevicePosition> devices, {
    double rangeInMeters = 1000,
  }) {
    if (_currentPosition == null) return [];
    
    return devices.where((device) {
      double distance = calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        device.latitude,
        device.longitude,
      );
      return distance <= rangeInMeters;
    }).toList();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
