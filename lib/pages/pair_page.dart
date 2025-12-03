import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm_page.dart';

class PairPage extends StatefulWidget {
  const PairPage({super.key});

  @override
  State<PairPage> createState() => _PairPageState();
}

class _PairPageState extends State<PairPage> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _savePairId() async {
    final prefs = await SharedPreferences.getInstance();
    final pairId = _controller.text.trim();

    if (pairId.isEmpty) {
      return;
    }

    await prefs.setString('pairId', pairId);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AlarmPage(pairId: pairId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Masukkan Pair Code")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kode Pair:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "contoh: yodha_karin_pair",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePairId,
              child: const Text("Hubungkan"),
            ),
          ],
        ),
      ),
    );
  }
}