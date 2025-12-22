// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/alarm_service.dart';
import '../services/pair_remote_service.dart';
import 'package:alarm/config/app_config.dart';

class PartnerRingtonePage extends StatefulWidget {
  const PartnerRingtonePage({super.key});

  @override
  State<PartnerRingtonePage> createState() => _PartnerRingtonePageState();
}

class _PartnerRingtonePageState extends State<PartnerRingtonePage> {
  late final PairRemoteService _pairService;
  String? _ringtoneName;

  @override
  void initState() {
    super.initState();
    _pairService = PairRemoteService(pairId: AppConfig.pairId);
  }

  @override
  void dispose() {
    _pairService.dispose();
    super.dispose();
  }

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

    AlarmService.instance.setCustomRingtone(path);

    setState(() {
      _ringtoneName = file.name;
    });

    print("✅ Ringtone selected: ${file.name}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller Alarm Pacar'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _pickRingtone,
              child: const Text('Pilih Nada Dering'),
            ),

            const SizedBox(height: 12),

            Text(
              _ringtoneName == null
                  ? 'Belum ada nada dering dipilih'
                  : 'Dipilih: $_ringtoneName',
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                print("🔔 Bunyikan alarm (remote + lokal)");
                await _pairService.setRing();
                AlarmService.instance.playAlarm(partnerName: 'You');
              },
              child: const Text('🔔 Bunyikan Alarm'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () async {
                print("🛑 Matikan alarm (remote + lokal)");
                await _pairService.setStop();
                AlarmService.instance.stopAlarm(method: 'manual_button');
              },
              child: const Text('🛑 Matikan Alarm'),
            ),
          ],
        ),
      ),
    );
  }
}