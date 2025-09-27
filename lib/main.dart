import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/audio_service.dart';
import 'services/interruption_service.dart';
import 'services/background_service.dart';
import 'screens/recording_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await BackgroundService.initializeService();
  await BackgroundService.requestPermissions();
  
  runApp(const MedicalTranscriptionApp());
}

class MedicalTranscriptionApp extends StatelessWidget {
  const MedicalTranscriptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProxyProvider<AudioService, InterruptionService>(
          create: (context) => InterruptionService(
            Provider.of<AudioService>(context, listen: false),
          ),
          update: (context, audioService, previous) => 
              previous ?? InterruptionService(audioService),
        ),
      ],
      child: MaterialApp(
        title: 'Medical Transcription',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const RecordingScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
