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
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Companion Toy (BLE)', style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
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
                    ? colors.accent.withValues(alpha: 0.12)
                    : colors.surface,
                borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    _connectedDeviceId != null
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_searching,
                    color: colors.accent,
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
                          style: TextStyle(
                            fontSize: SpeakabooTheme.baseFontSize,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          _connectedDeviceId != null
                              ? 'Audio relay and push-to-talk active'
                              : 'The app works fully standalone or with the toy',
                          style: TextStyle(
                            fontSize: SpeakabooTheme.captionSize,
                            color: colors.textSecondary,
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
                Text(
                  'Nearby Companion Toys',
                  style: TextStyle(
                    fontSize: SpeakabooTheme.subheadingSize,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _toggleScan,
                  icon: Icon(
                    _isScanning ? Icons.stop : Icons.refresh,
                    color: colors.accent,
                  ),
                  label: Text(
                    _isScanning ? 'Stop' : 'Scan',
                    style: TextStyle(
                      color: colors.accent,
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
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
                  border: isConnected
                      ? Border.all(color: colors.accent, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      color: colors.accent,
                      size: 32,
                    ),
                    const SizedBox(width: SpeakabooTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device['name'],
                            style: TextStyle(
                              fontSize: SpeakabooTheme.baseFontSize,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Battery: ${device['battery']}% • Signal: ${device['rssi']} dBm',
                            style: TextStyle(
                              fontSize: SpeakabooTheme.captionSize,
                              color: colors.textSecondary,
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
                              ? colors.textSecondary
                              : colors.accent,
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
            Text(
              'Hardware Audio Relay Settings',
              style: TextStyle(
                fontSize: SpeakabooTheme.subheadingSize,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: SpeakabooTheme.spacingSm),
            Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(SpeakabooTheme.radiusMd),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Relay Microphone Input', style: TextStyle(color: colors.textPrimary)),
                    subtitle: Text('Capture speech through physical toy mic', style: TextStyle(color: colors.textSecondary)),
                    value: _relayMic,
                    activeThumbColor: colors.accent,
                    onChanged: (val) => setState(() => _relayMic = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text('Relay Speaker Output', style: TextStyle(color: colors.textPrimary)),
                    subtitle: Text('Play companion voice on toy speaker', style: TextStyle(color: colors.textSecondary)),
                    value: _relaySpeaker,
                    activeThumbColor: colors.accent,
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
