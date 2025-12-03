// ignore_for_file: avoid_print

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Unified AlarmService with Hybrid Approach:
/// - Primary: Auto-stop when app comes to foreground (user interaction)
/// - Backup: Manual stop button in notification
/// - Wakelock: Keep screen ON during alarm
class AlarmService with WidgetsBindingObserver {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  final AudioPlayer _player = AudioPlayer();
  String? _customRingtone;

  bool _isAlarmActive = false;
  DateTime? _alarmStartTime;

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await initNotification();
    _initAppLifecycleListener();
    _configureAudioPlayer();
    print("✅ AlarmService initialized successfully");
  }

  void _configureAudioPlayer() {
    _player.setReleaseMode(ReleaseMode.loop);
    _player.setVolume(1.0);
  }

  void _initAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(this);
    print("✅ App lifecycle listener initialized");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("📱 App lifecycle changed: $state");
    
    if (state == AppLifecycleState.resumed && _isAlarmActive) {
      final timeSinceStart = _alarmStartTime != null 
          ? DateTime.now().difference(_alarmStartTime!).inSeconds 
          : 0;
      
      if (timeSinceStart >= 2) {
        print("🟢 App resumed (user interaction) → Auto-stopping alarm");
        stopAlarm(method: 'auto_user_interaction');
      } else {
        print("⏱️ Alarm just started, waiting for user interaction...");
      }
    }
  }

  Future<void> initNotification() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        print("🔔 Notification action: ${response.actionId}");

        if (response.actionId == 'stop_alarm' || response.payload == 'stop') {
          stopAlarm(method: 'manual_notification');
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'gentle_wakeup_alarm',
      'Gentle Wake-Up Alarm',
      description: 'Alarm notifications from your partner',
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
      enableLights: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print("✅ Notification system initialized");
  }

  void setCustomRingtone(String? path) {
    _customRingtone = path;
    print("🎵 Custom ringtone set: ${path ?? 'none'}");
  }

  Future<void> _showAlarmNotification({required String partnerName}) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'gentle_wakeup_alarm',
      'Gentle Wake-Up Alarm',
      channelDescription: 'Alarm notifications from your partner',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'stop_alarm',
          '🛑 STOP ALARM',
          showsUserInterface: true,
        ),
      ],
    );

    const NotificationDetails notifDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      9999,
      '⏰ Wake Up! - $partnerName',
      'Alarm akan stop otomatis saat kamu buka app.\nAtau tap tombol STOP di bawah.',
      notifDetails,
      payload: 'stop',
    );
  }

  Future<void> playAlarm({String partnerName = 'Partner'}) async {
    if (_isAlarmActive) {
      print("⚠️ Alarm already active, ignoring duplicate call");
      return;
    }

    print("🚨 ========== ALARM STARTED ==========");
    _isAlarmActive = true;
    _alarmStartTime = DateTime.now();

    try {
      await WakelockPlus.enable();
      print("🔒 Wakelock enabled - screen will stay ON");

      await _player.stop();
      
      if (_customRingtone != null) {
        print("🎵 Playing custom ringtone: $_customRingtone");
        await _player.play(DeviceFileSource(_customRingtone!));
      } else {
        print("🎵 Playing default alarm sound");
        await _player.play(AssetSource('sounds/alarm.mp3'));
      }

      await _showAlarmNotification(partnerName: partnerName);
      print("🔔 Notification shown with STOP button");

      print("✅ Alarm playing - waiting for:");
      print("   • User interaction/resume app (auto-stop) ← PRIMARY");
      print("   • Notification button tap (manual) ← BACKUP");

    } catch (e) {
      print("❌ Error playing alarm: $e");
      _isAlarmActive = false;
      await WakelockPlus.disable();
    }
  }

  Future<void> stopAlarm({String method = 'unknown'}) async {
    if (!_isAlarmActive) {
      print("⚠️ Alarm not active, nothing to stop");
      return;
    }

    print("🛑 ========== ALARM STOPPED ==========");
    print("   Method: $method");
    
    _isAlarmActive = false;

    try {
      await _player.stop();
      print("✅ Audio stopped");

      await WakelockPlus.disable();
      print("✅ Wakelock disabled");

      await flutterLocalNotificationsPlugin.cancel(9999);
      print("✅ Notification cleared");

    } catch (e) {
      print("❌ Error stopping alarm: $e");
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _player.dispose();
    await WakelockPlus.disable();
    print("🧹 AlarmService disposed");
  }
}