// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PairRemoteService {
  final String pairId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  PairRemoteService({
    required this.pairId,
  });

  void listen({
    required VoidCallback onRing,
    required VoidCallback onStop,
    required Function(String ringtone) onRingtoneChange,
  }) {
    _sub = _db.collection('pairs').doc(pairId).snapshots().listen((snap) {
      if (!snap.exists) {
        print('⚠️ Pair document does not exist: $pairId');
        return;
      }

      final data = snap.data();
      final action = data?['action'];
      final ringtone = data?['ringtone'];
      final timestamp = data?['timestamp'];

      print('📡 Firestore event:');
      print('   • action: $action');
      print('   • ringtone: $ringtone');
      print('   • timestamp: $timestamp');

      if (action == 'ring') onRing();
      if (action == 'stop') onStop();
      if (ringtone != null) onRingtoneChange(ringtone);
    });

    print('👂 Listening to pair: $pairId');
  }

  Future<void> setRing() async {
    try {
      await _db.collection('pairs').doc(pairId).set({
        'action': 'ring',
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'user',
      }, SetOptions(merge: true));
      
      print('📤 RING command sent to $pairId');
    } catch (e) {
      print('❌ Failed to send RING: $e');
    }
  }

  Future<void> setStop() async {
    try {
      await _db.collection('pairs').doc(pairId).set({
        'action': 'stop',
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'user',
      }, SetOptions(merge: true));
      
      print('📤 STOP command sent to $pairId');
    } catch (e) {
      print('❌ Failed to send STOP: $e');
    }
  }

  Future<void> setRingtone(String ringtone) async {
    try {
      await _db.collection('pairs').doc(pairId).set({
        'ringtone': ringtone,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('🎵 Ringtone updated: $ringtone');
    } catch (e) {
      print('❌ Failed to update ringtone: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    print('🧹 PairRemoteService disposed');
  }
}