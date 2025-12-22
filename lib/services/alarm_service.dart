// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AlarmService with WidgetsBindingObserver {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  final AudioPlayer _player = AudioPlayer();
  String? _customRingtone;

  bool _isAlarmActive = false;
  DateTime? _alarmStartTime;

  static const platform = MethodChannel('com.childe.alarm/screen_unlock');
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await initNotification();
    _initAppLifecycleListener();
    _initNativeScreenUnlockListener();
    _configureAudioPlayer();
    print("✅ AlarmService initialized successfully");
  }

  void _configureAudioPlayer() {
    _player.setReleaseMode(ReleaseMode.loop);
    _player.setVolume(1.0);
    
    _player.onPlayerStateChanged.listen((state) {
      print("🎵 AudioPlayer state: $state");
    });
    
    print("✅ AudioPlayer configured");
  }

  void _initAppLifecycleListener() {
    WidgetsBinding.instance.addObserver(this);
    print("✅ App lifecycle listener initialized");
  }

  void _initNativeScreenUnlockListener() {
    platform.setMethodCallHandler((call) async {
      print("📱 Native method call: ${call.method}");
      
      switch (call.method) {
        case 'onScreenUnlocked':
          print("🔓 Screen UNLOCKED detected from native!");
          _handleScreenUnlock();
          break;
        case 'onScreenOn':
          print("💡 Screen ON detected from native");
          break;
        default:
          print("⚠️ Unknown method: ${call.method}");
      }
    });
    
    print("✅ Native screen unlock listener initialized");
  }

  void _handleScreenUnlock() {
    if (!_isAlarmActive) return;
    
    final timeSinceStart = _alarmStartTime != null 
        ? DateTime.now().difference(_alarmStartTime!).inSeconds 
        : 0;
    
    if (timeSinceStart >= 2) {
      print("🎯 HYBRID: Screen unlock → Auto-stopping alarm!");
      stopAlarm(method: 'auto_screen_unlock');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("📱 App lifecycle: $state");
    
    if (state == AppLifecycleState.resumed && _isAlarmActive) {
      final timeSinceStart = _alarmStartTime != null 
          ? DateTime.now().difference(_alarmStartTime!).inSeconds 
          : 0;
      
      if (timeSinceStart >= 2) {
        print("🟢 App resumed → Auto-stopping alarm");
        stopAlarm(method: 'auto_user_interaction');
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
      'Unlock HP atau TAP tombol STOP.',
      notifDetails,
      payload: 'stop',
    );
  }

  Future<void> playAlarm({String partnerName = 'Partner'}) async {
    print("🔔 playAlarm() called");
    
    if (_isAlarmActive) {
      print("⚠️ Alarm already active, ignoring");
      return;
    }

    if (_customRingtone == null || _customRingtone!.isEmpty) {
      print("❌ No custom ringtone set!");
      return;
    }

    print("🚨 ========== ALARM STARTED ==========");
    _isAlarmActive = true;
    _alarmStartTime = DateTime.now();

    try {
      await WakelockPlus.enable();
      print("🔒 Wakelock enabled");

      await _player.stop();
      
      // VALIDATE FILE
      print("📂 Validating: $_customRingtone");
      final file = File(_customRingtone!);
      
      if (!await file.exists()) {
        print("❌ FILE NOT FOUND!");
        throw Exception("Ringtone file not found! Re-select audio.");
      }
      
      final size = await file.length();
      print("✅ File OK: ${(size / 1024 / 1024).toStringAsFixed(2)} MB");
      
      // PLAY
      print("🎵 Starting playback...");
      await _player.play(DeviceFileSource(_customRingtone!));
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final state = _player.state;
      print("🎵 Player state: $state");
      
      if (state != PlayerState.playing) {
        print("⚠️ Audio NOT playing! State: $state");
      } else {
        print("✅✅✅ AUDIO IS PLAYING!");
      }

      await _showAlarmNotification(partnerName: partnerName);
      print("🔔 Notification shown");

    } catch (e, stack) {
      print("❌ ERROR: $e");
      print("📍 Stack: $stack");
      _isAlarmActive = false;
      _alarmStartTime = null;
      await WakelockPlus.disable();
      rethrow;
    }
  }

  Future<void> stopAlarm({String method = 'unknown'}) async {
    if (!_isAlarmActive) {
      print("⚠️ Alarm not active");
      return;
    }

    print("🛑 ========== ALARM STOPPED ==========");
    print("   Method: $method");
    
    _isAlarmActive = false;
    _alarmStartTime = null;
    
    print("✅ State reset!");

    try {
      await _player.stop();
      await WakelockPlus.disable();
      await flutterLocalNotificationsPlugin.cancel(9999);
      print("✅ Cleanup complete");
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _player.dispose();
    await WakelockPlus.disable();
    print("🧹 Disposed");
  }
}