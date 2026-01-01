import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/device_position.dart';

class GridProvider extends ChangeNotifier {
  final Map<String, DevicePosition> _devices = {};
  GridBounds? _gridBounds;
  Timer? _updateTimer;
  
  Map<String, DevicePosition> get devices => _devices;
  GridBounds? get gridBounds => _gridBounds;
  int get deviceCount => _devices.length;

  /// Add or update a device position
  void updateDevice(String deviceId, DevicePosition position) {
    _devices[deviceId] = position;
    _recalculateGridBounds();
    notifyListeners();
  }

  /// Remove a device
  void removeDevice(String deviceId) {
    _devices.remove(deviceId);
    _recalculateGridBounds();
    notifyListeners();
  }

  /// Add multiple devices
  void updateDevices(Map<String, DevicePosition> devices) {
    _devices.addAll(devices);
    _recalculateGridBounds();
    notifyListeners();
  }

  /// Clear all devices
  void clearDevices() {
    _devices.clear();
    _gridBounds = null;
    notifyListeners();
  }

  /// Recalculate grid bounds based on all device positions
  void _recalculateGridBounds() {
    if (_devices.isEmpty) {
      _gridBounds = null;
      return;
    }

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLon = double.infinity;
    double maxLon = double.negativeInfinity;

    for (var device in _devices.values) {
      minLat = min(minLat, device.latitude);
      maxLat = max(maxLat, device.latitude);
      minLon = min(minLon, device.longitude);
      maxLon = max(maxLon, device.longitude);
    }

    _gridBounds = GridBounds(
      minLatitude: minLat,
      maxLatitude: maxLat,
      minLongitude: minLon,
      maxLongitude: maxLon,
    );
  }

  /// Get relative position of a device in the grid (0-1 range)
  Offset? getRelativePosition(String deviceId) {
    if (_gridBounds == null || !_devices.containsKey(deviceId)) {
      return null;
    }

    final device = _devices[deviceId]!;
    final bounds = _gridBounds!;

    // Handle case where all devices are at the same location
    final latRange = bounds.maxLatitude - bounds.minLatitude;
    final lonRange = bounds.maxLongitude - bounds.minLongitude;

    double relativeX;
    double relativeY;

    if (lonRange == 0) {
      relativeX = 0.5; // Center if all at same longitude
    } else {
      relativeX = (device.longitude - bounds.minLongitude) / lonRange;
    }

    if (latRange == 0) {
      relativeY = 0.5; // Center if all at same latitude
    } else {
      // Invert Y because latitude increases northward but screen Y increases downward
      relativeY = 1.0 - (device.latitude - bounds.minLatitude) / latRange;
    }

    return Offset(relativeX, relativeY);
  }

  /// Start periodic updates for animation/refresh
  void startPeriodicUpdates({Duration interval = const Duration(milliseconds: 100)}) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(interval, (_) {
      notifyListeners();
    });
  }

  /// Stop periodic updates
  void stopPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Generate a random color for a device
  Color generateDeviceColor(String deviceId) {
    final hash = deviceId.hashCode;
    final random = Random(hash);
    return Color.fromARGB(
      255,
      100 + random.nextInt(156), // 100-255 for better visibility
      100 + random.nextInt(156),
      100 + random.nextInt(156),
    );
  }

  @override
  void dispose() {
    stopPeriodicUpdates();
    super.dispose();
  }
}

class GridBounds {
  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;

  GridBounds({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });

  double get latitudeRange => maxLatitude - minLatitude;
  double get longitudeRange => maxLongitude - minLongitude;
  
  double get centerLatitude => (minLatitude + maxLatitude) / 2;
  double get centerLongitude => (minLongitude + maxLongitude) / 2;
}
