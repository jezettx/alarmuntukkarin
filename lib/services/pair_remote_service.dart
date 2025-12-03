// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PairRemoteService {
  final String pairId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  PairRemoteService({
    this.pairId = 'widget.pairId'
    }
  );

  void listen({
    required VoidCallback onRing,
    required VoidCallback onStop,
    required Function(String ringtone) onRingtoneChange,
  }) {
    _sub = _db.collection('pairs').doc(pairId).snapshots().listen((snap) {
      if (!snap.exists) return;

      final data = snap.data();
      final action = data?['action'];
      final ringtone = data?['ringtone'];

      print('Firestore action: $action, ringtone: $ringtone');

      if (action == 'ring') onRing();
      if (action == 'stop') onStop();
      if (ringtone != null) onRingtoneChange(ringtone);
    });
  }

  Future<void> setRing() async {
    await _db.collection('pairs').doc(pairId).set({'action': 'ring'}, SetOptions(merge: true));
  }

  Future<void> setStop() async {
    await _db.collection('pairs').doc(pairId).set({'action': 'stop'}, SetOptions(merge: true));
  }

  Future<void> setRingtone(String ringtone) async {
    await _db.collection('pairs').doc(pairId).set({'ringtone': ringtone}, SetOptions(merge: true));
  }

  void dispose() {
    _sub?.cancel();
  }
}