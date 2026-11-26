/// Audio service for recording and playback.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  final FlutterTts _tts = FlutterTts();
  bool _ttsInitialized = false;

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

  /// Play audio from bytes and wait until playback completes (or times out).
  Future<void> playAudio(Uint8List audioBytes) async {
    try {
      _state = AudioState.playing;
      notifyListeners();

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/speakaboo_playback_${DateTime.now().microsecondsSinceEpoch}.wav';
      await File(path).writeAsBytes(audioBytes);

      final completer = Completer<void>();
      late StreamSubscription<void> sub;
      sub = _player.onPlayerComplete.listen((_) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      });

      await _player.play(DeviceFileSource(path));
      await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          sub.cancel();
        },
      );
      _state = AudioState.idle;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to play audio: $e';
      _state = AudioState.error;
      notifyListeners();
    }
  }

  /// Play multiple WAV chunks sequentially so separate RIFF headers are respected.
  Future<void> playChunks(List<Uint8List> chunks) async {
    if (chunks.isEmpty) return;
    for (final chunk in chunks) {
      if (chunk.isEmpty) continue;
      await playAudio(chunk);
    }
  }

  /// Speak text using Android/iOS built-in on-device TTS engine (real voice fallback).
  Future<bool> speakOnDevice(String text, {double speed = 1.0}) async {
    if (text.trim().isEmpty) return false;
    try {
      _state = AudioState.playing;
      notifyListeners();
      if (!_ttsInitialized) {
        await _tts.setLanguage('en-US');
        await _tts.awaitSpeakCompletion(true);
        _ttsInitialized = true;
      }
      final clampedRate = (speed * 0.5).clamp(0.25, 0.9);
      await _tts.setSpeechRate(clampedRate);
      await _tts.speak(text);
      _state = AudioState.idle;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AudioService] speakOnDevice error: $e');
      _state = AudioState.idle;
      notifyListeners();
      return false;
    }
  }

  /// Stop playback.
  Future<void> stopPlayback() async {
    await _player.stop();
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('[AudioService] stopPlayback tts stop error: $e');
    }
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
