// screens/customer/sub/nearby_users_screen_wifi.dart
import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:offline_chat_app/models/caflow_models.dart';
import 'package:offline_chat_app/screens/customer/sub/chat/chat_screen.dart';
import 'package:offline_chat_app/screens/customer/sub/nearby/nearby_wifi_widgets.dart';
import 'package:offline_chat_app/services/wifi_direct_service.dart';
import 'package:offline_chat_app/utils/permission_helper.dart';

class NearbyUsersScreenWiFi extends StatefulWidget {
  final String userName;
  
  const NearbyUsersScreenWiFi({
    super.key,
    required this.userName,
  });

  @override
  State<NearbyUsersScreenWiFi> createState() => _NearbyUsersScreenWiFiState();
}

class _NearbyUsersScreenWiFiState extends State<NearbyUsersScreenWiFi>
    with WidgetsBindingObserver {
  final WiFiDirectService _wifiService = WiFiDirectService();

  List<CaflowDevice> _devices = [];
  ConnectionStatus _status = ConnectionStatus.idle;
  
  StreamSubscription<List<CaflowDevice>>? _devicesSub;
  StreamSubscription<ConnectionStatus>? _statusSub;

  // Chat request state
  bool _isWaitingForChatResponse = false;
  CaflowDevice? _pendingChatDevice;
  bool _hasIncomingRequestDialog = false;
  bool _waitingDialogOpen = false; // track "Waiting for response" dialog

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    // Request permissions first
    final permissionsGranted =
        await PermissionHelper.requestWiFiDirectPermissions();
    
    if (!permissionsGranted) {
      if (mounted) {
        _showPermissionDialog();
      }
      return;
    }

    // Initialize WiFi Direct
    final initialized = await _wifiService.initialize(widget.userName);
    
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize Wi-Fi Direct.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ====== CONTROL CALLBACKS ======

    // Incoming chat request from other device
    _wifiService.onChatRequestReceived = (remoteName) async {
      if (!mounted) return;

      // If this screen is not on top, we're busy -> auto-decline
      if (ModalRoute.of(context)?.isCurrent != true) {
        await _wifiService.sendChatDecline(widget.userName);
        return;
      }

      // If we already have another incoming request dialog open, auto-decline
      if (_hasIncomingRequestDialog) {
        await _wifiService.sendChatDecline(widget.userName);
        return;
      }

      _hasIncomingRequestDialog = true;
      final accept = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Chat Request'),
          content: Text('$remoteName wants to start an offline chat with you.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Decline'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Accept'),
            ),
          ],
        ),
      );
      _hasIncomingRequestDialog = false;

      if (!mounted) return;

      if (accept == true) {
        // Tell the other device we accepted
        await _wifiService.sendChatAccept(widget.userName);

        // Stop discovery while chatting
        await _wifiService.stopDiscovery();

        // We only need a CaflowDevice object for UI; address isn't used in ChatScreenWiFi
        final remoteDevice = CaflowDevice(
          name: remoteName,
          address: 'remote', // dummy
        );

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreenWiFi(
              device: remoteDevice,
              userName: widget.userName,
            ),
          ),
        );

        // After chat, restart discovery & advertising
        await _startDiscoveryAndAdvertising();
} else {
  await _wifiService.sendChatDecline(widget.userName);
  // Instead of full disconnect, just drop the peer:
  await _wifiService.disconnectPeerOnly();
}
    };

    // Our outgoing request was accepted
    _wifiService.onChatAccepted = (remoteName) async {
      if (!mounted) return;
      if (!_isWaitingForChatResponse || _pendingChatDevice == null) {
        return;
      }

      _isWaitingForChatResponse = false;
      final device = _pendingChatDevice!;
      _pendingChatDevice = null;

      if (_waitingDialogOpen && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // close "Waiting..." dialog
        _waitingDialogOpen = false;
      }

      await _wifiService.stopDiscovery();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreenWiFi(
            device: device,
            userName: widget.userName,
          ),
        ),
      );

      await _startDiscoveryAndAdvertising();
    };

