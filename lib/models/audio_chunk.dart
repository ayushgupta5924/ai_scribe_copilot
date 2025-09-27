class AudioChunk {
  final String id;
  final String sessionId;
  final int sequenceNumber;
  final String filePath;
  final DateTime timestamp;
  final bool uploaded;
  final int retryCount;

  AudioChunk({
    required this.id,
    required this.sessionId,
    required this.sequenceNumber,
    required this.filePath,
    required this.timestamp,
    this.uploaded = false,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'sequenceNumber': sequenceNumber,
      'filePath': filePath,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'uploaded': uploaded ? 1 : 0,
      'retryCount': retryCount,
    };
  }

  factory AudioChunk.fromMap(Map<String, dynamic> map) {
    return AudioChunk(
      id: map['id'],
      sessionId: map['sessionId'],
      sequenceNumber: map['sequenceNumber'],
      filePath: map['filePath'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      uploaded: map['uploaded'] == 1,
      retryCount: map['retryCount'] ?? 0,
    );
  }

  AudioChunk copyWith({
    bool? uploaded,
    int? retryCount,
  }) {
    return AudioChunk(
      id: id,
      sessionId: sessionId,
      sequenceNumber: sequenceNumber,
      filePath: filePath,
      timestamp: timestamp,
      uploaded: uploaded ?? this.uploaded,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class RecordingSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final String? patientId;

  RecordingSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.status,
    this.patientId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'status': status,
      'patientId': patientId,
    };
  }

  factory RecordingSession.fromMap(Map<String, dynamic> map) {
    return RecordingSession(
      id: map['id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      status: map['status'],
      patientId: map['patientId'],
    );
  }
}