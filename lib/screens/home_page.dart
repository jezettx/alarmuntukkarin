// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/alarm_service.dart';
import '../services/pair_remote_service.dart';
import 'package:alarm/config/app_config.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _lastMessageTitle;
  String? _lastMessageBody;

  late final PairRemoteService _pairService;

  @override
  void initState() {
    super.initState();

    // pakai layanan singleton
    final alarm = AlarmService.instance;

    // pairId HARUS kamu ganti nanti jadi 'yodha' / 'pacar'
    _pairService = PairRemoteService(pairId: AppConfig.pairId);

    // Firestore listener
    _pairService.listen(
      onRing: alarm.playAlarm,
      onStop: alarm.stopAlarm,
      onRingtoneChange: (rt) {
        // abaikan dulu, karena fitur ringtone remote belum dipakai
        print("DEBUG >>> Ringtone berubah di Firestore: $rt");
      },
    );

    // FCM listener saat app foreground
    FirebaseMessaging.onMessage.listen((msg) {
      final title = msg.notification?.title ?? '(tanpa judul)';
      final body = msg.notification?.body ?? '(tanpa teks)';

      setState(() {
        _lastMessageTitle = title;
        _lastMessageBody = body;
      });

      alarm.playAlarm();
    });

    // FCM listener saat notifikasi dibuka
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final title = msg.notification?.title ?? '(tanpa judul)';
      final body = msg.notification?.body ?? '(tanpa teks)';

      setState(() {
        _lastMessageTitle = '$title (dibuka dari notif)';
        _lastMessageBody = body;
      });

      alarm.playAlarm();
    });
  }

  @override
  void dispose() {
    _pairService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remote Alarm v1')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                print('DEBUG >>> Tombol REMOTE RING ditekan');
                await _pairService.setRing();
              },
              child: const Text('Bunyikan alarm (remote)'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () async {
                print('DEBUG >>> Tombol REMOTE STOP ditekan');
                await _pairService.setStop();
              },
              child: const Text('Matikan alarm (remote)'),
            ),

            const SizedBox(height: 24),
            Text(_lastMessageTitle ?? '-'),
            Text(_lastMessageBody ?? ''),
          ],
        ),
      ),
    );
  }
}
