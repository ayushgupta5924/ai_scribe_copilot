import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/audio_chunk.dart';
import 'database_service.dart';
import 'upload_service.dart';
import 'native_features_service.dart';
import 'transcript_service.dart';
import 'live_transcription_service.dart';

class AudioService extends ChangeNotifier {
  FlutterSoundRecorder? _recorder;
  final DatabaseService _db = DatabaseService();
  final UploadService _upload = UploadService();
  final TranscriptService _transcriptService = TranscriptService();
  LiveTranscriptionService? _liveTranscription;
  
  Function(String sessionId)? onRecordingComplete;
  
  AudioService() {
    _recoverFromCrash();
  }
  
  Future<void> _recoverFromCrash() async {
    try {
      final unuploadedChunks = await _db.getUnuploadedChunks();
      for (final chunk in unuploadedChunks) {
        _upload.uploadChunk(chunk);
      }
      debugPrint('Recovered ${unuploadedChunks.length} chunks after restart');
    } catch (e) {
      debugPrint('Recovery failed: $e');
    }
  }
  
  Timer? _chunkTimer;
  String? _currentSessionId;
  int _sequenceNumber = 0;
  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentFilePath;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get currentSessionId => _currentSessionId;
  
  void setLiveTranscriptionService(LiveTranscriptionService service) {
    _liveTranscription = service;
  }

  Future<bool> startRecording({String? patientId, String? patientName}) async {
    try {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      
      if (await Permission.microphone.request().isGranted) {
        // Start backend session
        _currentSessionId = await _upload.startSession(patientId, patientName: patientName);
        if (_currentSessionId == null) {
          debugPrint('Failed to start backend session');
          return false;
        }
        
        _sequenceNumber = 0;
        
        final session = RecordingSession(
          id: _currentSessionId!,
          startTime: DateTime.now(),
          status: 'recording',
          patientId: patientId,
        );
        await _db.insertSession(session);

        await _startChunkRecording();
        _isRecording = true;
        _isPaused = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
    return false;
  }

  Future<void> pauseRecording() async {
    if (_isRecording && !_isPaused) {
      await _stopCurrentChunk();
      _isPaused = true;
      notifyListeners();
    }
  }

  Future<void> resumeRecording() async {
    if (_isRecording && _isPaused) {
      await _startChunkRecording();
      _isPaused = false;
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    if (_isRecording) {
      await _stopCurrentChunk();
      _chunkTimer?.cancel();
      
      final completedSessionId = _currentSessionId;
      
      if (_currentSessionId != null) {
        final session = RecordingSession(
          id: _currentSessionId!,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          status: 'completed',
        );
        await _db.updateSession(session);
      }

      _isRecording = false;
      _isPaused = false;
      _currentSessionId = null;
      notifyListeners();
      
      // Hide recording notification
      try {
        await NativeFeaturesService.hideRecordingNotification();
      } catch (e) {
        debugPrint('Failed to hide notification: $e');
      }
      
      // Store transcript from live transcription
      if (completedSessionId != null && _liveTranscription != null) {
        await _transcriptService.storeSessionTranscript(
          completedSessionId,
          _liveTranscription!.transcriptLines,
        );
      }
      
      // Notify that recording is complete with session ID
      if (completedSessionId != null) {
        onRecordingComplete?.call(completedSessionId);
      }
    }
  }

  Future<void> _startChunkRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _currentFilePath = '${directory.path}/chunk_${_currentSessionId}_${_sequenceNumber}.aac';
    
    await _recorder!.startRecorder(
      toFile: _currentFilePath!,
      codec: Codec.aacADTS,
    );

    _chunkTimer = Timer(const Duration(seconds: 10), _rotateChunk);
  }

  Future<void> _rotateChunk() async {
    if (_isRecording && !_isPaused) {
      await _stopCurrentChunk();
      await _startChunkRecording();
    }
  }

  Future<void> _stopCurrentChunk() async {
    _chunkTimer?.cancel();
    await _recorder!.stopRecorder();
    
    if (_currentFilePath != null && _currentSessionId != null) {
      final chunk = AudioChunk(
        id: '${_currentSessionId}_$_sequenceNumber',
        sessionId: _currentSessionId!,
        sequenceNumber: _sequenceNumber,
        filePath: _currentFilePath!,
        timestamp: DateTime.now(),
      );
      
      await _db.insertAudioChunk(chunk);
      _upload.uploadChunk(chunk);
      _sequenceNumber++;
    }
  }

  @override
  void dispose() {
    _chunkTimer?.cancel();
    _recorder?.closeRecorder();
    super.dispose();
  }
}