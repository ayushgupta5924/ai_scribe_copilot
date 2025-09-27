import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class LiveTranscriptionService extends ChangeNotifier {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _currentText = '';
  List<String> _transcriptLines = [];
  double _confidence = 1.0;

  bool get isListening => _isListening;
  String get currentText => _currentText;
  List<String> get transcriptLines => _transcriptLines;
  double get confidence => _confidence;

  Future<bool> initialize() async {
    try {
      _speech = stt.SpeechToText();
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('Init Speech status: $val'),
        onError: (val) => debugPrint('Init Speech error: $val'),
      );
      debugPrint('Speech recognition initialized: $available');
      return available;
    } catch (e) {
      debugPrint('Speech initialization error: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    try {
      if (!_isListening && _speech.isAvailable) {
        _isListening = true;
        await _speech.listen(
          onResult: (val) {
            debugPrint('Speech result: ${val.recognizedWords}');
            _currentText = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
            
            // Add completed phrases to transcript lines
            if (val.finalResult && _currentText.isNotEmpty) {
              _transcriptLines.add(_currentText);
              debugPrint('Added to transcript: $_currentText');
              _currentText = '';
            }
            
            notifyListeners();
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
          localeId: 'en_US',
        );
        
        notifyListeners();
        debugPrint('Speech recognition started successfully');
      } else {
        debugPrint('Speech not available or already listening');
      }
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        notifyListeners();
        debugPrint('Speech recognition stopped');
      }
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  void clearTranscript() {
    _transcriptLines.clear();
    _currentText = '';
    notifyListeners();
  }
  
  void addTestTranscript() {
    _transcriptLines.addAll([
      'Hello, this is a test transcript.',
      'The speech recognition is working.',
      'This text should appear in the transcript screen.',
    ]);
    notifyListeners();
    debugPrint('Added test transcript lines: ${_transcriptLines.length}');
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}