// Our outgoing request was declined
_wifiService.onChatDeclined = (remoteName) async {
  if (!mounted) return;
  if (!_isWaitingForChatResponse) return;

  _isWaitingForChatResponse = false;
  _pendingChatDevice = null;

  if (_waitingDialogOpen && Navigator.of(context).canPop()) {
    Navigator.of(context).pop(); // close "Waiting..." dialog
    _waitingDialogOpen = false;
  }

  // Just drop the peer connection, keep advertising/discovery running
  await _wifiService.disconnectPeerOnly();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$remoteName declined your chat request'),
      backgroundColor: Colors.orange,
    ),
  );

  // No need to call _startDiscoveryAndAdvertising() here,
  // because we never stopped it.
};



    // ====== NORMAL DISCOVERY / STATUS STREAMS ======

    // Listen to device discoveries
    _devicesSub = _wifiService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices;
        });
      }
    });

    // Listen to connection status
    _statusSub = _wifiService.statusStream.listen((status) async {
      if (!mounted) return;
      setState(() {
        _status = status;
      });

      // If we were waiting for the other user and the connection drops,
      // treat it as a failed request.
      if (status == ConnectionStatus.disconnected && _isWaitingForChatResponse) {
        _isWaitingForChatResponse = false;
        _pendingChatDevice = null;

        if (_waitingDialogOpen && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // close "Waiting for response" dialog
          _waitingDialogOpen = false;
        }

        // Optional: show a small message so user understands
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Connection lost before the other device responded.',
            ),
          ),
        );
      }
    });

    // Start both advertising and discovery
    await _startDiscoveryAndAdvertising();
  }

  Future<void> _startDiscoveryAndAdvertising() async {
    if (!_wifiService.isAdvertising) {
      await _wifiService.startAdvertising(widget.userName);
    }

    if (!_wifiService.isDiscovering) {
      await _wifiService.startDiscovery(widget.userName);
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'Caflow needs Location permission to discover nearby users via Wi-Fi Direct.\n\n'
          'Please grant the permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _initialize();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _openSystemSettingsSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Check device settings'),
                subtitle: Text(
                  'If you are having trouble discovering devices, '
                  'check that Wi-Fi, Bluetooth, and Location are turned ON.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.wifi),
                title: const Text('Open Wi-Fi settings'),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSettings.openAppSettings(
                    type: AppSettingsType.wifi,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bluetooth),
                title: const Text('Open Bluetooth settings'),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSettings.openAppSettings(
                    type: AppSettingsType.bluetooth,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Open Location settings'),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSettings.openAppSettings(
                    type: AppSettingsType.location,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.android),
                title: const Text('Open app settings'),
                onTap: () {
                  Navigator.pop(ctx);
                  AppSettings.openAppSettings(
                    type: AppSettingsType.settings,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _connectAndChat(CaflowDevice device) async {
    // Avoid multiple parallel outgoing requests
    if (_isWaitingForChatResponse) return;
    if (!mounted) return;

    // Show connecting dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting via Wi-Fi Direct...'),
                  SizedBox(height: 8),
                  Text(
                    'Make sure the other device stays on this screen.',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Attempt connection
    final success =
        await _wifiService.connectToDevice(device, widget.userName);

    if (mounted) {
      Navigator.pop(context); // Close connecting dialog
    }

    if (success && mounted) {
      // We're connected. Send chat request and wait for their response.
      _pendingChatDevice = device;
      _isWaitingForChatResponse = true;

      await _wifiService.sendChatRequest(widget.userName);

      _waitingDialogOpen = true;
      // Show "waiting for acceptance" dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('Waiting for response'),
            content: Text(
              'Waiting for ${device.name} to accept your chat request...',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  _waitingDialogOpen = false;
                  _isWaitingForChatResponse = false;
                  _pendingChatDevice = null;
                  await _wifiService.sendChatDecline(widget.userName);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    } else if (mounted) {
      _showConnectionFailedDialog(device);
    }
  }

  void _showConnectionFailedDialog(CaflowDevice device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Connection Failed'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Could not connect to ${device.name}.'),
              const SizedBox(height: 16),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1️⃣ Make sure Wi-Fi is enabled on both devices'),
              const SizedBox(height: 4),
              const Text('2️⃣ Both devices should have Location enabled'),
              const SizedBox(height: 4),
              const Text('3️⃣ Ensure both devices are on this screen'),
              const SizedBox(height: 4),
              const Text('4️⃣ Grant all permissions when asked'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Caflow works completely offline using nearby connections.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _connectAndChat(device);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startDiscoveryAndAdvertising();
    } else if (state == AppLifecycleState.paused) {
      // Keep advertising but can pause discovery if you want
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _devicesSub?.cancel();
    _statusSub?.cancel();
    _wifiService.stopDiscovery();
    _wifiService.stopAdvertising();

    // Clear callbacks so they don’t fire into a dead widget
    _wifiService.onChatRequestReceived = null;
    _wifiService.onChatAccepted = null;
    _wifiService.onChatDeclined = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Caflow Users"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startDiscoveryAndAdvertising,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Top banner: shows state + "Troubleshoot" for error/permission cases
          NearbyStatusBanner(
            status: _status,
            onFixTap: _openSystemSettingsSheet,
          ),
          // Device list / empty state
          Expanded(
            child: _devices.isEmpty
                ? NearbyEmptyState(
                    status: _status,
                    onFixSettings: _openSystemSettingsSheet,
                  )
                : NearbyDeviceList(
                    devices: _devices,
                    onDeviceTap: _connectAndChat,
                  ),
          ),
        ],
      ),
    );
  }
}
