// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../services/background_service.dart';

/// Setup guide untuk battery optimization dan app reliability
class SetupGuidePage extends StatefulWidget {
  const SetupGuidePage({super.key});

  @override
  State<SetupGuidePage> createState() => _SetupGuidePageState();
}

class _SetupGuidePageState extends State<SetupGuidePage> {
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await BackgroundAlarmService.isServiceRunning();
    setState(() {
      _isServiceRunning = isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Guide'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Service Status Card
          Card(
            elevation: 4,
            color: _isServiceRunning ? Colors.green.shade50 : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    _isServiceRunning ? Icons.check_circle : Icons.warning,
                    size: 50,
                    color: _isServiceRunning ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isServiceRunning 
                        ? '✅ Background Service Active' 
                        : '⚠️ Background Service Inactive',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isServiceRunning ? Colors.green.shade800 : Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isServiceRunning
                        ? 'App is listening for alarms 24/7'
                        : 'Start service to receive alarms',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (!_isServiceRunning) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await BackgroundAlarmService.startService();
                        await _checkServiceStatus();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            '📱 Panduan Setup Reliability',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ikuti langkah berikut untuk alarm selalu bunyi!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 24),

          _buildInfoCard(
            '1️⃣ DISABLE Battery Optimization',
            'Settings → Apps → Gentle WakeUp → Battery → Unrestricted',
            Colors.red,
            'CRITICAL!',
          ),

          const SizedBox(height: 12),

          _buildInfoCard(
            '2️⃣ Enable AUTOSTART',
            'Settings → Apps → Gentle WakeUp → Autostart: ON',
            Colors.orange,
            'HIGH',
          ),

          const SizedBox(height: 12),

          _buildInfoCard(
            '3️⃣ JANGAN Swipe Notification',
            'Notification "💕 Active" HARUS tetap ada 24/7!',
            Colors.blue,
            'IMPORTANT',
          ),

          const SizedBox(height: 12),

          _buildInfoCard(
            '4️⃣ JANGAN Force Stop',
            'Jangan pakai "Close All Apps" atau RAM booster',
            Colors.red,
            'CRITICAL!',
          ),

          const SizedBox(height: 24),

          const Divider(thickness: 2),

          const SizedBox(height: 16),

          const Text(
            '📱 Device-Specific (Xiaomi/MIUI):',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('• Settings → Apps → Manage apps → Gentle WakeUp'),
          const Text('• Autostart: ON ✅'),
          const Text('• Battery saver: No restrictions ✅'),
          const Text('• Display pop-up windows: Allow ✅'),

          const SizedBox(height: 24),

          const Text(
            '🧪 Test Setup:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('1. Pastikan notification "💕 Active" muncul'),
          const Text('2. Lock HP (screen off)'),
          const Text('3. Minta pacar send alarm'),
          const Text('4. Wait 5-10 seconds'),
          const Text('✅ Kalau bunyi → SUKSES!'),
          const Text('❌ Kalau ga bunyi → Cek step 1-4 lagi'),

          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_circle, size: 28),
            label: const Text(
              'Setup Complete!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, Color color, String tag) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}