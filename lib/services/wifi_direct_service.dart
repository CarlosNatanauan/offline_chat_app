// services/wifi_direct_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:offline_chat_app/models/caflow_models.dart';
import 'package:offline_chat_app/services/wifi_direct_protocol.dart';
import 'package:nearby_connections/nearby_connections.dart';

/// WiFi Direct P2P Service - Handles peer discovery and messaging
class WiFiDirectService {
  static final WiFiDirectService _instance = WiFiDirectService._internal();
  factory WiFiDirectService() => _instance;
  WiFiDirectService._internal();

  final Nearby _nearby = Nearby();
  
  bool _initialized = false;
  
  // Streams
  final StreamController<List<CaflowDevice>> _devicesController =
      StreamController<List<CaflowDevice>>.broadcast();
  Stream<List<CaflowDevice>> get devicesStream => _devicesController.stream;

  final StreamController<String> _messagesController =
      StreamController<String>.broadcast();
  Stream<String> get messagesStream => _messagesController.stream;

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  // State
  final Map<String, CaflowDevice> _discoveredDevices = {};
  String? _connectedEndpointId;
  bool _isDiscovering = false;
  bool _isAdvertising = false;
  
  //Track if we're actually ready to send messages
  bool _connectionStable = false;

  // Strategy and service ID
  final Strategy _strategy = Strategy.P2P_POINT_TO_POINT;
  static const String SERVICE_ID = "com.caflow.offline_chat";

  // Control callbacks
  void Function(String remoteName)? _onChatRequestReceived;
  void Function(String remoteName)? _onChatAccepted;
  void Function(String remoteName)? _onChatDeclined;

  set onChatRequestReceived(void Function(String remoteName)? cb) {
    _onChatRequestReceived = cb;
  }

  set onChatAccepted(void Function(String remoteName)? cb) {
    _onChatAccepted = cb;
  }

  set onChatDeclined(void Function(String remoteName)? cb) {
    _onChatDeclined = cb;
  }

