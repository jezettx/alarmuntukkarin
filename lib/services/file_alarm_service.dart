// ignore_for_file: avoid_print

import 'package:audioplayers/audioplayers.dart';

class FileAlarmService {
  final AudioPlayer _player = AudioPlayer();
  String? _filePath; // path file yg dipilih dari file picker
  FileAlarmService() {
    _player.setReleaseMode(ReleaseMode.stop);
    _player.setVolume(0.6);
  }

  void setFilePath(String path) {
    _filePath = path;
    print("DEBUG >>> ringtone path diset: $path");
  }

  Future<void> playAlarm() async {
    if (_filePath == null) {
      print("DEBUG >>> belum ada file yang dipilih");
      return;
    }

    print("DEBUG >>> playAlarm pakai file: $_filePath");

    try {
      await _player.stop();
      await _player.play(
        DeviceFileSource(_filePath!), // mainin file picker
      );
    } catch (e) {
      print("Gagal play file: $e");
    }
  }

  Future<void> stopAlarm() async {
    print("DEBUG >>> stopAlarm dipanggil");
    try {
      await _player.stop();
    } catch (e) {
      print("Gagal stop: $e");
    }
  }

  void dispose() {
    _player.dispose();
  }
}
