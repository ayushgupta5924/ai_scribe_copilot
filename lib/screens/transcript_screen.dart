import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'dart:io';
import '../models/audio_chunk.dart';

class TranscriptScreen extends StatefulWidget {
  final String sessionId;
  final String? patientId;
  final String? patientName;

  const TranscriptScreen({
    super.key,
    required this.sessionId,
    this.patientId,
    this.patientName,
  });

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  List<AudioChunk> _audioChunks = [];
  bool _isLoading = true;
  int _totalChunks = 0;
  int _uploadedChunks = 0;

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
  }

  Future<void> _loadAudioFiles() async {
    try {
      final db = DatabaseService();
      final allChunks = await db.getUnuploadedChunks();
      final sessionChunks = allChunks.where((chunk) => chunk.sessionId == widget.sessionId).toList();
      
      setState(() {
        _audioChunks = sessionChunks;
        _totalChunks = sessionChunks.length;
        _uploadedChunks = sessionChunks.where((chunk) => chunk.uploaded).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      }
    } catch (e) {
      // File might not exist
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Files'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading audio files...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recording Session',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('Patient: ${widget.patientName ?? 'Unknown'}'),
                          if (widget.patientId != null)
                            Text('Patient ID: ${widget.patientId}'),
                          Text('Session ID: ${widget.sessionId}'),
                          Text('Total Audio Chunks: $_totalChunks'),
                          Text('Uploaded: $_uploadedChunks'),
                          Text('Pending: ${_totalChunks - _uploadedChunks}'),
                          Text('Estimated Duration: ~${_totalChunks * 10} seconds'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Audio Files Being Transcribed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
                    child: _audioChunks.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  'No audio files found for this session.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _audioChunks.length,
                            itemBuilder: (context, index) {
                              final chunk = _audioChunks[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: chunk.uploaded ? Colors.green : Colors.orange,
                                    child: Text('${chunk.sequenceNumber}'),
                                  ),
                                  title: Text('Audio Chunk ${chunk.sequenceNumber}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Size: ${_getFileSize(chunk.filePath)}'),
                                      Text('Time: ${chunk.timestamp.toString().split(' ')[1].split('.')[0]}'),
                                    ],
                                  ),
                                  trailing: Icon(
                                    chunk.uploaded ? Icons.cloud_done : Icons.cloud_upload,
                                    color: chunk.uploaded ? Colors.green : Colors.orange,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Recording'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loadAudioFiles,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      ),
    );
  }
}