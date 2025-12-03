// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:alarm/services/pair_remote_service.dart';

class WakePage extends StatefulWidget {
  final String pairId;
  const WakePage({super.key, required this.pairId});

  @override
  State<WakePage> createState() => _WakePageState();
}

class _WakePageState extends State<WakePage> {
  late final PairRemoteService _remote;

  @override
  void initState() {
    super.initState();
    _remote = PairRemoteService(pairId: widget.pairId);
  }

  @override
  void dispose() {
    _remote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bangunkan Karin'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                print('DEBUG >>> TOMBOL BANGUNKAN DIKLIK');
                _remote.setRing();
              },
              child: const Text('🚨 Bangunkan sekarang'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                print('DEBUG >>> TOMBOL STOP DIKLIK (SENDER)');
                _remote.setStop();
              },
              child: const Text('Stop-in aja'),
            ),
          ],
        ),
      ),
    );
  }
}