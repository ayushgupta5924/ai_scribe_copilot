import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class SessionSummaryScreen extends StatefulWidget {
  final String sessionId;
  final String? patientId;
  final String? patientName;

  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
    this.patientId,
    this.patientName,
  });

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  List<Map<String, dynamic>> _audioChunks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    final db = DatabaseService();
    final chunks = await db.getUnuploadedChunks();
    final sessionChunks = chunks.where((c) => c.sessionId == widget.sessionId).toList();
    
    setState(() {
      _audioChunks = sessionChunks.map((c) => {
        'sequence': c.sequenceNumber,
        'timestamp': c.timestamp,
        'uploaded': c.uploaded,
        'file_size': _getFileSize(c.filePath),
      }).toList();
      _isLoading = false;
    });
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
        title: const Text('Session Summary'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Patient: ${widget.patientName ?? 'Unknown'}'),
                          Text('Session ID: ${widget.sessionId}'),
                          Text('Audio Chunks: ${_audioChunks.length}'),
                          Text('Total Duration: ~${_audioChunks.length * 10} seconds'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Audio Chunks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _audioChunks.length,
                      itemBuilder: (context, index) {
                        final chunk = _audioChunks[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${chunk['sequence']}'),
                            ),
                            title: Text('Chunk ${chunk['sequence']}'),
                            subtitle: Text('Size: ${chunk['file_size']}'),
                            trailing: Icon(
                              chunk['uploaded'] == 1 
                                  ? Icons.cloud_done 
                                  : Icons.cloud_upload,
                              color: chunk['uploaded'] == 1 
                                  ? Colors.green 
                                  : Colors.orange,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Recording'),
                    ),
                  ),
                  const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }
}