  // =========================================================
  // INITIALIZATION
  // =========================================================
  Future<bool> initialize(String userName) async {
    if (_initialized) {
      print("ℹ️ WiFiDirectService already initialized");
      return true;
    }

    try {
      print("🧹 Resetting Nearby state (stopAllEndpoints / stopAdvertising / stopDiscovery)...");
      try {
        await _nearby.stopAllEndpoints();
        await _nearby.stopAdvertising();
        await _nearby.stopDiscovery();
      } catch (e) {
        print("⚠️ Nearby reset error (ignored): $e");
      }

      _updateStatus(ConnectionStatus.ready);
      _initialized = true;
      print("✅ WiFi Direct initialized (clean state)");
      return true;
    } catch (e) {
      print("❌ WiFi Direct init error: $e");
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }

  // =========================================================
  // DISCOVERY
  // =========================================================
  Future<void> startDiscovery(String userName) async {
    if (_isDiscovering) {
      print("⚠️ Already discovering");
      return;
    }

    try {
      _discoveredDevices.clear();
      _devicesController.add([]);
      _isDiscovering = true;

      print("🔍 Starting discovery...");

      await _nearby.startDiscovery(
        userName,
        _strategy,
        onEndpointFound: (endpointId, name, serviceId) {
          print("✅ Found device: $name ($endpointId)");
          
          if (serviceId == SERVICE_ID) {
            final device = CaflowDevice(
              name: name,
              address: endpointId,
            );
            
            _discoveredDevices[endpointId] = device;
            _devicesController.add(_discoveredDevices.values.toList());
          }
        },
        onEndpointLost: (endpointId) {
          print("⚠️ Lost device: $endpointId");
          _discoveredDevices.remove(endpointId);
          _devicesController.add(_discoveredDevices.values.toList());
        },
        serviceId: SERVICE_ID,
      );

      _updateStatus(ConnectionStatus.discovering);
      print("✅ Discovery started");
    } on PlatformException catch (e) {
      final msg = e.message ?? '';
      if (msg.contains('STATUS_ALREADY_DISCOVERING')) {
        print("ℹ️ Native is already discovering");
        _isDiscovering = true;
        _updateStatus(ConnectionStatus.discovering);
        return;
      }

      print("❌ Discovery error: $e");
      _isDiscovering = false;
      _updateStatus(ConnectionStatus.error);
    } catch (e) {
      print("❌ Discovery error: $e");
      _isDiscovering = false;
      _updateStatus(ConnectionStatus.error);
    }
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;

    try {
      await _nearby.stopDiscovery();
      _isDiscovering = false;
      print("🛑 Discovery stopped");
    } catch (e) {
      print("⚠️ Stop discovery error: $e");
    }
  }

  // =========================================================
  // ADVERTISING
  // =========================================================
  Future<void> startAdvertising(String userName) async {
    if (_isAdvertising) {
      print("⚠️ Already advertising");
      return;
    }

    try {
      print("📡 Starting advertising...");

      await _nearby.startAdvertising(
        userName,
        _strategy,
        onConnectionInitiated: (endpointId, info) {
          print("🔗 Connection initiated with: ${info.endpointName}");
          
          // Stop discovery when someone connects to us
          if (_isDiscovering) {
            stopDiscovery();
          }
          
          _nearby.acceptConnection(
            endpointId,
            onPayLoadRecieved: (endpointId, payload) {
              _handleIncomingPayload(endpointId, payload);
            },
            onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {
              // Handle transfer updates if needed
            },
          );
        },
        onConnectionResult: (endpointId, status) {
          if (status == Status.CONNECTED) {
            print("✅ Connected to: $endpointId");
            _connectedEndpointId = endpointId;
            
            // Wait a bit for connection to stabilize
            Future.delayed(const Duration(milliseconds: 500), () {
              _connectionStable = true;
              _updateStatus(ConnectionStatus.connected);
              print("✅ Connection stable");
            });
          } else {
            print("⚠️ Connection failed: $status");
            _connectionStable = false;
            _updateStatus(ConnectionStatus.disconnected);
          }
        },
        onDisconnected: (endpointId) {
          print("🔌 Disconnected from: $endpointId");
          _connectedEndpointId = null;
          _connectionStable = false;
          _updateStatus(ConnectionStatus.disconnected);
        },
        serviceId: SERVICE_ID,
      );

      _isAdvertising = true;
      _updateStatus(ConnectionStatus.advertising);
      print("✅ Advertising started");
    } on PlatformException catch (e) {
      final msg = e.message ?? '';
      if (msg.contains('STATUS_ALREADY_ADVERTISING')) {
        print("ℹ️ Native is already advertising");
        _isAdvertising = true;
        _updateStatus(ConnectionStatus.advertising);
        return;
      }

      print("❌ Advertising error: $e");
      _isAdvertising = false;
      _updateStatus(ConnectionStatus.error);
    } catch (e) {
      print("❌ Advertising error: $e");
      _isAdvertising = false;
      _updateStatus(ConnectionStatus.error);
    }
  }

  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;

    try {
      await _nearby.stopAdvertising();
      _isAdvertising = false;
      print("🛑 Advertising stopped");
    } catch (e) {
      print("⚠️ Stop advertising error: $e");
    }
  }

