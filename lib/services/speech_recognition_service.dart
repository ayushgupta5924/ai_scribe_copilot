import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechRecognitionService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  List<String> _conversationLog = [];

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  List<String> get conversationLog => _conversationLog;

  Future<bool> initialize() async {
    return await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );
  }

  Future<void> startListening() async {
    if (!_isListening && await _speech.initialize()) {
      _isListening = true;
      _speech.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          if (result.finalResult) {
            _addToConversation(_recognizedText);
          }
          notifyListeners();
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        onSoundLevelChange: (level) => debugPrint('Sound level: $level'),
      );
      notifyListeners();
    }
  }

  void _addToConversation(String text) {
    if (text.isNotEmpty) {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _conversationLog.add('[$timestamp] $text');
      _recognizedText = '';
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  String getFullTranscript() {
    return _conversationLog.join('\n\n');
  }

  void clearTranscript() {
    _conversationLog.clear();
    _recognizedText = '';
    notifyListeners();
  }
}