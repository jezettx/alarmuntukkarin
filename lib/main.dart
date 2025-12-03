import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'pages/alarm_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // pakai config dari android (google-services.json)
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AlarmPage(pairId: 'demoPair'), // <- cocok dengan constructor di atas
    );
  }
}