  // =========================================================
  // CONNECTION
  // =========================================================
  Future<bool> connectToDevice(CaflowDevice device, String userName) async {
    try {
      print("🔄 Connecting to ${device.name}...");
      _updateStatus(ConnectionStatus.connecting);

      // Stop discovery before connecting
      if (_isDiscovering) {
        await stopDiscovery();
      }

      final completer = Completer<bool>();

      await _nearby.requestConnection(
        userName,
        device.address,
        onConnectionInitiated: (endpointId, info) {
          print("🔗 Connection initiated with: ${info.endpointName}");
          
          _nearby.acceptConnection(
            endpointId,
            onPayLoadRecieved: (endpointId, payload) {
              _handleIncomingPayload(endpointId, payload);
            },
            onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {
              // Handle transfer updates
            },
          );
        },
        onConnectionResult: (endpointId, status) {
          if (status == Status.CONNECTED) {
            print("✅ Connected successfully!");
            _connectedEndpointId = endpointId;
            
            // Wait for connection to stabilize before saying we're ready
            Future.delayed(const Duration(milliseconds: 500), () {
              _connectionStable = true;
              _updateStatus(ConnectionStatus.connected);
              completer.complete(true);
              print("✅ Connection stable and ready");
            });
          } else {
            print("⚠️ Connection failed: $status");
            _connectionStable = false;
            _updateStatus(ConnectionStatus.disconnected);
            completer.complete(false);
          }
        },
        onDisconnected: (endpointId) {
          print("🔌 Disconnected");
          _connectedEndpointId = null;
          _connectionStable = false;
          _updateStatus(ConnectionStatus.disconnected);
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print("⏱️ Connection timeout");
          _connectionStable = false;
          _updateStatus(ConnectionStatus.disconnected);
          return false;
        },
      );
    } catch (e) {
      print("❌ Connection error: $e");
      _connectionStable = false;
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }

  // =========================================================
  // MESSAGING
  // =========================================================
  void _handleIncomingPayload(String endpointId, Payload payload) {
    try {
      if (payload.type == PayloadType.BYTES) {
        final bytes = payload.bytes;
        if (bytes != null) {
          final message = utf8.decode(bytes);
          print("📩 Received: $message");

          // Check for control messages
          final ctrl = WiFiControlMessage.tryParse(message);
          if (ctrl != null) {
            switch (ctrl.type) {
              case WiFiControlType.chatRequest:
                _onChatRequestReceived?.call(ctrl.fromName);
                break;
              case WiFiControlType.chatAccept:
                _onChatAccepted?.call(ctrl.fromName);
                break;
              case WiFiControlType.chatDecline:
                _onChatDeclined?.call(ctrl.fromName);
                break;
            }
            return;
          }

          // Normal chat message
          _messagesController.add(message);
        }
      }
    } catch (e) {
      print("⚠️ Payload decode error: $e");
    }
  }

  Future<bool> sendMessage(String message) async {
    if (_connectedEndpointId == null) {
      print("⚠️ Not connected");
      _updateStatus(ConnectionStatus.disconnected);
      return false;
    }

    // Wait for connection to be stable before sending
    if (!_connectionStable) {
      print("⚠️ Connection not stable yet, waiting...");
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!_connectionStable) {
        print("❌ Connection never stabilized");
        return false;
      }
    }

    try {
      final bytes = utf8.encode(message);
      await _nearby.sendBytesPayload(_connectedEndpointId!, bytes);
      print("📤 Sent: $message");
      return true;
    } catch (e) {
      print("❌ Send error: $e");
      _connectedEndpointId = null;
      _connectionStable = false;
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }

  // Control message helpers
  Future<bool> sendChatRequest(String fromName) async {
    final msg = WiFiControlMessage.encode(WiFiControlType.chatRequest, fromName);
    return sendMessage(msg);
  }

  Future<bool> sendChatAccept(String fromName) async {
    final msg = WiFiControlMessage.encode(WiFiControlType.chatAccept, fromName);
    return sendMessage(msg);
  }

  Future<bool> sendChatDecline(String fromName) async {
    final msg = WiFiControlMessage.encode(WiFiControlType.chatDecline, fromName);
    return sendMessage(msg);
  }

  // =========================================================
  // DISCONNECTION
  // =========================================================
  Future<void> disconnectPeerOnly() async {
    try {
      if (_connectedEndpointId != null) {
        await _nearby.disconnectFromEndpoint(_connectedEndpointId!);
        print("🔌 Disconnected from peer");
        _connectedEndpointId = null;
        _connectionStable = false;
      }
      _updateStatus(ConnectionStatus.disconnected);
    } catch (e) {
      print("⚠️ Disconnect peer error: $e");
    }
  }

  Future<void> disconnect() async {
    try {
      await disconnectPeerOnly();
      await stopDiscovery();
      await stopAdvertising();
      print("🔌 Full disconnect complete");
    } catch (e) {
      print("⚠️ Disconnect error: $e");
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================
  void _updateStatus(ConnectionStatus status) {
    _statusController.add(status);
  }

  bool get isConnected => _connectedEndpointId != null && _connectionStable;
  bool get isDiscovering => _isDiscovering;
  bool get isAdvertising => _isAdvertising;

  Future<void> dispose() async {
    await disconnect();
    await _devicesController.close();
    await _messagesController.close();
    await _statusController.close();
  }
}

enum ConnectionStatus {
  idle,
  ready,
  discovering,
  advertising,
  connecting,
  connected,
  disconnected,
  error,
  permissionDenied,
}