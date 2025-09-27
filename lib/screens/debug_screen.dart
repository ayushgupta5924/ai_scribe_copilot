import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/database_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  List<FileSystemEntity> _audioFiles = [];
  List<Map<String, dynamic>> _chunks = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync().where((f) => f.path.endsWith('.aac')).toList();
    
    final db = DatabaseService();
    final chunks = await db.getUnuploadedChunks();
    
    setState(() {
      _audioFiles = files;
      _chunks = chunks.map((c) => c.toMap()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Files Debug')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Local Audio Files: ${_audioFiles.length}'),
              Text('Pending Uploads: ${_chunks.length}'),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _audioFiles.length,
                itemBuilder: (context, index) {
                  final file = _audioFiles[index];
                  final stat = file.statSync();
                  return ListTile(
                    title: Text(file.path.split('/').last),
                    subtitle: Text('Size: ${stat.size} bytes'),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}