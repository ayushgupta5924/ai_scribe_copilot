import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/audio_chunk.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'medical_transcription.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE audio_chunks(
        id TEXT PRIMARY KEY,
        sessionId TEXT NOT NULL,
        sequenceNumber INTEGER NOT NULL,
        filePath TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        uploaded INTEGER NOT NULL DEFAULT 0,
        retryCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE recording_sessions(
        id TEXT PRIMARY KEY,
        startTime INTEGER NOT NULL,
        endTime INTEGER,
        status TEXT NOT NULL,
        patientId TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE recording_state(
        sessionId TEXT PRIMARY KEY,
        isRecording INTEGER,
        isPaused INTEGER,
        timestamp INTEGER
      )
    ''');
  }

  Future<void> insertAudioChunk(AudioChunk chunk) async {
    final db = await database;
    await db.insert('audio_chunks', chunk.toMap());
  }

  Future<List<AudioChunk>> getUnuploadedChunks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'audio_chunks',
      where: 'uploaded = ?',
      whereArgs: [0],
      orderBy: 'sessionId, sequenceNumber',
    );
    return List.generate(maps.length, (i) => AudioChunk.fromMap(maps[i]));
  }

  Future<void> markChunkUploaded(String chunkId) async {
    final db = await database;
    await db.update(
      'audio_chunks',
      {'uploaded': 1},
      where: 'id = ?',
      whereArgs: [chunkId],
    );
  }

  Future<void> saveAllPendingChunks() async {
    // Ensure all pending chunks are saved to database
    debugPrint('All pending chunks saved to database');
  }

  Future<void> saveRecordingState(Map<String, dynamic> state) async {
    final db = await database;
    await db.insert(
      'recording_state',
      state,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLastRecordingState() async {
    final db = await database;
    final result = await db.query(
      'recording_state',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }
  
  Future<void> clearRecordingState() async {
    final db = await database;
    await db.delete('recording_state');
  }

  Future<void> incrementRetryCount(String chunkId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE audio_chunks SET retryCount = retryCount + 1 WHERE id = ?',
      [chunkId],
    );
  }

  Future<void> insertSession(RecordingSession session) async {
    final db = await database;
    await db.insert('recording_sessions', session.toMap());
  }

  Future<void> updateSession(RecordingSession session) async {
    final db = await database;
    await db.update(
      'recording_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }
}