import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
import '../models/device_position.dart';

class P2PService extends ChangeNotifier {
  final String _deviceId = const Uuid().v4();
  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  final Map<String, DevicePosition> _connectedDevices = {};
  
  bool _isRunning = false;
  String _statusMessage = 'P2P service inactive';
  
  // WebRTC configuration
  final Map<String, dynamic> _rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  final Map<String, dynamic> _dataChannelConstraints = {
    'ordered': true,
  };

  String get deviceId => _deviceId;
  bool get isRunning => _isRunning;
  String get statusMessage => _statusMessage;
  Map<String, DevicePosition> get connectedDevices => _connectedDevices;
  int get peerCount => _peers.length;

  /// Initialize P2P service
  Future<void> initialize() async {
    if (_isRunning) return;
    
    _isRunning = true;
    _statusMessage = 'P2P service initialized';
    notifyListeners();
  }

  /// Create a peer connection for a new device
  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    final peerConnection = await createPeerConnection(_rtcConfiguration);
    
    // Handle ICE candidates
    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      _handleIceCandidate(peerId, candidate);
    };

    // Handle connection state changes
    peerConnection.onConnectionState = (RTCPeerConnectionState state) {
      _handleConnectionStateChange(peerId, state);
    };

    // Handle ICE connection state changes
    peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      _handleIceConnectionStateChange(peerId, state);
    };

    _peers[peerId] = peerConnection;
    return peerConnection;
  }

  /// Create offer to connect to a peer
  Future<Map<String, dynamic>> createOffer(String peerId) async {
    try {
      final peerConnection = await _createPeerConnection(peerId);
      
      // Create data channel
      final dataChannel = await peerConnection.createDataChannel(
        'positionData',
        RTCDataChannelInit()..ordered = true,
      );
      
      _setupDataChannel(peerId, dataChannel);
      _dataChannels[peerId] = dataChannel;

      // Create offer
      final offer = await peerConnection.createOffer();
      await peerConnection.setLocalDescription(offer);

      return {
        'type': 'offer',
        'sdp': offer.sdp,
        'from': _deviceId,
        'to': peerId,
      };
    } catch (e) {
      _statusMessage = 'Error creating offer: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Handle incoming offer
  Future<Map<String, dynamic>> handleOffer(Map<String, dynamic> offerData) async {
    try {
      final peerId = offerData['from'] as String;
      final peerConnection = await _createPeerConnection(peerId);

      // Handle data channel from peer
      peerConnection.onDataChannel = (RTCDataChannel dataChannel) {
        _setupDataChannel(peerId, dataChannel);
        _dataChannels[peerId] = dataChannel;
      };

      // Set remote description
      await peerConnection.setRemoteDescription(
        RTCSessionDescription(offerData['sdp'], 'offer'),
      );

      // Create answer
      final answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      return {
        'type': 'answer',
        'sdp': answer.sdp,
        'from': _deviceId,
        'to': peerId,
      };
    } catch (e) {
      _statusMessage = 'Error handling offer: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Handle incoming answer
  Future<void> handleAnswer(Map<String, dynamic> answerData) async {
    try {
      final peerId = answerData['from'] as String;
      final peerConnection = _peers[peerId];
      
      if (peerConnection != null) {
        await peerConnection.setRemoteDescription(
          RTCSessionDescription(answerData['sdp'], 'answer'),
        );
      }
    } catch (e) {
      _statusMessage = 'Error handling answer: $e';
      notifyListeners();
    }
  }

  /// Handle ICE candidate
  Future<void> handleIceCandidate(Map<String, dynamic> candidateData) async {
    try {
      final peerId = candidateData['from'] as String;
      final peerConnection = _peers[peerId];
      
      if (peerConnection != null && candidateData['candidate'] != null) {
        await peerConnection.addCandidate(
          RTCIceCandidate(
            candidateData['candidate'],
            candidateData['sdpMid'],
            candidateData['sdpMLineIndex'],
          ),
        );
      }
    } catch (e) {
      _statusMessage = 'Error handling ICE candidate: $e';
      notifyListeners();
    }
  }

  /// Setup data channel
  void _setupDataChannel(String peerId, RTCDataChannel dataChannel) {
    dataChannel.onMessage = (RTCDataChannelMessage message) {
      _handleDataChannelMessage(peerId, message);
    };

    dataChannel.onDataChannelState = (RTCDataChannelState state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _statusMessage = 'Data channel open with $peerId';
        notifyListeners();
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        _statusMessage = 'Data channel closed with $peerId';
        _connectedDevices.remove(peerId);
        notifyListeners();
      }
    };
  }

  /// Handle data channel message
  void _handleDataChannelMessage(String peerId, RTCDataChannelMessage message) {
    try {
      final data = jsonDecode(message.text);
      if (data['type'] == 'position') {
        final devicePosition = DevicePosition.fromJson(data['data']);
        _connectedDevices[peerId] = devicePosition;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error parsing message from $peerId: $e');
    }
  }

  /// Broadcast position to all peers
  void broadcastPosition(DevicePosition position) {
    final message = jsonEncode({
      'type': 'position',
      'data': position.toJson(),
    });

    for (var entry in _dataChannels.entries) {
      final dataChannel = entry.value;
      if (dataChannel.state == RTCDataChannelState.RTCDataChannelOpen) {
        try {
          dataChannel.send(RTCDataChannelMessage(message));
        } catch (e) {
          debugPrint('Error sending to ${entry.key}: $e');
        }
      }
    }
  }

  /// Handle ICE candidate internally
  void _handleIceCandidate(String peerId, RTCIceCandidate candidate) {
    // In a real implementation, you would send this to a signaling server
    // For now, we'll just log it
    debugPrint('ICE Candidate for $peerId: ${candidate.toMap()}');
  }

  /// Handle connection state change
  void _handleConnectionStateChange(String peerId, RTCPeerConnectionState state) {
    _statusMessage = 'Connection with $peerId: $state';
    notifyListeners();
    
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      _cleanupPeer(peerId);
    }
  }

  /// Handle ICE connection state change
  void _handleIceConnectionStateChange(String peerId, RTCIceConnectionState state) {
    debugPrint('ICE connection with $peerId: $state');
    
    if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
        state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
      _cleanupPeer(peerId);
    }
  }

  /// Cleanup peer connection
  void _cleanupPeer(String peerId) {
    _dataChannels[peerId]?.close();
    _dataChannels.remove(peerId);
    _peers[peerId]?.close();
    _peers.remove(peerId);
    _connectedDevices.remove(peerId);
    notifyListeners();
  }

  /// Disconnect from a specific peer
  Future<void> disconnectPeer(String peerId) async {
    _cleanupPeer(peerId);
    _statusMessage = 'Disconnected from $peerId';
    notifyListeners();
  }

  /// Shutdown P2P service
  Future<void> shutdown() async {
    for (var peerId in _peers.keys.toList()) {
      await disconnectPeer(peerId);
    }
    
    _isRunning = false;
    _statusMessage = 'P2P service stopped';
    notifyListeners();
  }

  @override
  void dispose() {
    shutdown();
    super.dispose();
  }
}
