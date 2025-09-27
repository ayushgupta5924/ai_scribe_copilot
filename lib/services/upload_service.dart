import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/audio_chunk.dart';
import 'database_service.dart';

class UploadService {
  final DatabaseService _db = DatabaseService();
  final String _baseUrl = 'https://app.scribehealth.ai/api';
  final String _userId = 'user_123'; // TODO: Replace with actual user ID
  final String _authToken = 'your_auth_token_here'; // TODO: Replace with actual JWT token
  Timer? _retryTimer;
  bool _isUploading = false;
  String? _currentSessionId;

  UploadService() {
    _startRetryTimer();
    _listenToConnectivity();
  }

  void _startRetryTimer() {
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _processUploadQueue();
    });
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile)) {
        _processUploadQueue();
      }
    });
  }

  Future<String?> startSession(String? patientId, {String? patientName}) async {
    // Try to register with backend first
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/upload-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'patientId': patientId ?? 'unknown_patient',
          'userId': _userId,
          'patientName': patientName ?? 'Unknown Patient',
          'status': 'recording',
          'startTime': DateTime.now().toIso8601String(),
          'templateId': 'new_patient_visit',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentSessionId = data['id'];
        debugPrint('Backend session created: $_currentSessionId');
        return _currentSessionId;
      }
    } catch (e) {
      debugPrint('Backend unavailable, creating local session: $e');
    }
    
    // Fallback to local session ID
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    return _currentSessionId;
  }

  Future<void> uploadChunk(AudioChunk chunk) async {
    try {
      final file = File(chunk.filePath);
      if (!file.existsSync()) return;

      // Try backend upload, but store locally if unavailable
      try {
        // Get presigned URL
        final urlResponse = await http.post(
          Uri.parse('$_baseUrl/v1/get-presigned-url'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
          body: jsonEncode({
            'sessionId': chunk.sessionId,
            'chunkNumber': chunk.sequenceNumber,
            'mimeType': 'audio/aac',
          }),
        ).timeout(const Duration(seconds: 10));

        if (urlResponse.statusCode == 200) {
          final urlData = jsonDecode(urlResponse.body);
          final presignedUrl = urlData['presignedUrl'];

          // Upload to presigned URL
          final uploadResponse = await http.put(
            Uri.parse(presignedUrl),
            headers: {'Content-Type': 'audio/aac'},
            body: await file.readAsBytes(),
          ).timeout(const Duration(seconds: 30));

          if (uploadResponse.statusCode == 200) {
            // Notify backend of successful upload
            await http.post(
              Uri.parse('$_baseUrl/v1/notify-chunk-uploaded'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_authToken',
              },
              body: jsonEncode({
                'sessionId': chunk.sessionId,
                'gcsPath': 'sessions/${chunk.sessionId}/chunk_${chunk.sequenceNumber}.aac',
                'chunkNumber': chunk.sequenceNumber,
                'isLast': false,
                'totalChunksClient': 0,
                'publicUrl': urlData['publicUrl'] ?? '',
                'mimeType': 'audio/aac',
                'selectedTemplate': 'New Patient Visit',
                'selectedTemplateId': 'new_patient_visit',
                'model': 'fast',
              }),
            );

            await _db.markChunkUploaded(chunk.id);
            await file.delete();
            debugPrint('Chunk ${chunk.sequenceNumber} uploaded successfully');
            return;
          }
        }
      } catch (e) {
        debugPrint('Backend upload failed, storing locally: $e');
      }
      
      // Backend unavailable - keep chunk for later retry
      await _db.incrementRetryCount(chunk.id);
      debugPrint('Chunk ${chunk.sequenceNumber} queued for retry');
      
    } catch (e) {
      debugPrint('Upload failed: $e');
      await _db.incrementRetryCount(chunk.id);
    }
  }

  Future<void> _processUploadQueue() async {
    if (_isUploading) return;
    _isUploading = true;

    try {
      final chunks = await _db.getUnuploadedChunks();
      for (final chunk in chunks) {
        if (chunk.retryCount < 5) {
          await uploadChunk(chunk);
        }
      }
    } finally {
      _isUploading = false;
    }
  }

  void dispose() {
    _retryTimer?.cancel();
  }
}