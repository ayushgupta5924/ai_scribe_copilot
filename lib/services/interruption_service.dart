import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'audio_service.dart';

class InterruptionService extends ChangeNotifier {
  final AudioService _audioService;
  bool _wasRecordingBeforeInterruption = false;

  InterruptionService(this._audioService) {
    _listenToAppLifecycle();
  }

  void _listenToAppLifecycle() {
    SystemChannels.lifecycle.setMessageHandler((message) async {
      switch (message) {
        case 'AppLifecycleState.paused':
          // Keep recording in background - no action needed
          debugPrint('App paused - recording continues in background');
          break;

        case 'AppLifecycleState.inactive':
          // Phone call detected - pause recording
          if (_audioService.isRecording && !_audioService.isPaused) {
            _wasRecordingBeforeInterruption = true;
            _audioService.pauseRecording();
            debugPrint('Recording paused - phone call detected');
          }
          break;
        case 'AppLifecycleState.resumed':
          // Phone call ended - resume recording
          if (_wasRecordingBeforeInterruption) {
            _audioService.resumeRecording();
            _wasRecordingBeforeInterruption = false;
            debugPrint('Recording resumed - call ended');
          }
          break;
        case 'AppLifecycleState.detached':
          await _handleAppTermination();
          break;
      }
      return null;
    });
  }

  Future<void> _handleAppTermination() async {
    // Save current state before app terminates
    if (_audioService.isRecording) {
      await _audioService.stopRecording();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}