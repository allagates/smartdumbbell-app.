import 'package:intl/intl.dart';

class Workout {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final DateTime startTime;
  DateTime? endTime;
  final List<WorkoutSet> sets;
  int totalReps;
  int goodFormReps;
  int badFormReps;
  double averageSpeed;
  double qualityScore;

  Workout({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.startTime,
    this.endTime,
    List<WorkoutSet>? sets,
    this.totalReps = 0,
    this.goodFormReps = 0,
    this.badFormReps = 0,
    this.averageSpeed = 0.0,
    this.qualityScore = 0.0,
  }) : sets = sets ?? [];

  Duration get duration {
    if (endTime == null) {
      return DateTime.now().difference(startTime);
    }
    return endTime!.difference(startTime);
  }

  String get durationFormatted {
    final d = duration;
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get dateFormatted {
    return DateFormat('dd MMM yyyy - HH:mm').format(startTime);
  }

  void addSet(WorkoutSet set) {
    sets.add(set);
    totalReps += set.reps;
    goodFormReps += set.goodFormReps;
    badFormReps += set.badFormReps;
    _updateQualityScore();
  }

  void _updateQualityScore() {
    if (totalReps == 0) {
      qualityScore = 0;
      return;
    }
    qualityScore = (goodFormReps / totalReps) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalReps': totalReps,
      'goodFormReps': goodFormReps,
      'badFormReps': badFormReps,
      'averageSpeed': averageSpeed,
      'qualityScore': qualityScore,
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      exerciseId: json['exerciseId'],
      exerciseName: json['exerciseName'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      totalReps: json['totalReps'],
      goodFormReps: json['goodFormReps'],
      badFormReps: json['badFormReps'],
      averageSpeed: json['averageSpeed']?.toDouble() ?? 0.0,
      qualityScore: json['qualityScore']?.toDouble() ?? 0.0,
      sets: (json['sets'] as List?)
          ?.map((s) => WorkoutSet.fromJson(s))
          .toList(),
    );
  }
}

class WorkoutSet {
  final int setNumber;
  final int reps;
  final int goodFormReps;
  final int badFormReps;
  final double averageSpeed;
  final DateTime timestamp;
  final List<RepData> repDetails;

  WorkoutSet({
    required this.setNumber,
    required this.reps,
    this.goodFormReps = 0,
    this.badFormReps = 0,
    this.averageSpeed = 0.0,
    DateTime? timestamp,
    List<RepData>? repDetails,
  })  : timestamp = timestamp ?? DateTime.now(),
        repDetails = repDetails ?? [];

  double get qualityPercentage {
    if (reps == 0) return 0;
    return (goodFormReps / reps) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'goodFormReps': goodFormReps,
      'badFormReps': badFormReps,
      'averageSpeed': averageSpeed,
      'timestamp': timestamp.toIso8601String(),
      'repDetails': repDetails.map((r) => r.toJson()).toList(),
    };
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      setNumber: json['setNumber'],
      reps: json['reps'],
      goodFormReps: json['goodFormReps'] ?? 0,
      badFormReps: json['badFormReps'] ?? 0,
      averageSpeed: json['averageSpeed']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp']),
      repDetails: (json['repDetails'] as List?)
          ?.map((r) => RepData.fromJson(r))
          .toList(),
    );
  }
}

class RepData {
  final int repNumber;
  final double maxAngle;
  final double minAngle;
  final double speed;
  final bool goodForm;
  final DateTime timestamp;

  RepData({
    required this.repNumber,
    required this.maxAngle,
    required this.minAngle,
    required this.speed,
    required this.goodForm,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'repNumber': repNumber,
      'maxAngle': maxAngle,
      'minAngle': minAngle,
      'speed': speed,
      'goodForm': goodForm,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RepData.fromJson(Map<String, dynamic> json) {
    return RepData(
      repNumber: json['repNumber'],
      maxAngle: json['maxAngle']?.toDouble() ?? 0.0,
      minAngle: json['minAngle']?.toDouble() ?? 0.0,
      speed: json['speed']?.toDouble() ?? 0.0,
      goodForm: json['goodForm'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
