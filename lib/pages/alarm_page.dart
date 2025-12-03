// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:alarm/services/pair_remote_service.dart';
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
  late final PairRemoteService _remote;
  final AudioPlayer _player = AudioPlayer();

  String _currentRingtone = 'default';

  @override
  void initState() {
    super.initState();

    _remote = PairRemoteService(
      pairId: widget.pairId,
    );

    _remote.listen(
      onRing: _handleRing,
      onStop: _handleStop,
      onRingtoneChange: (ringtone) {
        setState(() {
          _currentRingtone = ringtone;
        });
        if (kDebugMode) {
          print('Ringtone diganti jadi: $_currentRingtone');
        }
      },
    );
  }

  void _handleRing() {
    print('🔔 RING command received from partner');
    AlarmService.instance.playAlarm(partnerName: 'Karin');
  }

  void _handleStop() {
    print('🛑 STOP command received from partner');
    AlarmService.instance.stopAlarm(method: 'remote_command');
  }

  @override
  void dispose() {
    _remote.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Receiver'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PairID: ${widget.pairId}'),
            const SizedBox(height: 8),
            Text('Ringtone sekarang: $_currentRingtone'),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                print('🔔 Kirim RING command');
                _remote.setRing();
              },
              child: const Text('Kirim RING ke pasangan'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () {
                print('🛑 Kirim STOP command');
                _remote.setStop();
              },
              child: const Text('Kirim STOP ke pasangan'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () {
                print('🎵 Set ringtone');
                _remote.setRingtone('ringtone_1');
              },
              child: const Text('Set Ringtone ke "ringtone_1"'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () async {
                print('🧪 Test local audio playback');
                await _player.stop();
                await _player.setReleaseMode(ReleaseMode.loop);
                await _player.play(AssetSource('ringtones/ringtone_1.mp3'));
              },
              child: const Text('Tes play langsung'),
            ),
          ],
        ),
      ),
    );
  }
}