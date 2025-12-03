// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:alarm/services/alarm_service.dart';

class AlarmPage extends StatefulWidget {
  final String pairId;

  const AlarmPage({
    super.key,
    required this.pairId,
  });

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  String? _selectedRingtonePath;
  String? _selectedRingtoneName;

  // Button 3: Pilih Nada Dering
  Future<void> _pickRingtone() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result == null || result.files.isEmpty) {
      print("🔇 User cancelled file picker");
      return;
    }

    final file = result.files.single;
    final path = file.path;

    if (path == null) {
      print("❌ File path is null");
      return;
    }

    setState(() {
      _selectedRingtonePath = path;
      _selectedRingtoneName = file.name;
    });

    print("✅ Ringtone selected: ${file.name}");
  }

  // Button 4: Set Nada Dering
  void _setRingtone() {
    if (_selectedRingtonePath == null) {
      print("⚠️ Belum pilih nada dering!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih nada dering dulu!')),
      );
      return;
    }

    // Set ke AlarmService
    AlarmService.instance.setCustomRingtone(_selectedRingtonePath);
    
    print("✅ Nada dering di-set: $_selectedRingtoneName");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nada dering di-set: $_selectedRingtoneName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gentle Wake-Up'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.music_note, size: 48, color: Colors.deepPurple),
                      const SizedBox(height: 12),
                      Text(
                        _selectedRingtoneName ?? 'Belum ada nada dering dipilih',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              // Button 1: Play Alarm
              ElevatedButton.icon(
                onPressed: () {
                  print('🔔 Play alarm');
                  AlarmService.instance.playAlarm(partnerName: 'Test');
                },
                icon: const Icon(Icons.alarm, size: 28),
                label: const Text(
                  'Play Alarm',
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

              // Button 2: Stop Alarm
              ElevatedButton.icon(
                onPressed: () {
                  print('🛑 Stop alarm');
                  AlarmService.instance.stopAlarm(method: 'manual_button');
                },
                icon: const Icon(Icons.stop_circle, size: 28),
                label: const Text(
                  'Stop Alarm',
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

              const Divider(),

              const SizedBox(height: 20),

              // Button 3: Pilih Nada Dering
              OutlinedButton.icon(
                onPressed: _pickRingtone,
                icon: const Icon(Icons.folder_open),
                label: const Text(
                  'Pilih Nada Dering',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.deepPurple, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Button 4: Set Nada Dering
              OutlinedButton.icon(
                onPressed: _setRingtone,
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'Set Nada Dering',
                  style: TextStyle(fontSize: 16),
                ),
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