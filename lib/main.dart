// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/alarm_service.dart';
import 'pages/alarm_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  print('✅ Firebase initialized');

  // Initialize AlarmService (notification + screen listener + wakelock)
  await AlarmService.instance.init();
  print('✅ AlarmService initialized');

  // Request permissions
  await _requestPermissions();

  runApp(const MyApp());
}

/// Request all necessary permissions for alarm system
Future<void> _requestPermissions() async {
  print('📱 Requesting permissions...');

  // Request notification permission (Android 13+)
  final notifStatus = await Permission.notification.request();
  print('  • Notification: $notifStatus');

  // Request exact alarm permission (Android 12+)
  final alarmStatus = await Permission.scheduleExactAlarm.request();
  print('  • Exact Alarm: $alarmStatus');

  // Request ignore battery optimization (critical for Xiaomi!)
  final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
  print('  • Battery Optimization: $batteryStatus');

  // Optional: System alert window (for overlay features)
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
      home: AlarmPage(pairId: 'demoPair'),
    );
  }
}