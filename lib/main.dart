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
  List<Map<String, dynamic>> _savedUSDZFiles = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkDeviceCapabilities();
    _loadSavedUSDZFiles();
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

  Future<void> _loadSavedUSDZFiles() async {
    try {
      if (Platform.isIOS) {
        final String result = await platform.invokeMethod('getSavedUSDZFiles');
        final List<dynamic> files = json.decode(result);
        setState(() {
          _savedUSDZFiles = files.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Error loading USDZ files: $e');
    }
  }

  Future<void> _startRoomScan() async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
    });

    try {
      final result = await platform.invokeMethod('startRoomScan');
      
      if (result is Map) {
        final message = result['message'] ?? 'Room scan completed';
        final success = result['success'] ?? false;
        
        // Show result message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.orange,
            duration: Duration(seconds: success ? 3 : 2),
          ),
        );
        
        // If a file was saved, reload the list
        if (result['filePath'] != null && success) {
          await _loadSavedUSDZFiles();
          
          // Show additional success info
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 USDZ file saved! View it in the "Saved Room Scans" section below.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'VIEW FILES',
                textColor: Colors.white,
                onPressed: () {
                  // Scroll to saved files section (if needed)
                },
              ),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan Error: ${e.message}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _openUSDZFile(String fileName) async {
    try {
      await platform.invokeMethod('openUSDZFile', {'fileName': fileName});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUSDZFile(String fileName) async {
    try {
      await platform.invokeMethod('deleteUSDZFile', {'fileName': fileName});
      await _loadSavedUSDZFiles(); // Reload the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File deleted: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importUSDZFile() async {
    try {
      final result = await platform.invokeMethod('importUSDZFile');
      
      if (result is Map && result['success'] == true) {
        final fileName = result['fileName'] as String?;
        final message = result['message'] as String? ?? 'File imported successfully';
        
        // Reload the files list
        await _loadSavedUSDZFiles();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $message'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Show additional info about the imported file
        if (fileName != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📁 Imported: $fileName\nTap to view in AR!'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'VIEW',
                textColor: Colors.white,
                onPressed: () => _openUSDZFile(fileName),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${result['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (e.code == 'USER_CANCELLED') {
        // Don't show error for user cancellation
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import Error: ${e.message}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

                  // Room Scanning Section
                  if (_deviceInfo?['isSupported'] == true) ...[
                    Text(
                      'Room Scanning',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _startRoomScan,
                      icon: _isScanning 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.view_in_ar),
                      label: Text(_isScanning ? 'Scanning...' : 'Start Room Scan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Saved USDZ Files Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saved Room Scans',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _importUSDZFile,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Import USDZ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_savedUSDZFiles.isEmpty)
                      Card(
                        color: Colors.grey.shade100,
                        child: const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(Icons.folder_open, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No room scans saved yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Start a room scan or import a USDZ file',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _savedUSDZFiles.length,
                        itemBuilder: (context, index) {
                          final file = _savedUSDZFiles[index];
                          final fileName = file['fileName'] as String;
                          final timestamp = file['timestamp'] as int;
                          final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                          final formattedDate = 
                              '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.view_in_ar, color: Colors.blue),
                              title: Text(fileName),
                              subtitle: Text('Scanned on $formattedDate'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'open') {
                                    await _openUSDZFile(fileName);
                                  } else if (value == 'delete') {
                                    // Show confirmation dialog
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Room Scan'),
                                        content: Text('Are you sure you want to delete "$fileName"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    
                                    if (shouldDelete == true) {
                                      await _deleteUSDZFile(fileName);
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'open',
                                    child: Row(
                                      children: [
                                        Icon(Icons.open_in_new),
                                        SizedBox(width: 8),
                                        Text('View in AR'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _openUSDZFile(fileName),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                  ],

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
