import 'package:flutter/material.dart';

class DevicePosition {
  final String deviceId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final Color color;
  
  DevicePosition({
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'color': color.value,
    };
  }

  factory DevicePosition.fromJson(Map<String, dynamic> json) {
    return DevicePosition(
      deviceId: json['deviceId'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      color: Color(json['color'] as int),
    );
  }

  DevicePosition copyWith({
    String? deviceId,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    Color? color,
  }) {
    return DevicePosition(
      deviceId: deviceId ?? this.deviceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      color: color ?? this.color,
    );
  }
}
