// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:alarm/services/pair_remote_service.dart';

class AlarmPage extends StatefulWidget {
  final String pairId; // <- pakai huruf kecil d

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
      pairId: widget.pairId, // <- pakai widget.pairId
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
    print('DEBUG >>> _handleRing() DIPANGGIL');
    _playAlarm();
  }

  void _handleStop() {
    print('DEBUG >>> _handleStop() DIPANGGIL');
    _stopAlarm();
  }

  String _getRingtoneAsset() {
    switch (_currentRingtone) {
      case 'ringtone_1':
        return 'ringtones/ringtone_1.mp3';
      case 'ringtone_2':
        return 'ringtones/ringtone_2.mp3';
      default:
        return 'ringtones/ringtone_1.mp3';
    }
  }

  Future<void> _playAlarm() async {
    print('DEBUG >>> _playAlarm() DIPANGGIL (dari Firestore / lokal)');

    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);

    final assetPath = _getRingtoneAsset();
    print('DEBUG >>> mainkan asset: $assetPath');

    await _player.play(AssetSource(assetPath));
  }

  Future<void> _stopAlarm() async {
    print('DEBUG >>> _stopAlarm() DIPANGGIL (dari Firestore / lokal)');
    await _player.stop();
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
                print('DEBUG >>> TOMBOL SET RINGTONE DIKLIK');
                _remote.setRingtone('ringtone_1');
              },
              child: const Text('Set Ringtone ke "ringtone_1"'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () {
                print('DEBUG >>> TOMBOL RING DIKLIK');
                _remote.setRing();
              },
              child: const Text('Kirim RING ke pasangan'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () {
                print('DEBUG >>> TOMBOL STOP DIKLIK');
                _remote.setStop();
              },
              child: const Text('Kirim STOP ke pasangan'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () async {
                print('DEBUG >>> TOMBOL TES LOCAL AUDIO');
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
