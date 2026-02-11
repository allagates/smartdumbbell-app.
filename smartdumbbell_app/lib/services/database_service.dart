import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/workout.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartdumbbell.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE workouts (
        id $idType,
        exerciseId $textType,
        exerciseName $textType,
        startTime $textType,
        endTime TEXT,
        totalReps $intType,
        goodFormReps $intType,
        badFormReps $intType,
        averageSpeed $realType,
        qualityScore $realType,
        setsData $textType
      )
    ''');

    // Index pour recherches rapides
    await db.execute('''
      CREATE INDEX idx_workout_exercise ON workouts(exerciseId)
    ''');

    await db.execute('''
      CREATE INDEX idx_workout_date ON workouts(startTime)
    ''');
  }

  // Insérer un workout
  Future<void> insertWorkout(Workout workout) async {
    final db = await database;

    await db.insert(
      'workouts',
      {
        'id': workout.id,
        'exerciseId': workout.exerciseId,
        'exerciseName': workout.exerciseName,
        'startTime': workout.startTime.toIso8601String(),
        'endTime': workout.endTime?.toIso8601String(),
        'totalReps': workout.totalReps,
        'goodFormReps': workout.goodFormReps,
        'badFormReps': workout.badFormReps,
        'averageSpeed': workout.averageSpeed,
        'qualityScore': workout.qualityScore,
        'setsData': jsonEncode(workout.sets.map((s) => s.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Récupérer tous les workouts
  Future<List<Workout>> getAllWorkouts() async {
    final db = await database;
    final result = await db.query(
      'workouts',
      orderBy: 'startTime DESC',
    );

    return result.map((json) => _workoutFromMap(json)).toList();
  }

  // Récupérer les workouts par exercice
  Future<List<Workout>> getWorkoutsByExercise(String exerciseId) async {
    final db = await database;
    final result = await db.query(
      'workouts',
      where: 'exerciseId = ?',
      whereArgs: [exerciseId],
      orderBy: 'startTime DESC',
    );

    return result.map((json) => _workoutFromMap(json)).toList();
  }

  // Récupérer les workouts dans une plage de dates
  Future<List<Workout>> getWorkoutsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final result = await db.query(
      'workouts',
      where: 'startTime >= ? AND startTime <= ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'startTime DESC',
    );

    return result.map((json) => _workoutFromMap(json)).toList();
  }

  // Supprimer un workout
  Future<void> deleteWorkout(String id) async {
    final db = await database;
    await db.delete(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprimer tous les workouts d'un exercice
  Future<void> deleteWorkoutsByExercise(String exerciseId) async {
    final db = await database;
    await db.delete(
      'workouts',
      where: 'exerciseId = ?',
      whereArgs: [exerciseId],
    );
  }

  // Obtenir les statistiques globales
  Future<Map<String, dynamic>> getGlobalStats() async {
    final db = await database;

    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM workouts');
    final totalWorkouts = Sqflite.firstIntValue(countResult) ?? 0;

    final repsResult = await db.rawQuery('SELECT SUM(totalReps) as total FROM workouts');
    final totalReps = Sqflite.firstIntValue(repsResult) ?? 0;

    final qualityResult = await db.rawQuery('SELECT AVG(qualityScore) as avg FROM workouts');
    final avgQuality = (qualityResult.first['avg'] as num?)?.toDouble() ?? 0.0;

    return {
      'totalWorkouts': totalWorkouts,
      'totalReps': totalReps,
      'averageQuality': avgQuality,
    };
  }

  // Convertir une map en Workout
  Workout _workoutFromMap(Map<String, dynamic> map) {
    List<WorkoutSet> sets = [];
    if (map['setsData'] != null) {
      final setsJson = jsonDecode(map['setsData']) as List;
      sets = setsJson.map((s) => WorkoutSet.fromJson(s)).toList();
    }

    return Workout(
      id: map['id'],
      exerciseId: map['exerciseId'],
      exerciseName: map['exerciseName'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      totalReps: map['totalReps'],
      goodFormReps: map['goodFormReps'],
      badFormReps: map['badFormReps'],
      averageSpeed: map['averageSpeed'],
      qualityScore: map['qualityScore'],
      sets: sets,
    );
  }

  // Fermer la base de données
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
