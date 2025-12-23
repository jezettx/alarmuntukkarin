// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/alarm_service.dart';
import 'services/background_service.dart';
import 'pages/alarm_page.dart';

/// ✅ WAJIB TOP-LEVEL untuk background/terminated FCM handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // jangan init UI di sini
  print('📩 [BG] messageId: ${message.messageId}');
  print('📩 [BG] data: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Initialize Firebase
  await Firebase.initializeApp();
  print('✅ Firebase initialized');

  // ✅ register background handler sebelum runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 2) Initialize AlarmService (notification channel dibuat di sini)
  await AlarmService.instance.init();
  print('✅ AlarmService initialized');

  // 3) Request permissions DULU
  await _requestPermissions();

  // ✅ minta permission FCM (iOS & Android 13+ notif)
  final fm = FirebaseMessaging.instance;
  await fm.requestPermission(alert: true, badge: true, sound: true);

  final token = await fm.getToken();
  print('✅ FCM Token: $token');

  // ✅ listener saat app foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 [FG] messageId: ${message.messageId}');
    print('📩 [FG] data: ${message.data}');
    // nanti di step berikutnya: kalau data['action']=='ring' => play alarm
  });

  // 4) Save default pairId if not set
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('pair_id')) {
    await prefs.setString('pair_id', 'yodha_karin_pair');
    print('✅ Default pairId saved');
  }

  // 5) Configure background service SETELAH permission beres
  await BackgroundAlarmService.initialize();
  print('✅ Background service configured');

  // 6) Start background service
  await BackgroundAlarmService.startService();
  print('🚀 Background service started');

  // ✅ Pastikan service tetap hidup walau app di-kill / reboot
  await BackgroundAlarmService.ensureRunning();

  runApp(const MyApp());
}

/// Request all necessary permissions for alarm system
Future<void> _requestPermissions() async {
  print('📱 Requesting permissions...');

  final notifStatus = await Permission.notification.request();
  print('  • Notification: $notifStatus');

  final alarmStatus = await Permission.scheduleExactAlarm.request();
  print('  • Exact Alarm: $alarmStatus');

  final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
  print('  • Battery Optimization: $batteryStatus');

  final systemAlertStatus = await Permission.systemAlertWindow.request();
  print('  • System Alert: $systemAlertStatus');

  print('✅ Permissions requested');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Gentle Wake-Up',
      debugShowCheckedModeBanner: false,
      home: AlarmPage(pairId: 'yodha_karin_pair'),
    );
  }
}