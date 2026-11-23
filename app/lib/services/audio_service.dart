/// Audio service for recording and playback.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// States of the audio service.
enum AudioState {
  idle,
  recording,
  processing,
  playing,
  error,
}

/// Service for managing audio recording and playback.
class AudioService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  AudioState _state = AudioState.idle;
  String? _errorMessage;

  AudioState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isRecording => _state == AudioState.recording;
  bool get isPlaying => _state == AudioState.playing;

  AudioService() {
    _player.onPlayerComplete.listen((_) {
      _state = AudioState.idle;
      notifyListeners();
    });
  }

  /// Start recording audio.
  Future<bool> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        _errorMessage = 'Microphone permission denied';
        _state = AudioState.error;
        notifyListeners();
        return false;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/speakaboo_recording.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
        ),
        path: path,
      );

      _state = AudioState.recording;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to start recording: $e';
      _state = AudioState.error;
      notifyListeners();
      return false;
    }
  }

  /// Stop recording and return the audio bytes.
  Future<Uint8List?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _state = AudioState.idle;
      notifyListeners();

      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
      return null;
    } catch (e) {
      _errorMessage = 'Failed to stop recording: $e';
      _state = AudioState.error;
      notifyListeners();
      return null;
    }
  }

  /// Play audio from bytes.
  Future<void> playAudio(Uint8List audioBytes) async {
    try {
      _state = AudioState.playing;
      notifyListeners();

      // Write to temp file for playback
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/speakaboo_playback.wav';
      await File(path).writeAsBytes(audioBytes);

      await _player.play(DeviceFileSource(path));
    } catch (e) {
      _errorMessage = 'Failed to play audio: $e';
      _state = AudioState.error;
      notifyListeners();
    }
  }

  /// Play multiple audio chunks sequentially.
  Future<void> playChunks(List<Uint8List> chunks) async {
    if (chunks.isEmpty) return;

    // Concatenate chunks for simple playback
    final totalBytes =
        chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final combined = Uint8List(totalBytes);
    var offset = 0;
    for (final chunk in chunks) {
      combined.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    await playAudio(combined);
  }

  /// Stop playback.
  Future<void> stopPlayback() async {
    await _player.stop();
    _state = AudioState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
