import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/database_service.dart';

class WorkoutProvider with ChangeNotifier {
  final List<Exercise> _exercises = Exercise.getDefaultExercises();
  Exercise? _currentExercise;
  Workout? _currentWorkout;
  List<Workout> _workoutHistory = [];
  
  bool _isWorkoutActive = false;
  int _currentSetNumber = 0;
  List<RepData> _currentSetReps = [];
  
  // Getters
  List<Exercise> get exercises => _exercises;
  Exercise? get currentExercise => _currentExercise;
  Workout? get currentWorkout => _currentWorkout;
  List<Workout> get workoutHistory => _workoutHistory;
  bool get isWorkoutActive => _isWorkoutActive;
  int get currentSetNumber => _currentSetNumber;
  
  // Statistiques globales
  int get totalWorkouts => _workoutHistory.length;
  int get totalReps => _workoutHistory.fold(0, (sum, w) => sum + w.totalReps);
  double get averageQuality {
    if (_workoutHistory.isEmpty) return 0;
    return _workoutHistory.fold(0.0, (sum, w) => sum + w.qualityScore) / _workoutHistory.length;
  }
  
  WorkoutProvider() {
    _loadWorkoutHistory();
  }
  
  // Charger l'historique depuis la base de données
  Future<void> _loadWorkoutHistory() async {
    try {
      _workoutHistory = await DatabaseService.instance.getAllWorkouts();
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur chargement historique: $e");
    }
  }
  
  // Sélectionner un exercice
  void selectExercise(Exercise exercise) {
    if (_isWorkoutActive) {
      debugPrint("Impossible de changer d'exercice pendant un workout");
      return;
    }
    _currentExercise = exercise;
    notifyListeners();
  }
  
  // Démarrer un workout
  void startWorkout() {
    if (_currentExercise == null) {
      debugPrint("Aucun exercice sélectionné");
      return;
    }
    
    _currentWorkout = Workout(
      id: const Uuid().v4(),
      exerciseId: _currentExercise!.id,
      exerciseName: _currentExercise!.name,
      startTime: DateTime.now(),
    );
    
    _isWorkoutActive = true;
    _currentSetNumber = 0;
    _currentSetReps = [];
    
    notifyListeners();
    debugPrint("Workout démarré: ${_currentExercise!.name}");
  }
  
  // Ajouter une répétition
  void addRep(RepData repData) {
    if (!_isWorkoutActive || _currentWorkout == null) return;
    
    _currentSetReps.add(repData);
    _currentWorkout!.totalReps++;
    
    if (repData.goodForm) {
      _currentWorkout!.goodFormReps++;
    } else {
      _currentWorkout!.badFormReps++;
    }
    
    notifyListeners();
  }
  
  // Terminer une série
  void endSet() {
    if (!_isWorkoutActive || _currentWorkout == null || _currentSetReps.isEmpty) {
      return;
    }
    
    _currentSetNumber++;
    
    int goodReps = _currentSetReps.where((r) => r.goodForm).length;
    int badReps = _currentSetReps.where((r) => !r.goodForm).length;
    double avgSpeed = _currentSetReps.fold(0.0, (sum, r) => sum + r.speed) / _currentSetReps.length;
    
    WorkoutSet newSet = WorkoutSet(
      setNumber: _currentSetNumber,
      reps: _currentSetReps.length,
      goodFormReps: goodReps,
      badFormReps: badReps,
      averageSpeed: avgSpeed,
      repDetails: List.from(_currentSetReps),
    );
    
    _currentWorkout!.addSet(newSet);
    _currentSetReps.clear();
    
    notifyListeners();
    debugPrint("Série $_currentSetNumber terminée: ${newSet.reps} reps");
  }
  
  // Terminer le workout
  Future<void> endWorkout() async {
    if (!_isWorkoutActive || _currentWorkout == null) return;
    
    // Terminer la série en cours s'il y a des reps
    if (_currentSetReps.isNotEmpty) {
      endSet();
    }
    
    _currentWorkout!.endTime = DateTime.now();
    _isWorkoutActive = false;
    
    // Sauvegarder dans la base de données
    try {
      await DatabaseService.instance.insertWorkout(_currentWorkout!);
      _workoutHistory.insert(0, _currentWorkout!);
      notifyListeners();
      
      debugPrint("Workout terminé et sauvegardé!");
      debugPrint("Total reps: ${_currentWorkout!.totalReps}");
      debugPrint("Qualité: ${_currentWorkout!.qualityScore.toStringAsFixed(1)}%");
    } catch (e) {
      debugPrint("Erreur sauvegarde workout: $e");
    }
    
    _currentWorkout = null;
    _currentSetNumber = 0;
    notifyListeners();
  }
  
  // Annuler le workout en cours
  void cancelWorkout() {
    _currentWorkout = null;
    _isWorkoutActive = false;
    _currentSetNumber = 0;
    _currentSetReps.clear();
    notifyListeners();
  }
  
  // Obtenir les workouts par exercice
  List<Workout> getWorkoutsByExercise(String exerciseId) {
    return _workoutHistory.where((w) => w.exerciseId == exerciseId).toList();
  }
  
  // Obtenir les statistiques d'un exercice
  Map<String, dynamic> getExerciseStats(String exerciseId) {
    List<Workout> exerciseWorkouts = getWorkoutsByExercise(exerciseId);
    
    if (exerciseWorkouts.isEmpty) {
      return {
        'totalWorkouts': 0,
        'totalReps': 0,
        'totalSets': 0,
        'averageQuality': 0.0,
        'bestQuality': 0.0,
        'progressionData': [],
      };
    }
    
    int totalReps = exerciseWorkouts.fold(0, (sum, w) => sum + w.totalReps);
    int totalSets = exerciseWorkouts.fold(0, (sum, w) => sum + w.sets.length);
    double avgQuality = exerciseWorkouts.fold(0.0, (sum, w) => sum + w.qualityScore) / exerciseWorkouts.length;
    double bestQuality = exerciseWorkouts.fold(0.0, (max, w) => w.qualityScore > max ? w.qualityScore : max);
    
    // Données de progression (derniers 10 workouts)
    List<Map<String, dynamic>> progressionData = exerciseWorkouts
        .take(10)
        .reversed
        .map((w) => {
              'date': w.startTime,
              'reps': w.totalReps,
              'quality': w.qualityScore,
            })
        .toList();
    
    return {
      'totalWorkouts': exerciseWorkouts.length,
      'totalReps': totalReps,
      'totalSets': totalSets,
      'averageQuality': avgQuality,
      'bestQuality': bestQuality,
      'progressionData': progressionData,
    };
  }
  
  // Supprimer un workout
  Future<void> deleteWorkout(String workoutId) async {
    try {
      await DatabaseService.instance.deleteWorkout(workoutId);
      _workoutHistory.removeWhere((w) => w.id == workoutId);
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur suppression workout: $e");
    }
  }
  
  // Obtenir les workouts de la semaine
  List<Workout> getThisWeekWorkouts() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    return _workoutHistory.where((w) => w.startTime.isAfter(startOfWeek)).toList();
  }
  
  // Obtenir le workout le plus récent
  Workout? get lastWorkout {
    if (_workoutHistory.isEmpty) return null;
    return _workoutHistory.first;
  }
}
