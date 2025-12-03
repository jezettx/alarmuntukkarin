// ignore_for_file: avoid_print

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  final AudioPlayer _player = AudioPlayer();
  String? _filePath;

  Timer? _autoStopTimer;

  // Plugin notifikasi (global)
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // -----------------------------------------------------------
  //  STEP 1: Inisialisasi notifikasi
  // -----------------------------------------------------------
  Future<void> initNotification() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        print(
            "DEBUG >>> Notif action ditekan, actionId = ${response.actionId}, payload = ${response.payload}");

        // Apapun yang diklik di notif (body / tombol), kita anggap perintah STOP
        AlarmService.instance.stopAlarm();
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'remote_alarm_channel',
      'Remote Alarm',
      description: 'Channel untuk alarm remote',
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
      enableLights: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print("DEBUG >>> Notifikasi berhasil diinisialisasi");
  }

  // -----------------------------------------------------------
  //  SET RINGTONE (dari file picker)
  // -----------------------------------------------------------
  void setFilePath(String path) {
    _filePath = path;
    print("DEBUG >>> ringtone path diset: $path");
  }

  // -----------------------------------------------------------
  //  Notifikasi Alarm + Tombol STOP
  // -----------------------------------------------------------
  Future<void> showAlarmNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'remote_alarm_channel',
      'Remote Alarm',
      channelDescription: 'Notifikasi untuk alarm remote',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'stop_alarm', // actionId
          'STOP ALARM', // label tombol
        ),
      ],
    );

    const NotificationDetails notifDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      1001,
      'ERINN BANGUNN 🚨',
      'Alarm lagi bunyi, pencet STOP ALARM.',
      notifDetails,
    );
  }
  // -----------------------------------------------------------
  //  PLAY ALARM + AUTO STOP (10 DETIK)
  // -----------------------------------------------------------
  Future<void> playAlarm() async {
    print("DEBUG >>> playAlarm DIPANGGIL (file: $_filePath)");

    try {
      await _player.stop();
      // Mainkan suara
      if (_filePath != null) {
        await _player.play(DeviceFileSource(_filePath!));
      } else {
        await _player.play(AssetSource('sounds/alarm.mp3'));
      }

      // Munculkan notifikasi alarm
      await showAlarmNotification();

      // Reset timer sebelumnya jika ada
      _autoStopTimer?.cancel();

      // Mulai timer 10 detik
      _autoStopTimer = Timer(const Duration(seconds: 10), () {
        print("DEBUG >>> AUTO STOP (10 detik)");
        stopAlarm();
      });
    } catch (e) {
      print("Gagal play file: $e");
    }
  }

  // -----------------------------------------------------------
  //  STOP ALARM (manual / notif / auto)
  // -----------------------------------------------------------
  Future<void> stopAlarm() async {
    print("DEBUG >>> stopAlarm dipanggil");

    // Stop suara
    await _player.stop();

    // Stop timer kalau masih aktif
    _autoStopTimer?.cancel();

    // Hapus notifikasi alarm
    await flutterLocalNotificationsPlugin.cancel(1001);
  }
}