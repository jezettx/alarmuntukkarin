// ignore_for_file: avoid_print, use_build_context_synchronously, unused_import

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:alarm/services/alarm_service.dart';
import 'package:alarm/services/pair_remote_service.dart';
import 'package:alarm/services/background_service.dart';
import 'package:alarm/pages/setup_guide_page.dart';

class AlarmPage extends StatefulWidget {
  final String pairId;

  const AlarmPage({super.key, required this.pairId});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  PairRemoteService? _pairService;
  
  String? _selectedRingtonePath;
  String? _selectedRingtoneName;
  
  DateTime? _lastCommandTime;

  @override
  void initState() {
    super.initState();
    _initService();
    
    // Listen to background service messages
    FlutterBackgroundService().on('ring').listen((event) {
      print('🔔 Background service says: RING!');
      _handleRing();
    });

    FlutterBackgroundService().on('stop').listen((event) {
      print('🛑 Background service says: STOP!');
      _handleStop();
    });
  }

  Future<void> _initService() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? deviceId = prefs.getString('device_id');
      
      if (deviceId == null) {
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('device_id', deviceId);
        print('✅ Generated Device ID: $deviceId');
      }

      // LOAD SAVED RINGTONE
      _selectedRingtonePath = prefs.getString('custom_ringtone_path');
      _selectedRingtoneName = prefs.getString('custom_ringtone_name');
      
      if (_selectedRingtonePath != null) {
        // Validate file still exists
        final file = File(_selectedRingtonePath!);
        if (await file.exists()) {
          print('✅ Loaded ringtone: $_selectedRingtoneName');
          AlarmService.instance.setCustomRingtone(_selectedRingtonePath);
        } else {
          print('⚠️ Saved ringtone file not found, cleared');
          _selectedRingtonePath = null;
          _selectedRingtoneName = null;
          await prefs.remove('custom_ringtone_path');
          await prefs.remove('custom_ringtone_name');
        }
      }

      _pairService = PairRemoteService(pairId: widget.pairId);
      
      _pairService!.listen(
        onRing: _handleRing,
        onStop: _handleStop,
        onRingtoneChange: (ringtone) {
          print('🎵 Ringtone changed: $ringtone');
        },
      );

      if (mounted) setState(() {});
      
    } catch (e) {
      print('❌ Init error: $e');
    }
  }

  void _handleRing() {
    print('🔔 RING received');
    
    if (_lastCommandTime != null) {
      final diff = DateTime.now().difference(_lastCommandTime!);
      print('⏱️ Time since last: ${diff.inSeconds}s');
      
      if (diff.inSeconds < 5) {
        print('⏭️ Ignoring (sent by me)');
        return;
      }
    }
    
    print('✅ Playing alarm');
    AlarmService.instance.playAlarm(partnerName: 'Pacar');
  }

  void _handleStop() {
    print('🛑 STOP received');
    
    if (_lastCommandTime != null) {
      final diff = DateTime.now().difference(_lastCommandTime!);
      if (diff.inSeconds < 5) {
        print('⏭️ Ignoring');
        return;
      }
    }
    
    AlarmService.instance.stopAlarm(method: 'remote_command');
  }

  @override
  void dispose() {
    _pairService?.dispose();
    super.dispose();
  }

  Future<void> _sendRing() async {
    if (_pairService == null) return;

    if (_selectedRingtonePath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Pilih nada dering dulu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('🚀 Sending RING...');
    _lastCommandTime = DateTime.now();
    await _pairService!.setRing();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏰ Alarm dikirim!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _sendStop() async {
    if (_pairService == null) return;

    _lastCommandTime = DateTime.now();
    await _pairService!.setStop();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛑 Stop dikirim!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _pickRingtone() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.path == null) return;

    setState(() {
      _selectedRingtonePath = file.path;
      _selectedRingtoneName = file.name;
    });

    print("✅ Selected: ${file.name}");
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('👆 Tap "Set Nada Dering"!')),
      );
    }
  }

  Future<void> _setRingtone() async {
    if (_selectedRingtonePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dulu!')),
      );
      return;
    }

    try {
      // COPY FILE KE PERMANENT STORAGE!
      print('📂 Copying file to permanent storage...');
      
      final appDir = await getApplicationDocumentsDirectory();
      final ringtoneDir = Directory('${appDir.path}/ringtones');
      
      // Create directory if not exists
      if (!await ringtoneDir.exists()) {
        await ringtoneDir.create(recursive: true);
        print('✅ Created ringtone directory');
      }
      
      // Copy file
      final sourceFile = File(_selectedRingtonePath!);
      final fileName = _selectedRingtoneName ?? 'alarm_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final targetPath = '${ringtoneDir.path}/$fileName';
      
      print('📋 Copying from: $_selectedRingtonePath');
      print('📋 Copying to: $targetPath');
      
      await sourceFile.copy(targetPath);
      
      final targetFile = File(targetPath);
      final size = await targetFile.length();
      print('✅ File copied! Size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
      
      // Update path to permanent location
      _selectedRingtonePath = targetPath;
      
      // Set to AlarmService
      AlarmService.instance.setCustomRingtone(_selectedRingtonePath);
      
      // SAVE TO SHAREDPREFERENCES
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_ringtone_path', _selectedRingtonePath!);
      await prefs.setString('custom_ringtone_name', _selectedRingtoneName!);
      
      print('✅ Saved to permanent storage!');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Tersimpan permanent: $_selectedRingtoneName'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {});
      
    } catch (e) {
      print('❌ Error copying file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasRingtone = _selectedRingtonePath != null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gentle Wake-Up'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SetupGuidePage()),
              );
            },
            tooltip: 'Setup Guide',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                color: hasRingtone ? Colors.green.shade50 : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        hasRingtone ? Icons.check_circle : Icons.warning,
                        size: 40,
                        color: hasRingtone ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pair: ${widget.pairId}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasRingtone 
                            ? '✅ $_selectedRingtoneName' 
                            : '⚠️ Pilih nada dering!',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasRingtone ? Colors.green.shade800 : Colors.orange.shade900,
                          fontWeight: hasRingtone ? FontWeight.normal : FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: _sendRing,
                icon: const Icon(Icons.notifications_active, size: 28),
                label: const Text(
                  'Bangunin Pacar! 💕',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _sendStop,
                icon: const Icon(Icons.stop_circle, size: 28),
                label: const Text(
                  'Stop Alarm Pacar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              const Divider(thickness: 2),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _pickRingtone,
                icon: const Icon(Icons.folder_open),
                label: const Text('Pilih Nada Dering'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.deepPurple, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _setRingtone,
                icon: const Icon(Icons.check_circle),
                label: const Text('Set Nada Dering'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.deepPurple, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}