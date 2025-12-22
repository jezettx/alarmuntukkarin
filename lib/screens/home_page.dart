// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/services/alarm_service.dart';
import 'package:alarm/services/pair_remote_service.dart';

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
  PairRemoteService? _pairService;
  
  String? _selectedRingtonePath;
  String? _selectedRingtoneName;
  
  DateTime? _lastCommandTime;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? deviceId = prefs.getString('device_id');
      
      if (deviceId == null) {
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('device_id', deviceId);
        print('✅ Generated Device ID: $deviceId');
      } else {
        print('✅ Loaded Device ID: $deviceId');
      }

      // ✅ LOAD SAVED RINGTONE (PERSIST!)
      _selectedRingtonePath = prefs.getString('custom_ringtone_path');
      _selectedRingtoneName = prefs.getString('custom_ringtone_name');
      
      if (_selectedRingtonePath != null) {
        print('✅ Loaded saved ringtone: $_selectedRingtoneName');
        AlarmService.instance.setCustomRingtone(_selectedRingtonePath);
      } else {
        print('⚠️ No saved ringtone - user must select one!');
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
    print('🔔 RING received from Firestore');
    
    if (_lastCommandTime != null) {
      final diff = DateTime.now().difference(_lastCommandTime!);
      if (diff.inSeconds < 3) {
        print('⏭️ Ignoring RING (sent by me)');
        return;
      }
    }
    
    print('✅ Playing alarm from partner');
    AlarmService.instance.playAlarm(partnerName: 'Pacar');
  }

  void _handleStop() {
    print('🛑 STOP received from Firestore');
    
    if (_lastCommandTime != null) {
      final diff = DateTime.now().difference(_lastCommandTime!);
      if (diff.inSeconds < 3) {
        print('⏭️ Ignoring STOP (sent by me)');
        return;
      }
    }
    
    print('✅ Stopping alarm from partner');
    AlarmService.instance.stopAlarm(method: 'remote_command');
  }

  @override
  void dispose() {
    _pairService?.dispose();
    super.dispose();
  }

  Future<void> _sendRing() async {
    if (_pairService == null) return;

    // ✅ VALIDATION: Harus sudah set custom ringtone dulu!
    if (_selectedRingtonePath == null || _selectedRingtonePath!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Pilih dan set nada dering dulu!\nScroll ke bawah → Pilih Nada Dering'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    print('🚀 Sending RING to partner...');
    _lastCommandTime = DateTime.now();
    
    await _pairService!.setRing();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏰ Alarm dikirim ke pacar!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendStop() async {
    if (_pairService == null) return;

    print('🛑 Sending STOP to partner...');
    _lastCommandTime = DateTime.now();
    
    await _pairService!.setStop();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛑 Stop dikirim ke pacar!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickRingtone() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result == null || result.files.isEmpty) {
      print("🔇 Cancelled");
      return;
    }

    final file = result.files.single;
    if (file.path == null) return;

    setState(() {
      _selectedRingtonePath = file.path;
      _selectedRingtoneName = file.name;
    });

    print("✅ Selected: ${file.name}");
    
    // Auto-show hint to click "Set Nada Dering"
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('👆 Sekarang tap "Set Nada Dering" untuk save!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _setRingtone() async {
    if (_selectedRingtonePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih nada dering dulu!')),
      );
      return;
    }

    // Set ke AlarmService
    AlarmService.instance.setCustomRingtone(_selectedRingtonePath);
    
    // ✅ SAVE ke SharedPreferences (PERSIST!)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_ringtone_path', _selectedRingtonePath!);
    await prefs.setString('custom_ringtone_name', _selectedRingtoneName ?? 'Custom');
    
    print('✅ Ringtone saved to preferences: $_selectedRingtoneName');
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Tersimpan: $_selectedRingtoneName'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasRingtone = _selectedRingtonePath != null && _selectedRingtonePath!.isNotEmpty;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gentle Wake-Up'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasRingtone 
                            ? '✅ $_selectedRingtoneName' 
                            : '⚠️ Belum ada nada dering!\nPilih audio di bawah.',
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