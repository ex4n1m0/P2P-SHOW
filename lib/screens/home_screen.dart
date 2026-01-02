import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/p2p_service.dart';
import '../providers/grid_provider.dart';
import '../models/device_position.dart';
import '../widgets/grid_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _broadcastTimer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final p2pService = Provider.of<P2PService>(context, listen: false);
    await p2pService.initialize();
  }

  void _startBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _broadcastPosition();
    });
  }

  void _stopBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
  }

  void _broadcastPosition() {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final p2pService = Provider.of<P2PService>(context, listen: false);
    final gridProvider = Provider.of<GridProvider>(context, listen: false);

    if (locationService.currentPosition != null) {
      final position = DevicePosition(
        deviceId: p2pService.deviceId,
        latitude: locationService.currentPosition!.latitude,
        longitude: locationService.currentPosition!.longitude,
        timestamp: DateTime.now(),
        color: gridProvider.generateDeviceColor(p2pService.deviceId),
      );

      // Update own position in grid
      gridProvider.updateDevice(p2pService.deviceId, position);

      // Broadcast to peers
      p2pService.broadcastPosition(position);

      // Update grid with peer positions and filter by range
      final peerDevices = p2pService.connectedDevices;
      final devicesInRange = locationService.filterDevicesInRange(
        peerDevices.values.toList(),
        rangeInMeters: 1000,
      );

      // Update grid with filtered devices
      for (var device in devicesInRange) {
        gridProvider.updateDevice(device.deviceId, device);
      }

      // Remove devices that are no longer in range
      for (var deviceId in gridProvider.devices.keys.toList()) {
        if (deviceId != p2pService.deviceId &&
            !devicesInRange.any((d) => d.deviceId == deviceId)) {
          gridProvider.removeDevice(deviceId);
        }
      }
    }
  }

  @override
  void dispose() {
    _stopBroadcasting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Mobile Grid'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Grid Display
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: const GridDisplay(),
            ),
          ),

          // Control Panel
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLocationSection(),
                    const SizedBox(height: 16),
                    _buildP2PSection(),
                    const SizedBox(height: 16),
                    _buildDeviceInfo(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Location Tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: locationService.isTracking,
                      onChanged: (value) async {
                        if (value) {
                          await locationService.startTracking();
                          _startBroadcasting();
                        } else {
                          locationService.stopTracking();
                          _stopBroadcasting();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  locationService.statusMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (locationService.currentPosition != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${locationService.currentPosition!.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Lon: ${locationService.currentPosition!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Accuracy: ${locationService.currentPosition!.accuracy.toStringAsFixed(1)}m',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildP2PSection() {
    return Consumer<P2PService>(
      builder: (context, p2pService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'P2P Connection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p2pService.isRunning ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        p2pService.isRunning ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Peers connected: ${p2pService.peerCount}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  p2pService.statusMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Device ID: ${p2pService.deviceId.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceInfo() {
    return Consumer<GridProvider>(
      builder: (context, gridProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grid Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Devices in grid: ${gridProvider.deviceCount}',
                  style: const TextStyle(fontSize: 12),
                ),
                const Text(
                  'Range: 1km radius',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (gridProvider.gridBounds != null) ...[
                  Text(
                    'Coverage:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'Lat: ${(gridProvider.gridBounds!.latitudeRange * 111).toStringAsFixed(0)}m',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    'Lon: ${(gridProvider.gridBounds!.longitudeRange * 111).toStringAsFixed(0)}m',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
