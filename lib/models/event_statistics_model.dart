// lib/models/event_statistics_model.dart

class EventStatistics {
  final String eventId;
  final String eventName;
  final int totalStudents;
  final int presentStudents;
  final int absentStudents;
  final int lateStudents;
  final double attendanceRate;
  final double averageArrivalTime;
  final List<StudentAttendanceStat> studentStats;
  final Map<String, dynamic> timelineData;
  final DateTime lastUpdate;

  const EventStatistics({
    required this.eventId,
    required this.eventName,
    required this.totalStudents,
    required this.presentStudents,
    required this.absentStudents,
    required this.lateStudents,
    required this.attendanceRate,
    required this.averageArrivalTime,
    required this.studentStats,
    required this.timelineData,
    required this.lastUpdate,
  });

  factory EventStatistics.fromJson(Map<String, dynamic> json) {
    return EventStatistics(
      eventId: json['eventId'] ?? '',
      eventName: json['eventName'] ?? '',
      totalStudents: json['totalStudents'] ?? 0,
      presentStudents: json['presentStudents'] ?? 0,
      absentStudents: json['absentStudents'] ?? 0,
      lateStudents: json['lateStudents'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0.0).toDouble(),
      averageArrivalTime: (json['averageArrivalTime'] ?? 0.0).toDouble(),
      studentStats: json['studentStats'] != null
          ? (json['studentStats'] as List)
              .map((item) => StudentAttendanceStat.fromJson(item))
              .toList()
          : [],
      timelineData: json['timelineData'] ?? {},
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'totalStudents': totalStudents,
      'presentStudents': presentStudents,
      'absentStudents': absentStudents,
      'lateStudents': lateStudents,
      'attendanceRate': attendanceRate,
      'averageArrivalTime': averageArrivalTime,
      'studentStats': studentStats.map((stat) => stat.toJson()).toList(),
      'timelineData': timelineData,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  EventStatistics copyWith({
    String? eventId,
    String? eventName,
    int? totalStudents,
    int? presentStudents,
    int? absentStudents,
    int? lateStudents,
    double? attendanceRate,
    double? averageArrivalTime,
    List<StudentAttendanceStat>? studentStats,
    Map<String, dynamic>? timelineData,
    DateTime? lastUpdate,
  }) {
    return EventStatistics(
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      totalStudents: totalStudents ?? this.totalStudents,
      presentStudents: presentStudents ?? this.presentStudents,
      absentStudents: absentStudents ?? this.absentStudents,
      lateStudents: lateStudents ?? this.lateStudents,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      averageArrivalTime: averageArrivalTime ?? this.averageArrivalTime,
      studentStats: studentStats ?? this.studentStats,
      timelineData: timelineData ?? this.timelineData,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  String toString() {
    return 'EventStatistics(eventId: $eventId, eventName: $eventName, '
        'attendance: $presentStudents/$totalStudents ($attendanceRate%))';
  }
}

class StudentAttendanceStat {
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String status; // 'present', 'absent', 'late'
  final DateTime? arrivalTime;
  final DateTime? departureTime;
  final int minutesLate;
  final List<LocationPoint> locationHistory;

  const StudentAttendanceStat({
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.status,
    this.arrivalTime,
    this.departureTime,
    required this.minutesLate,
    required this.locationHistory,
  });

  factory StudentAttendanceStat.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceStat(
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      studentEmail: json['studentEmail'] ?? '',
      status: json['status'] ?? 'absent',
      arrivalTime: json['arrivalTime'] != null
          ? DateTime.parse(json['arrivalTime'])
          : null,
      departureTime: json['departureTime'] != null
          ? DateTime.parse(json['departureTime'])
          : null,
      minutesLate: json['minutesLate'] ?? 0,
      locationHistory: json['locationHistory'] != null
          ? (json['locationHistory'] as List)
              .map((item) => LocationPoint.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'status': status,
      'arrivalTime': arrivalTime?.toIso8601String(),
      'departureTime': departureTime?.toIso8601String(),
      'minutesLate': minutesLate,
      'locationHistory': locationHistory.map((point) => point.toJson()).toList(),
    };
  }

  bool get isPresent => status == 'present';
  bool get isLate => status == 'late' || minutesLate > 0;
  bool get isAbsent => status == 'absent';

  Duration? get attendanceDuration {
    if (arrivalTime != null && departureTime != null) {
      return departureTime!.difference(arrivalTime!);
    }
    return null;
  }
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
    };
  }
}