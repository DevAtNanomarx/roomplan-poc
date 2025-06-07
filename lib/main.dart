import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomPlan Flutter POC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RoomPlanHomePage(),
    );
  }
}

class RoomPlanHomePage extends StatefulWidget {
  const RoomPlanHomePage({super.key});

  @override
  State<RoomPlanHomePage> createState() => _RoomPlanHomePageState();
}

class _RoomPlanHomePageState extends State<RoomPlanHomePage> {
  static const platform = MethodChannel('roomplan_flutter_poc/roomplan');
  
  String _status = 'Ready to scan';
  bool _isScanning = false;
  bool _isSupported = false;
  Map<String, dynamic>? _roomData;
  String? _errorMessage;
  List<Map<String, dynamic>> _savedScans = [];
  List<Map<String, dynamic>> _savedUSDZFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    try {
      // Check if we're running on iOS
      if (!Platform.isIOS) {
        setState(() {
          _isSupported = false;
          _status = 'RoomPlan not supported';
          _errorMessage = 'RoomPlan is only available on iOS devices with LiDAR';
        });
        return;
      }

      final bool supported = await platform.invokeMethod('isRoomPlanSupported');
      setState(() {
        _isSupported = supported;
        if (supported) {
          _status = 'RoomPlan is supported! Ready to scan.';
          _loadSavedScans(); // Only load saved scans if RoomPlan is supported
        } else {
          _status = 'RoomPlan not supported - USDZ files available';
          _errorMessage = 'RoomPlan is not supported on this device. You can still upload and view USDZ files.';
        }
      });
      
      // Always load USDZ files regardless of RoomPlan support
      _loadSavedUSDZFiles();
    } on PlatformException catch (e) {
      setState(() {
        _isSupported = false;
        _status = 'Error checking support';
        _errorMessage = 'Failed to check RoomPlan support: ${e.message}';
      });
    }
  }

  Future<void> _loadSavedScans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String result = await platform.invokeMethod('getSavedScans');
      final List<dynamic> scansData = json.decode(result);
      
      setState(() {
        _savedScans = scansData.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load saved scans: ${e.message}';
      });
    }
  }

  Future<void> _loadSavedUSDZFiles() async {
    try {
      final String result = await platform.invokeMethod('getSavedUSDZFiles');
      final List<dynamic> usdzData = json.decode(result);
      
      setState(() {
        _savedUSDZFiles = usdzData.cast<Map<String, dynamic>>();
      });
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = 'Failed to load USDZ files: ${e.message}';
      });
    }
  }

  Future<void> _pickAndUploadUSDZFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['usdz'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final String filePath = result.files.single.path!;
        final String fileName = result.files.single.name;
        
        setState(() {
          _status = 'Uploading USDZ file...';
        });

        await platform.invokeMethod('uploadUSDZFile', {
          'filePath': filePath,
          'fileName': fileName,
        });
        
        setState(() {
          _status = 'USDZ file uploaded successfully!';
        });
        
        _loadSavedUSDZFiles(); // Reload the list
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileName uploaded successfully')),
        );
      }
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Upload failed';
        _errorMessage = 'Failed to upload USDZ file: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _status = 'Upload failed';
        _errorMessage = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _openUSDZFile(String fileName) async {
    try {
      await platform.invokeMethod('openUSDZFile', {'fileName': fileName});
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open USDZ file: ${e.message}')),
      );
    }
  }

  Future<void> _deleteUSDZFile(String fileName) async {
    try {
      await platform.invokeMethod('deleteUSDZFile', {'fileName': fileName});
      _loadSavedUSDZFiles(); // Reload the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('USDZ file deleted successfully')),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete USDZ file: ${e.message}')),
      );
    }
  }

  Future<void> _startRoomScan() async {
    if (!_isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage ?? 'RoomPlan not supported')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _status = 'Starting room scan...';
      _roomData = null;
      _errorMessage = null;
    });

    try {
      // Show scanning dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Room Scanning'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Follow the on-screen instructions to scan your room.'),
                const SizedBox(height: 8),
                const Text('Move around to capture all walls, floors, and furniture.'),
              ],
            ),
          );
        },
      );

      final String result = await platform.invokeMethod('startRoomScan');
      
      // Dismiss the scanning dialog
      Navigator.of(context).pop();
      
      final Map<String, dynamic> responseData = json.decode(result);
      final Map<String, dynamic> roomData = json.decode(responseData['scanData']);
      
      setState(() {
        _isScanning = false;
        _status = 'Scan completed and saved successfully!';
        _roomData = roomData;
      });
      
      // Show success message with scan details
      _showScanResults(roomData);
      
      // Reload saved scans to include the new one
      _loadSavedScans();
    } on PlatformException catch (e) {
      // Dismiss the scanning dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      setState(() {
        _isScanning = false;
        _status = 'Scan failed';
        _errorMessage = 'Error: ${e.message}';
      });
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Scan Failed'),
            content: Text(e.message ?? 'Unknown error occurred'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showScanResults(Map<String, dynamic> roomData) {
    final summary = roomData['summary'] as Map<String, dynamic>?;
    final dimensions = roomData['dimensions'] as Map<String, dynamic>?;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('✅ Scan Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Room Type: ${summary?['roomType'] ?? 'Unknown'}'),
              Text('Scan Quality: ${summary?['scanQuality'] ?? 'Unknown'}'),
              if (dimensions != null) ...[
                const SizedBox(height: 8),
                Text('Dimensions:'),
                Text('  Width: ${dimensions['width']?.toStringAsFixed(2) ?? 'N/A'}m'),
                Text('  Length: ${dimensions['length']?.toStringAsFixed(2) ?? 'N/A'}m'),
                Text('  Height: ${dimensions['height']?.toStringAsFixed(2) ?? 'N/A'}m'),
              ],
              const SizedBox(height: 8),
              Text('Surfaces detected: ${summary?['totalSurfaces'] ?? 0}'),
              Text('Objects detected: ${summary?['totalObjects'] ?? 0}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Great!'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSavedScan(String fileName) async {
    try {
      await platform.invokeMethod('deleteSavedScan', {'fileName': fileName});
      _loadSavedScans(); // Reload the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan deleted successfully')),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete scan: ${e.message}')),
      );
    }
  }

  void _loadSavedScan(Map<String, dynamic> scanData) {
    final roomData = json.decode(scanData['scanData']);
    setState(() {
      _roomData = roomData;
      _status = 'Loaded saved scan';
      _errorMessage = null;
    });
  }

  Widget _buildRoomDataDisplay() {
    if (_roomData == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Room Scan Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRoomInfo(),
            const SizedBox(height: 16),
            _buildSurfacesList(),
            const SizedBox(height: 16),
            _buildObjectsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomInfo() {
    final confidence = _roomData!['confidence'] ?? 'Unknown';
    final dimensions = _roomData!['dimensions'] as Map<String, dynamic>?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confidence: $confidence', style: const TextStyle(fontSize: 16)),
        if (dimensions != null) ...[
          const SizedBox(height: 8),
          Text(
            'Dimensions: ${dimensions['width']?.toStringAsFixed(2) ?? 'N/A'}m × ${dimensions['height']?.toStringAsFixed(2) ?? 'N/A'}m × ${dimensions['length']?.toStringAsFixed(2) ?? 'N/A'}m',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ],
    );
  }

  Widget _buildSurfacesList() {
    final surfaces = _roomData!['surfaces'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Surfaces (${surfaces.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...surfaces.map((surface) => Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
          child: Text(
            '• ${surface['category'] ?? 'Unknown'} - ${surface['confidence'] ?? 'Unknown'} confidence',
            style: const TextStyle(fontSize: 14),
          ),
        )),
      ],
    );
  }

  Widget _buildObjectsList() {
    final objects = _roomData!['objects'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Objects (${objects.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...objects.map((object) => Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
          child: Text(
            '• ${object['category'] ?? 'Unknown'} - ${object['confidence'] ?? 'Unknown'} confidence',
            style: const TextStyle(fontSize: 14),
          ),
        )),
      ],
    );
  }

  Widget _buildSavedScansSection() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saved Scans',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadSavedScans,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_savedScans.isEmpty && !_isLoading)
              const Text('No saved scans found')
            else
              ..._savedScans.map((scan) => _buildSavedScanItem(scan)),
          ],
        ),
      ),
    );
  }

  Widget _buildUSDZFilesSection() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'USDZ Files',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      onPressed: _pickAndUploadUSDZFile,
                      tooltip: 'Upload USDZ file',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadSavedUSDZFiles,
                      tooltip: 'Refresh list',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Upload and view 3D models in USDZ format',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            if (_savedUSDZFiles.isEmpty)
              const Text('No USDZ files found. Tap + to upload one.')
            else
              ..._savedUSDZFiles.map((file) => _buildUSDZFileItem(file)),
          ],
        ),
      ),
    );
  }

  Widget _buildUSDZFileItem(Map<String, dynamic> file) {
    final fileName = file['fileName'] ?? 'Unknown';
    final timestamp = file['timestamp'] ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(Icons.view_in_ar_outlined, color: Colors.orange),
        title: Text(fileName),
        subtitle: Text(formattedDate),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.green),
              onPressed: () => _openUSDZFile(fileName),
              tooltip: 'Open in AR',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteUSDZConfirmation(file),
              tooltip: 'Delete file',
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUSDZConfirmation(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete USDZ File'),
          content: Text('Are you sure you want to delete "${file['fileName']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUSDZFile(file['fileName']);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSavedScanItem(Map<String, dynamic> scan) {
    final fileName = scan['fileName'] ?? 'Unknown';
    final timestamp = scan['timestamp'] ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: const Icon(Icons.view_in_ar, color: Colors.blue),
        title: Text('Room Scan'),
        subtitle: Text(formattedDate),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.green),
              onPressed: () => _loadSavedScan(scan),
              tooltip: 'Load scan',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(scan),
              tooltip: 'Delete scan',
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> scan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Scan'),
          content: const Text('Are you sure you want to delete this room scan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSavedScan(scan['fileName']);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('RoomPlan Flutter POC'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            
            // Support status
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _isSupported ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: _isSupported ? Colors.green : Colors.red,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSupported ? Icons.check_circle : Icons.error,
                    color: _isSupported ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isSupported 
                        ? 'RoomPlan is supported on this device'
                        : _errorMessage ?? 'RoomPlan not supported',
                      style: TextStyle(
                        color: _isSupported ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status display
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),

            // Action buttons
            const SizedBox(height: 32),
            if (_isSupported)
              ElevatedButton(
                onPressed: !_isScanning ? _startRoomScan : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: _isScanning
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Scanning...'),
                        ],
                      )
                    : const Text('Start Room Scan'),
              )
            else
              ElevatedButton.icon(
                onPressed: _pickAndUploadUSDZFile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload USDZ File'),
              ),

            // Error message
            if (_errorMessage != null && !_isScanning)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              ),

            // Room data display
            _buildRoomDataDisplay(),

            // Saved scans section (only show if RoomPlan is supported)
            if (_isSupported) _buildSavedScansSection(),

            // USDZ files section (always show)
            _buildUSDZFilesSection(),
          ],
        ),
      ),
    );
  }
}
