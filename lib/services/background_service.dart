// ignore_for_file: avoid_print, unrelated_type_equality_checks, unnecessary_import

import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ✅ ENTRY POINT TOP-LEVEL (WAJIB untuk native callback / tree-shaking)
@pragma('vm:entry-point')
void backgroundServiceOnStart(ServiceInstance service) {
  BackgroundAlarmService.onStart(service);
}

/// Background Service untuk listen Firestore commands 24/7
/// Runs as Foreground Service dengan persistent notification
@pragma('vm:entry-point')
class BackgroundAlarmService {
  /// Initialize and start the background service
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: backgroundServiceOnStart,
        autoStart: true,
        isForegroundMode: true,

        /// Pastikan service auto start lagi setelah reboot/kill
        autoStartOnBoot: true,

        /// ✅ FIX: pakai channel yang benar-benar sudah dibuat di app
        /// (channel lama 'alarm_service_channel' bikin crash: Bad notification for startForeground)
        notificationChannelId: 'gentle_wakeup_alarm',

        initialNotificationTitle: '💕 Gentle Wake-Up Active',
        initialNotificationContent: 'Ready to receive alarms from your partner',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    print('✅ Background service configured');
  }

  /// Start the service
  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
    print('🚀 Background service started');
  }

  /// Pastikan service tetap hidup (akan start ulang jika mati)
  static Future<void> ensureRunning() async {
    final isRunning = await isServiceRunning();
    if (!isRunning) {
      print('♻️ Background service not running - restarting...');
      await startService();
    }
  }

  /// Stop the service
  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
    print('🛑 Background service stopped');
  }

  /// Check if service is running
  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Main service entry point - runs in background isolate
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    print('🔵 Background service STARTED');

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stop').listen((event) {
      print('🔴 Background service STOPPING');
      service.stopSelf();
    });

    _startFirestoreListener(service);
  }

  /// Listen to Firestore for alarm commands
  static void _startFirestoreListener(ServiceInstance service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pairId = prefs.getString('pair_id') ?? 'yodha_karin_pair';
      final deviceId = prefs.getString('device_id') ?? 'unknown';

      print('👂 Listening to Firestore pair: $pairId');
      print('📱 My device ID: $deviceId');

      FirebaseFirestore.instance
          .collection('pairs')
          .doc(pairId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) {
          print('⚠️ Pair document does not exist');
          return;
        }

        final data = snapshot.data();
        if (data == null) return;

        final action = data['action'] as String?;
        final timestamp = data['timestamp'] as Timestamp?;

        print('📡 Firestore update: action=$action');

        if (action == 'ring') {
          _handleRingCommand(service, data);
        } else if (action == 'stop') {
          _handleStopCommand(service, data);
        }

        if (service is AndroidServiceInstance) {
          final timeStr =
              timestamp != null ? _formatTimestamp(timestamp) : 'Just now';

          service.setForegroundNotificationInfo(
            title: '💕 Gentle Wake-Up Active',
            content: 'Last update: $timeStr • Tap to open',
          );
        }
      }, onError: (error) {
        print('❌ Firestore listener error: $error');
      });

      print('✅ Firestore listener started');

      Timer.periodic(const Duration(seconds: 30), (timer) async {
        if (service is AndroidServiceInstance) {
          final isForeground = await service.isForegroundService();
          if (isForeground == false) {
            timer.cancel();
            return;
          }
        }

        print('💓 Service heartbeat - alive and listening');
      });
    } catch (e) {
      print('❌ Error starting Firestore listener: $e');
    }
  }

  /// Handle RING command from Firestore
  static void _handleRingCommand(
      ServiceInstance service, Map<String, dynamic> data) {
    print('🔔 RING command received in background service');

    service.invoke('ring', {
      'action': 'ring',
      'timestamp': data['timestamp']?.millisecondsSinceEpoch,
    });

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: '⏰ ALARM RINGING!',
        content: 'Wake up! Your partner is calling you',
      );
    }
  }

  /// Handle STOP command from Firestore
  static void _handleStopCommand(
      ServiceInstance service, Map<String, dynamic> data) {
    print('🛑 STOP command received in background service');

    service.invoke('stop', {
      'action': 'stop',
      'timestamp': data['timestamp']?.millisecondsSinceEpoch,
    });

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: '💕 Gentle Wake-Up Active',
        content: 'Ready to receive alarms',
      );
    }
  }

  /// Format timestamp for display
  static String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
