import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const RoomPlanTestApp());
}

class RoomPlanTestApp extends StatelessWidget {
  const RoomPlanTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomPlan Support Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DeviceCapabilityDashboard(),
    );
  }
}

class DeviceCapabilityDashboard extends StatefulWidget {
  const DeviceCapabilityDashboard({super.key});

  @override
  State<DeviceCapabilityDashboard> createState() => _DeviceCapabilityDashboardState();
}

class _DeviceCapabilityDashboardState extends State<DeviceCapabilityDashboard> {
  static const platform = MethodChannel('roomplan_flutter_poc/roomplan');
  
  bool _isLoading = true;
  Map<String, dynamic>? _deviceInfo;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkDeviceCapabilities();
  }

  Future<void> _checkDeviceCapabilities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if we're running on iOS
      if (!Platform.isIOS) {
        setState(() {
          _isLoading = false;
          _deviceInfo = {
            'isSupported': false,
            'platform': Platform.operatingSystem.toUpperCase(),
            'platformVersion': Platform.operatingSystemVersion,
            'error': 'RoomPlan is only available on iOS devices',
            'hasLiDAR': false,
            'frameworkAvailable': false,
          };
        });
        return;
      }

      final String result = await platform.invokeMethod('isRoomPlanSupported');
      final Map<String, dynamic> deviceInfo = json.decode(result);
      
      setState(() {
        _isLoading = false;
        _deviceInfo = deviceInfo;
      });
    } on PlatformException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
        _deviceInfo = {
          'isSupported': false,
          'error': 'Platform error: ${e.message}',
          'errorCode': e.code,
        };
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _deviceInfo = {
          'isSupported': false,
          'error': 'Unexpected error: $e',
        };
      });
    }
  }

  Widget _buildStatusCard(String title, bool? status, {String? subtitle, IconData? icon}) {
    Color cardColor;
    Color textColor;
    IconData displayIcon;

    if (status == null) {
      cardColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
      displayIcon = Icons.help_outline;
    } else if (status) {
      cardColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
      displayIcon = Icons.check_circle;
    } else {
      cardColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
      displayIcon = Icons.cancel;
    }

    return Card(
      elevation: 4,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon ?? displayIcon,
              size: 32,
              color: textColor,
            ),
            const SizedBox(width: 16),
            Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, {IconData? icon}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24, color: Colors.blue),
              const SizedBox(width: 12),
            ],
            Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
              ),
            ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('RoomPlan Device Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkDeviceCapabilities,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
          children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking device capabilities...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Status Section
                  Text(
                    'Device Capabilities',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // RoomPlan Support
                  _buildStatusCard(
                    'RoomPlan Support',
                    _deviceInfo?['isSupported'] as bool?,
                    subtitle: _deviceInfo?['isSupported'] == true 
                        ? 'Ready to scan rooms!' 
                        : _deviceInfo?['error']?.toString() ?? 'Not supported',
                    icon: Icons.view_in_ar,
                      ),
                  const SizedBox(height: 12),

                  // LiDAR Support
                  _buildStatusCard(
                    'LiDAR Sensor',
                    _deviceInfo?['hasLiDAR'] as bool?,
                    subtitle: _deviceInfo?['hasLiDAR'] == true 
                        ? 'Depth sensing available' 
                        : 'Required for RoomPlan',
                    icon: Icons.radar,
                  ),
                  const SizedBox(height: 12),

                  // RoomPlan Framework
                  _buildStatusCard(
                    'RoomPlan Framework',
                    _deviceInfo?['frameworkAvailable'] as bool?,
                    subtitle: _deviceInfo?['frameworkAvailable'] == true 
                        ? 'Framework loaded' 
                        : 'Not available (likely simulator)',
                    icon: Icons.extension,
                  ),
                  const SizedBox(height: 24),

                  // Device Information Section
                  Text(
                    'Device Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      ),
                  ),
                  const SizedBox(height: 16),

                  if (_deviceInfo != null) ...[
                    _buildInfoCard(
                      'Platform',
                      Platform.isIOS ? 'iOS' : Platform.operatingSystem.toUpperCase(),
                      icon: Platform.isIOS ? Icons.phone_iphone : Icons.android,
                    ),
                    const SizedBox(height: 8),
                    
                    if (_deviceInfo!['iOSVersion'] != null)
                      _buildInfoCard(
                        'iOS Version',
                        _deviceInfo!['iOSVersion'].toString(),
                        icon: Icons.info,
                      ),
                    const SizedBox(height: 8),

                    if (_deviceInfo!['deviceModel'] != null)
                      _buildInfoCard(
                        'Device Model',
                        _deviceInfo!['deviceModel'].toString(),
                        icon: Icons.devices,
                      ),
                    const SizedBox(height: 8),

                    // Debug Information (if available)
                    if (_deviceInfo!['debugInfo'] != null)
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                              Row(
                                children: [
                                  Icon(Icons.bug_report, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                          Text(
                                    'Debug Information',
                            style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                            ),
                                  ),
                                ],
                          ),
                          const SizedBox(height: 8),
                              Text(
                                _deviceInfo!['debugInfo'].toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ),
                    ),
                  ],

                  // Error Information
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Error Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Test Scan Button (only if supported)
                  if (_deviceInfo?['isSupported'] == true)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await platform.invokeMethod('startRoomScan');
                        } on PlatformException catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Scan test: ${e.message}'),
                                backgroundColor: Colors.orange,
              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.scanner),
                      label: const Text('Test RoomPlan Scan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Supported Devices Info
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
              padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'RoomPlan Requirements',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('• iOS 16.0 or later'),
                          const Text('• LiDAR-enabled device:'),
                          const Text('  - iPhone 12 Pro, 12 Pro Max'),
                          const Text('  - iPhone 13 Pro, 13 Pro Max'), 
                          const Text('  - iPhone 14 Pro, 14 Pro Max'),
                          const Text('  - iPhone 15 Pro, 15 Pro Max'),
                          const Text('  - iPad Pro (4th gen) 11-inch and later'),
                          const Text('  - iPad Pro (5th gen) 12.9-inch and later'),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
