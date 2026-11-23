/// Device Pairing and Settings Screen for Speakaboo hardware companion.
library;

import 'package:flutter/material.dart';
import '../config/theme.dart';

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  bool _isScanning = false;
  String? _connectedDeviceId;
  bool _relayMic = true;
  bool _relaySpeaker = true;

  final List<Map<String, dynamic>> _devices = [
    {
      'id': 'ble:spk-toy-001',
      'name': 'Speakaboo Toy (Puff)',
      'rssi': -58,
      'battery': 94,
      'firmware': 'v1.0.2',
    },
    {
      'id': 'ble:spk-toy-002',
      'name': 'Speakaboo Toy (Reggie)',
      'rssi': -76,
      'battery': 68,
      'firmware': 'v1.0.1',
    },
  ];

  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;
    });
  }

  void _toggleConnect(String deviceId) {
    setState(() {
      if (_connectedDeviceId == deviceId) {
        _connectedDeviceId = null;
      } else {
        _connectedDeviceId = deviceId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpeakabooTheme.background,
      appBar: AppBar(
        title: const Text('Companion Toy (BLE)'),
        backgroundColor: SpeakabooTheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
              decoration: BoxDecoration(
                color: _connectedDeviceId != null
                    ? SpeakabooTheme.accent.withValues(alpha: 0.12)
                    : SpeakabooTheme.surface,
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    _connectedDeviceId != null
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_searching,
                    color: SpeakabooTheme.accent,
                    size: 28,
                  ),
                  const SizedBox(width: SpeakabooTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _connectedDeviceId != null
                              ? 'Connected to Toy'
                              : 'No Toy Connected',
                          style: const TextStyle(
                            fontSize: SpeakabooTheme.baseFontSize,
                            fontWeight: FontWeight.bold,
                            color: SpeakabooTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _connectedDeviceId != null
                              ? 'Audio relay and push-to-talk active'
                              : 'The app works fully standalone or with the toy',
                          style: const TextStyle(
                            fontSize: SpeakabooTheme.captionSize,
                            color: SpeakabooTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingLg),

            // Scan header & button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby Companion Toys',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.subheadingSize,
                    fontWeight: FontWeight.bold,
                    color: SpeakabooTheme.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _toggleScan,
                  icon: Icon(
                    _isScanning ? Icons.stop : Icons.refresh,
                    color: SpeakabooTheme.accent,
                  ),
                  label: Text(
                    _isScanning ? 'Stop' : 'Scan',
                    style: const TextStyle(
                      color: SpeakabooTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpeakabooTheme.spacingSm),

            // Discovered Devices
            ..._devices.map((device) {
              final isConnected = _connectedDeviceId == device['id'];
              return Container(
                margin: const EdgeInsets.only(bottom: SpeakabooTheme.spacingSm),
                padding: const EdgeInsets.all(SpeakabooTheme.spacingMd),
                decoration: BoxDecoration(
                  color: SpeakabooTheme.surface,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                  border: isConnected
                      ? Border.all(color: SpeakabooTheme.accent, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.smart_toy_outlined,
                      color: SpeakabooTheme.accent,
                      size: 32,
                    ),
                    const SizedBox(width: SpeakabooTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device['name'],
                            style: const TextStyle(
                              fontSize: SpeakabooTheme.baseFontSize,
                              fontWeight: FontWeight.bold,
                              color: SpeakabooTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Battery: ${device['battery']}% • Signal: ${device['rssi']} dBm',
                            style: const TextStyle(
                              fontSize: SpeakabooTheme.captionSize,
                              color: SpeakabooTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: SpeakabooTheme.minTapTarget,
                      child: ElevatedButton(
                        onPressed: () => _toggleConnect(device['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected
                              ? SpeakabooTheme.textSecondary
                              : SpeakabooTheme.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(SpeakabooTheme.radiusSm),
                          ),
                        ),
                        child: Text(isConnected ? 'Disconnect' : 'Connect'),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: SpeakabooTheme.spacingLg),

            // Audio Relay Settings
            const Text(
              'Hardware Audio Relay Settings',
              style: TextStyle(
                fontSize: SpeakabooTheme.subheadingSize,
                fontWeight: FontWeight.bold,
                color: SpeakabooTheme.textPrimary,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingSm),
            Material(
              color: SpeakabooTheme.surface,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Relay Microphone Input'),
                    subtitle: const Text('Capture speech through physical toy mic'),
                    value: _relayMic,
                    activeThumbColor: SpeakabooTheme.accent,
                    onChanged: (val) => setState(() => _relayMic = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Relay Speaker Output'),
                    subtitle: const Text('Play companion voice on toy speaker'),
                    value: _relaySpeaker,
                    activeThumbColor: SpeakabooTheme.accent,
                    onChanged: (val) => setState(() => _relaySpeaker = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
