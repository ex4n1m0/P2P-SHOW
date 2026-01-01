# P2P Mobile Grid - Cross-Platform Location Sharing App

A Flutter-based mobile application that enables users to share their geolocation with nearby devices (within 1km range) and creates a combined visual display across multiple screens. Each device's screen becomes part of a collaborative grid visualization.

## Features

- **Real-time Geolocation Sharing**: Share your position with nearby devices (1km range)
- **Peer-to-Peer Communication**: Uses WebRTC for direct device-to-device connections
- **Collaborative Visual Display**: Screens combine to create a single visual representation
- **Dynamic Grid Visualization**: Device positions mapped to colored rectangles in a shared grid
- **Cross-Platform**: Runs on both iOS and Android
- **No Central Server Required**: True P2P architecture for data transfer

## Architecture

```
lib/
├── main.dart              # App entry point
├── models/
│   └── device_position.dart  # Data model for device positions
├── services/
│   ├── location_service.dart # Geolocation handling
│   └── p2p_service.dart      # WebRTC P2P communication
├── providers/
│   └── grid_provider.dart    # Grid visualization logic
├── screens/
│   └── home_screen.dart      # Main UI screen
└── widgets/
    └── grid_display.dart     # Custom grid visualization widget
```

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (version 3.0.0 or higher)
2. **Android Studio** (for Android development)
3. **Xcode** (for iOS development, macOS only)
4. **Java Development Kit** (JDK 11 or higher)
5. **CocoaPods** (for iOS, macOS only)

## Installation

### Step 1: Install Flutter

If you haven't installed Flutter yet, follow these steps:

#### Windows:
```bash
# Download Flutter SDK
# Extract to a location (e.g., C:\src\flutter)
# Add to PATH: C:\src\flutter\bin

# Verify installation
flutter --version
```

#### macOS:
```bash
# Using Homebrew
brew install --cask flutter

# Or manual installation
# Download and extract to ~/Development/flutter
# Add to PATH: export PATH="$PATH:$HOME/Development/flutter/bin"
```

#### Linux:
```bash
# Download and extract Flutter SDK
sudo snap install flutter --classic
```

### Step 2: Clone and Setup Project

```bash
# Navigate to project directory
cd mobile_grid_app

# Install dependencies
flutter pub get

# For iOS (macOS only)
cd ios
pod install
cd ..
```

### Step 3: Configure Platform-Specific Settings

#### Android:
- Ensure you have an Android emulator or physical device
- Android Studio → AVD Manager → Create Virtual Device
- Required: API level 21 or higher

#### iOS (macOS only):
- Open `ios/Runner.xcworkspace` in Xcode
- Select your development team in Signing & Capabilities
- Set Bundle Identifier to unique value

### Step 4: Run the Application

```bash
# Check connected devices
flutter devices

# Run on connected device/emulator
flutter run

# Or specify platform
flutter run -d android
flutter run -d ios
```

## Usage Guide

### 1. Start Location Tracking
- Tap the "Location Tracking" switch to enable
- Grant location permissions when prompted
- Your current position will be displayed

### 2. Connect with Nearby Devices
- The app automatically searches for nearby devices
- WebRTC establishes P2P connections
- Connected devices appear in the "Peers connected" count

### 3. View Collaborative Grid
- Devices within 1km range appear on the grid
- Each device is represented by a colored rectangle
- Rectangle size adapts based on number of connected devices
- Device positions are relative to their actual geographical locations

### 4. Monitor Status
- Location accuracy and coordinates
- P2P connection status
- Number of connected devices
- Grid coverage area

## Technical Implementation

### Geolocation Service
- Uses `geolocator` package for precise location tracking
- Implements distance calculation within 1km range
- Handles permission requests for both Android and iOS

### P2P Communication
- Built with `flutter_webrtc` for true peer-to-peer connections
- Uses STUN servers for NAT traversal
- Implements data channels for position broadcasting
- Automatic peer discovery and connection management

### Grid Visualization
- Custom `CustomPainter` for efficient rendering
- Dynamic scaling based on device count
- Color-coded device representation
- Real-time position updates

## Permissions

### Android:
- `ACCESS_FINE_LOCATION` - Precise geolocation
- `ACCESS_COARSE_LOCATION` - Approximate location
- `ACCESS_BACKGROUND_LOCATION` - Background tracking
- `INTERNET` - Network communication
- `CAMERA` & `RECORD_AUDIO` - WebRTC requirements

### iOS:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test
```

### Manual Testing
1. Install on multiple devices (minimum 2)
2. Enable location services on all devices
3. Move devices within 1km range
4. Verify grid visualization updates in real-time

## Building for Release

### Android:
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS (macOS only):
```bash
flutter build ios --release
# Open Xcode to archive and distribute
```

## Troubleshooting

### Common Issues:

1. **Location permissions not granted**
   - Check app permissions in device settings
   - Restart app after granting permissions

2. **Devices not connecting**
   - Ensure both devices have internet access
   - Check firewall/network restrictions
   - Verify devices are within 1km range

3. **Build errors**
   - Run `flutter clean` and `flutter pub get`
   - Delete `ios/Podfile.lock` and run `pod install`
   - Ensure Flutter channel is stable: `flutter channel stable`

4. **WebRTC connection issues**
   - Check STUN server accessibility
   - Verify microphone/camera permissions
   - Test on different network types (WiFi vs Mobile)

### Debugging:
```bash
# Enable verbose logging
flutter run --verbose

# Check dependencies
flutter pub deps

# Analyze code
flutter analyze
```

## Performance Optimization

- Grid rendering optimized with `CustomPaint`
- Location updates throttled to 5-meter intervals
- Efficient state management with `Provider`
- Memory-efficient device position tracking
- Background location updates with minimal battery impact

## Future Enhancements

1. **Advanced Visualization**: More complex visual patterns
2. **Extended Range**: Configurable distance parameters
3. **Offline Mode**: Local storage of position history
4. **Social Features**: User profiles and messaging
5. **Advanced Filtering**: Device filtering by type or group

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing cross-platform framework
- WebRTC community for peer-to-peer technology
- Geolocator and permission_handler package maintainers
- All open-source contributors

## Support

For issues and questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Search existing GitHub issues
3. Create a new issue with detailed description

---

**Note**: This app requires actual mobile devices or emulators with location services enabled. For testing with multiple devices, ensure they are physically close (within 1km) or simulate locations on emulators.
