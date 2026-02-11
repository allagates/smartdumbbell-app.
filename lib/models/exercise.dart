class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String icon;
  final String description;
  final int targetReps;
  final int targetSets;
  final double minAngle;
  final double maxAngle;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.icon,
    required this.description,
    this.targetReps = 12,
    this.targetSets = 3,
    this.minAngle = 30,
    this.maxAngle = 150,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'icon': icon,
      'description': description,
      'targetReps': targetReps,
      'targetSets': targetSets,
      'minAngle': minAngle,
      'maxAngle': maxAngle,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      muscleGroup: json['muscleGroup'],
      icon: json['icon'],
      description: json['description'],
      targetReps: json['targetReps'] ?? 12,
      targetSets: json['targetSets'] ?? 3,
      minAngle: json['minAngle']?.toDouble() ?? 30.0,
      maxAngle: json['maxAngle']?.toDouble() ?? 150.0,
    );
  }

  static List<Exercise> getDefaultExercises() {
    return [
      Exercise(
        id: 'squats',
        name: 'Squats',
        muscleGroup: 'Jambes',
        icon: '🦵',
        description: 'Flexion complète des jambes avec le poids du corps',
        targetReps: 15,
        targetSets: 3,
        minAngle: 45,
        maxAngle: 170,
      ),
      Exercise(
        id: 'pushups',
        name: 'Pompes',
        muscleGroup: 'Pectoraux',
        icon: '💪',
        description: 'Pompes classiques au sol, amplitude complète',
        targetReps: 12,
        targetSets: 3,
        minAngle: 30,
        maxAngle: 170,
      ),
      Exercise(
        id: 'pullups',
        name: 'Tractions',
        muscleGroup: 'Dos',
        icon: '🏋️',
        description: 'Tractions à la barre, menton au-dessus de la barre',
        targetReps: 8,
        targetSets: 3,
        minAngle: 40,
        maxAngle: 160,
      ),
      Exercise(
        id: 'burpees',
        name: 'Burpees',
        muscleGroup: 'Full Body',
        icon: '🔥',
        description: 'Mouvement complet : squat, planche, pompe, saut',
        targetReps: 10,
        targetSets: 3,
        minAngle: 20,
        maxAngle: 170,
      ),
      Exercise(
        id: 'lunges',
        name: 'Fentes',
        muscleGroup: 'Jambes',
        icon: '🦿',
        description: 'Fentes alternées avant, genou à 90°',
        targetReps: 12,
        targetSets: 3,
        minAngle: 45,
        maxAngle: 170,
      ),
      Exercise(
        id: 'dips',
        name: 'Dips',
        muscleGroup: 'Triceps',
        icon: '💪',
        description: 'Dips aux barres parallèles ou chaise',
        targetReps: 10,
        targetSets: 3,
        minAngle: 35,
        maxAngle: 170,
      ),
      Exercise(
        id: 'crunches',
        name: 'Abdos',
        muscleGroup: 'Abdominaux',
        icon: '🔲',
        description: 'Crunchs classiques ou sit-ups',
        targetReps: 20,
        targetSets: 3,
        minAngle: 20,
        maxAngle: 90,
      ),
      Exercise(
        id: 'plank',
        name: 'Planche',
        muscleGroup: 'Core',
        icon: '⏱️',
        description: 'Maintien de la position planche (temps)',
        targetReps: 60, // secondes
        targetSets: 3,
        minAngle: 0,
        maxAngle: 10,
      ),
    ];
  }
}
