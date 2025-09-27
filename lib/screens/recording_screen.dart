import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/native_features_service.dart';
import '../widgets/audio_visualizer.dart';
import '../services/live_transcription_service.dart';
import 'transcript_screen.dart';


class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController();
  final LiveTranscriptionService _transcriptionService = LiveTranscriptionService();
  
  @override
  void initState() {
    super.initState();
    final audioService = Provider.of<AudioService>(context, listen: false);
    audioService.onRecordingComplete = _navigateToTranscript;
    audioService.setLiveTranscriptionService(_transcriptionService);
    _initializeTranscription();
  }
  
  Future<void> _initializeTranscription() async {
    bool available = await _transcriptionService.initialize();
    debugPrint('Transcription service initialized: $available');
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _navigateToTranscript(String sessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TranscriptScreen(
          sessionId: sessionId,
          patientId: _patientIdController.text.isEmpty ? null : _patientIdController.text,
          patientName: _patientNameController.text.isEmpty ? null : _patientNameController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Transcription'),
        backgroundColor: Colors.redAccent[800],
        foregroundColor: Colors.blueGrey,
      ),
      body: Consumer<AudioService>(
        builder: (context, audioService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                if (!audioService.isRecording) ...[
                  TextField(
                    controller: _patientIdController,
                    decoration: const InputDecoration(
                      labelText: 'Patient ID (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _patientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Name (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                AudioVisualizer(isRecording: audioService.isRecording),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: audioService.isRecording
                        ? (audioService.isPaused ? Colors.orange : Colors.red)
                        : Colors.pinkAccent,
                  ),
                  child: IconButton(
                    onPressed: _handleRecordingAction,
                    icon: Icon(
                      audioService.isRecording
                          ? (audioService.isPaused
                              ? Icons.play_arrow
                              : Icons.pause)
                          : Icons.mic,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  audioService.isRecording
                      ? (audioService.isPaused
                          ? 'Recording Paused'
                          : 'Recording...')
                      : 'Tap to Start Recording',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (audioService.isRecording) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => audioService.stopRecording(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Stop Recording'),
                  ),
                  const SizedBox(height: 20),
                  ChangeNotifierProvider.value(
                    value: _transcriptionService,
                    child: Consumer<LiveTranscriptionService>(
                      builder: (context, service, child) {
                        return Container(
                          height: 120,
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    service.isListening ? Icons.mic : Icons.mic_off,
                                    size: 16,
                                    color: service.isListening ? Colors.red : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Live Transcript ${service.isListening ? '(${(service.confidence * 100).toInt()}%)' : ''}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: service.isListening ? Colors.red : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      if (service.isListening) {
                                        service.stopListening();
                                      } else {
                                        service.startListening();
                                      }
                                    },
                                    child: Text(
                                      service.isListening ? 'Stop' : 'Start',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ...service.transcriptLines.map((line) => 
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text(line, style: const TextStyle(fontSize: 12)),
                                        )
                                      ),
                                      if (service.currentText.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Current: ${service.currentText}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.info, color: Colors.tealAccent),
                        SizedBox(height: 10),
                        Text(
                          'Smart recording features:\n'
                          '• Auto-pauses during phone calls\n'
                          '• Auto-resumes when call ends\n'
                          '• Continues when screen is locked\n'
                          '• Survives network outages',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleRecordingAction() async {
    final audioService = Provider.of<AudioService>(context, listen: false);

    if (!audioService.isRecording) {
      await NativeFeaturesService.mediumHaptic();
      final success = await audioService.startRecording(
        patientId: _patientIdController.text.isEmpty
            ? null
            : _patientIdController.text,
        patientName: _patientNameController.text.isEmpty
            ? null
            : _patientNameController.text,
      );
      if (success) {
        await NativeFeaturesService.showRecordingNotification('Recording consultation...');
        _transcriptionService.startListening();
        // Add test transcript for debugging
        _transcriptionService.addTestTranscript();
      }
    } else if (audioService.isPaused) {
      await NativeFeaturesService.lightHaptic();
      await audioService.resumeRecording();
      await NativeFeaturesService.showRecordingNotification('Recording resumed');
      _transcriptionService.startListening();
    } else {
      await NativeFeaturesService.lightHaptic();
      await audioService.pauseRecording();
      await NativeFeaturesService.showRecordingNotification('Recording paused');
      _transcriptionService.stopListening();
    }
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _patientNameController.dispose();
    _transcriptionService.stopListening();
    super.dispose();
  }
}
