import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/speech_recognition_service.dart';

class LiveTranscriptScreen extends StatefulWidget {
  final String sessionId;
  final String? patientName;

  const LiveTranscriptScreen({
    super.key,
    required this.sessionId,
    this.patientName,
  });

  @override
  State<LiveTranscriptScreen> createState() => _LiveTranscriptScreenState();
}

class _LiveTranscriptScreenState extends State<LiveTranscriptScreen> {
  late SpeechRecognitionService _speechService;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _speechService = SpeechRecognitionService();
    _speechService.initialize();
    _speechService.addListener(_scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Transcript'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _speechService.clearTranscript(),
          ),
        ],
      ),
      body: SafeArea(
        child: ChangeNotifierProvider.value(
          value: _speechService,
          child: Consumer<SpeechRecognitionService>(
            builder: (context, service, child) {
              return SingleChildScrollView(
                child: Column(
                children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Transcription',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Patient: ${widget.patientName ?? 'Unknown'}'),
                        Text('Session: ${widget.sessionId}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              service.isListening ? Icons.mic : Icons.mic_off,
                              color: service.isListening ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              service.isListening ? 'Listening...' : 'Not listening',
                              style: TextStyle(
                                color: service.isListening ? Colors.red : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (service.recognizedText.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      'Current: ${service.recognizedText}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: service.conversationLog.isEmpty
                      ? const Center(
                          child: Text(
                            'Start speaking to see live transcription...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: service.conversationLog.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                service.conversationLog[index],
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: service.isListening
                              ? () => service.stopListening()
                              : () => service.startListening(),
                          icon: Icon(
                            service.isListening ? Icons.stop : Icons.play_arrow,
                          ),
                          label: Text(
                            service.isListening ? 'Stop Listening' : 'Start Listening',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: service.isListening ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final transcript = service.getFullTranscript();
                          if (transcript.isNotEmpty) {
                            _showTranscriptDialog(transcript);
                          }
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Full'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
                ],
              ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTranscriptDialog(String transcript) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full Transcript'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(transcript),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speechService.removeListener(_scrollToBottom);
    _speechService.stopListening();
    _scrollController.dispose();
    super.dispose();
  }
}