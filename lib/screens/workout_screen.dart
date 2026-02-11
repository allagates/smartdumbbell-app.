import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/workout_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../models/exercise.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<WorkoutProvider, BluetoothProvider>(
      builder: (context, workout, bluetooth, child) {
        if (!bluetooth.isConnected) {
          return _buildNotConnectedView(context);
        }

        if (workout.isWorkoutActive) {
          return _buildActiveWorkoutView(context, workout, bluetooth);
        }

        return _buildExerciseSelection(context, workout, bluetooth);
      },
    );
  }

  // Vue quand pas connecté
  Widget _buildNotConnectedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun appareil connecté',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connecte ton SmartDumbbell pour commencer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/bluetooth');
              },
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Connecter un appareil'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sélection d'exercice
  Widget _buildExerciseSelection(
    BuildContext context,
    WorkoutProvider workout,
    BluetoothProvider bluetooth,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Choisis ton exercice',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionne un exercice pour commencer ton workout',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Grille d'exercices
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: workout.exercises.length,
            itemBuilder: (context, index) {
              final exercise = workout.exercises[index];
              final isSelected = workout.currentExercise?.id == exercise.id;

              return GestureDetector(
                onTap: () {
                  workout.selectExercise(exercise);
                  bluetooth.setExercise(exercise.id);
                  Vibration.vibrate(duration: 50);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF667eea).withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: isSelected ? 15 : 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          exercise.icon,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          exercise.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exercise.muscleGroup,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${exercise.targetReps} reps × ${exercise.targetSets}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white60 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Bouton démarrer
          if (workout.currentExercise != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  workout.startWorkout();
                  bluetooth.startWorkout(workout.currentExercise!.id);
                  Vibration.vibrate(duration: 100);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: const Color(0xFF11998e),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Démarrer le workout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Vue workout actif
  Widget _buildActiveWorkoutView(
    BuildContext context,
    WorkoutProvider workout,
    BluetoothProvider bluetooth,
  ) {
    final currentWorkout = workout.currentWorkout!;
    final exercise = workout.currentExercise!;

    return Column(
      children: [
        // En-tête avec exercice
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      exercise.icon,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            exercise.muscleGroup,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            currentWorkout.durationFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Statistiques en temps réel
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Compteur de reps principal
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF11998e).withOpacity(0.1),
                        const Color(0xFF38ef7d).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'RÉPÉTITIONS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF11998e),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${currentWorkout.totalReps}',
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF11998e),
                        ),
                      ),
                      Text(
                        'Série ${workout.currentSetNumber + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Grille de stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '✅',
                        'Bonne forme',
                        '${currentWorkout.goodFormReps}',
                        const Color(0xFF38ef7d),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '⚠️',
                        'À améliorer',
                        '${currentWorkout.badFormReps}',
                        const Color(0xFFFFA726),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '📊',
                        'Séries',
                        '${currentWorkout.sets.length}',
                        const Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '🎯',
                        'Qualité',
                        '${currentWorkout.qualityScore.toStringAsFixed(0)}%',
                        currentWorkout.qualityScore > 70
                            ? const Color(0xFF38ef7d)
                            : const Color(0xFFFFA726),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Angle en temps réel
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          '📐 Angle en temps réel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${bluetooth.currentAngle.toStringAsFixed(1)}°',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bluetooth.movementStatus,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Boutons de contrôle
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      workout.endSet();
                      bluetooth.endSet();
                      Vibration.vibrate(duration: 100);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Série terminée!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.pause),
                    label: const Text('Terminer la série'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: const Color(0xFFFFA726),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showEndWorkoutDialog(context, workout, bluetooth);
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Terminer le workout'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      foregroundColor: const Color(0xFFe53935),
                      side: const BorderSide(color: Color(0xFFe53935)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEndWorkoutDialog(
    BuildContext context,
    WorkoutProvider workout,
    BluetoothProvider bluetooth,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer le workout ?'),
        content: const Text(
          'Es-tu sûr de vouloir terminer ce workout ? Tes stats seront sauvegardées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              workout.endWorkout();
              bluetooth.endWorkout();
              Vibration.vibrate(duration: 200);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Workout terminé! Bien joué!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFe53935),
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }
}
