import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class NativeFeaturesService {
  static const MethodChannel _channel = MethodChannel('medical_transcription/native');

  // Audio level monitoring
  static Stream<double> get audioLevelStream {
    return const EventChannel('medical_transcription/audio_level')
        .receiveBroadcastStream()
        .map((level) => (level as num).toDouble());
  }

  // Native share functionality
  static Future<void> shareTranscript(String transcript, String patientName) async {
    try {
      await _channel.invokeMethod('shareText', {
        'text': transcript,
        'subject': 'Medical Transcript - $patientName',
      });
    } catch (e) {
      debugPrint('Share failed: $e');
    }
  }

  // Haptic feedback
  static Future<void> lightHaptic() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> mediumHaptic() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavyHaptic() async {
    await HapticFeedback.heavyImpact();
  }

  // System notifications
  static Future<void> showRecordingNotification(String message) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'title': 'Medical Transcription',
        'message': message,
        'ongoing': true,
      });
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }

  static Future<void> hideRecordingNotification() async {
    try {
      await _channel.invokeMethod('hideNotification');
    } catch (e) {
      debugPrint('Hide notification failed: $e');
    }
  }

  // Audio gain control
  static Future<void> setAudioGain(double gain) async {
    try {
      await _channel.invokeMethod('setAudioGain', {'gain': gain});
    } catch (e) {
      debugPrint('Set audio gain failed: $e');
    }
  }
}