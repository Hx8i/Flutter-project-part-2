import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class BodyVisualizerPage extends StatefulWidget {
  final int userId;

  const BodyVisualizerPage({Key? key, required this.userId}) : super(key: key);

  @override
  _BodyVisualizerPageState createState() => _BodyVisualizerPageState();
}

class _BodyVisualizerPageState extends State<BodyVisualizerPage>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  String selectedBodyPart = '';
  Map<String, int> muscleGroupProgress = {};
  Set<String> completedExercises = {}; // Track completed exercises

  // Enhanced exercise data with descriptions and durations
  Map<String, List<Map<String, dynamic>>> muscleGroupExercises = {
    'chest': [
      {
        'name': 'Push-ups',
        'description': 'Classic bodyweight exercise that targets chest, shoulders, and triceps. Start in plank position, lower body to ground, then push back up.',
        'duration': 30,
        'reps': '10-15 reps',
        'calories': 50,
        'difficulty': 'Beginner'
      },
      {
        'name': 'Chest Press',
        'description': 'Lie on bench, hold weights above chest, lower slowly to chest level, then press back up. Great for building chest strength.',
        'duration': 45,
        'reps': '8-12 reps',
        'calories': 80,
        'difficulty': 'Intermediate'
      },
      {
        'name': 'Chest Fly',
        'description': 'Lie on bench with arms extended, lower weights in wide arc, then bring back together above chest. Targets inner chest.',
        'duration': 40,
        'reps': '10-15 reps',
        'calories': 70,
        'difficulty': 'Intermediate'
      }
    ],
    'arms': [
      {
        'name': 'Bicep Curls',
        'description': 'Stand with weights, arms at sides. Curl weights to shoulders by bending elbows, then lower slowly. Targets biceps.',
        'duration': 35,
        'reps': '12-15 reps',
        'calories': 40,
        'difficulty': 'Beginner'
      },
      {
        'name': 'Tricep Dips',
        'description': 'Sit on chair edge, hands gripping edge. Lower body by bending elbows, then push back up. Great for tricep strength.',
        'duration': 30,
        'reps': '8-12 reps',
        'calories': 60,
        'difficulty': 'Intermediate'
      },
      {
        'name': 'Pull-ups',
        'description': 'Hang from bar with overhand grip, pull body up until chin over bar, lower slowly. Full upper body workout.',
        'duration': 60,
        'reps': '5-10 reps',
        'calories': 100,
        'difficulty': 'Advanced'
      }
    ],
    'shoulders': [
      {
        'name': 'Shoulder Press',
        'description': 'Stand or sit, press weights from shoulder level straight up overhead, then lower slowly. Builds shoulder strength.',
        'duration': 40,
        'reps': '10-12 reps',
        'calories': 70,
        'difficulty': 'Intermediate'
      },
      {
        'name': 'Lateral Raises',
        'description': 'Stand with weights at sides, raise arms out to shoulder height, lower slowly. Targets side deltoids.',
        'duration': 30,
        'reps': '12-15 reps',
        'calories': 50,
        'difficulty': 'Beginner'
      },
      {
        'name': 'Shoulder Shrugs',
        'description': 'Hold weights, lift shoulders toward ears, hold briefly, then lower. Great for upper traps and neck.',
        'duration': 25,
        'reps': '15-20 reps',
        'calories': 35,
        'difficulty': 'Beginner'
      }
    ],
    'abs': [
      {
        'name': 'Crunches',
        'description': 'Lie on back, knees bent, hands behind head. Lift shoulders off ground, squeeze abs, then lower slowly.',
        'duration': 30,
        'reps': '15-25 reps',
        'calories': 45,
        'difficulty': 'Beginner'
      },
      {
        'name': 'Planks',
        'description': 'Hold push-up position with forearms on ground. Keep body straight, engage core. Hold for time.',
        'duration': 60,
        'reps': '30-60 seconds',
        'calories': 80,
        'difficulty': 'Intermediate'
      },
      {
        'name': 'Russian Twists',
        'description': 'Sit with knees bent, lean back slightly, rotate torso side to side. Add weight for extra challenge.',
        'duration': 45,
        'reps': '20-30 reps',
        'calories': 65,
        'difficulty': 'Intermediate'
      }
    ],
    'legs': [
      {
        'name': 'Squats',
        'description': 'Stand with feet shoulder-width apart, lower body as if sitting in chair, then stand back up. Great for thighs and glutes.',
        'duration': 40,
        'reps': '15-20 reps',
        'calories': 90,
        'difficulty': 'Beginner'
      },
      {
        'name': 'Lunges',
        'description': 'Step forward into lunge position, lower back knee toward ground, then push back to starting position.',
        'duration': 45,
        'reps': '10-15 each leg',
        'calories': 85,
        'difficulty': 'Intermediate'
      },
      {
        'name': 'Leg Press',
        'description': 'Using machine, place feet on platform, lower weight by bending knees, then press back up. Targets all leg muscles.',
        'duration': 50,
        'reps': '12-15 reps',
        'calories': 100,
        'difficulty': 'Intermediate'
      }
    ],
    'back': [
      {
        'name': 'Bent-over Rows',
        'description': 'Bend forward at waist, pull weights to chest by squeezing shoulder blades, then lower slowly. Great for upper back.',
        'duration': 45,
        'reps': '10-12 reps',
        'calories': 75,
        'difficulty': 'Intermediate'
      },
      {
        'name': 'Lat Pulldowns',
        'description': 'Using machine, pull bar down to chest while squeezing lats, then slowly return to start position.',
        'duration': 40,
        'reps': '10-15 reps',
        'calories': 80,
        'difficulty': 'Intermediate'
      },
      {
        'name': 'Deadlifts',
        'description': 'Stand with feet hip-width apart, bend at hips to lower weight, then return to standing. Full posterior chain exercise.',
        'duration': 60,
        'reps': '8-10 reps',
        'calories': 120,
        'difficulty': 'Advanced'
      }
    ],
  };

  bool isLoading = true;
  int totalWorkouts = 0;

  @override
  void initState() {
    super.initState();

    // Initialize with safe defaults first
    muscleGroupProgress = {
      'chest': 0,
      'arms': 0,
      'shoulders': 0,
      'abs': 0,
      'legs': 0,
      'back': 0,
    };

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Delay data fetching slightly to ensure everything is initialized
    Future.delayed(Duration(milliseconds: 100), () {
      fetchWorkoutData();
      fetchCompletedExercises();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // Helper methods for safe type conversion
  int _safeParseInt(dynamic value) {
    try {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) {
        if (value.isEmpty) return 0;
        return int.tryParse(value) ?? 0;
      }
      // Try to convert any other type to string first, then to int
      return int.tryParse(value.toString()) ?? 0;
    } catch (e) {
      print('Error parsing int from $value: $e');
      return 0;
    }
  }

  String _safeParseString(dynamic value) {
    try {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    } catch (e) {
      print('Error parsing string from $value: $e');
      return '';
    }
  }

  double _safeParseDouble(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        if (value.isEmpty) return 0.0;
        return double.tryParse(value) ?? 0.0;
      }
      return double.tryParse(value.toString()) ?? 0.0;
    } catch (e) {
      print('Error parsing double from $value: $e');
      return 0.0;
    }
  }

  // Safe method to ensure userId is always an integer
  int get safeUserId {
    try {
      return _safeParseInt(widget.userId);
    } catch (e) {
      print('Error with userId: $e');
      return 1; // Default fallback
    }
  }

  Future<void> fetchWorkoutData() async {
    try {
      print('Fetching workout data for user ID: ${safeUserId}');

      final response = await http.get(
        Uri.parse('$baseUrl/activity_api.php?user_id=$safeUserId'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded data: $data');

        if (data is Map && data['success'] == true) {
          var activitiesData = data['data'];
          print('Activities data type: ${activitiesData.runtimeType}');
          print('Activities data: $activitiesData');

          if (activitiesData is List) {
            List<Map<String, dynamic>> safeActivities = [];
            for (var activity in activitiesData) {
              if (activity is Map) {
                safeActivities.add(Map<String, dynamic>.from(activity));
              }
            }
            _processMuscleGroupData(safeActivities);
          } else {
            print('Activities data is not a list: ${activitiesData.runtimeType}');
            _processMuscleGroupData([]);
          }
        } else {
          print('API response indicates failure or wrong format');
          _processMuscleGroupData([]);
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        _processMuscleGroupData([]);
      }
    } catch (e, stackTrace) {
      print('Error fetching workout data: $e');
      print('Stack trace: $stackTrace');
      _processMuscleGroupData([]);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchCompletedExercises() async {
    try {
      print('Fetching completed exercises for user ID: ${safeUserId}');

      final response = await http.get(
        Uri.parse('$baseUrl/exercise_completions_api.php?user_id=$safeUserId&date=${DateTime.now().toIso8601String().split('T')[0]}'),
      );

      print('Completed exercises response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['success'] == true) {
          var completedData = data['completed_exercises'];
          if (completedData is List) {
            Set<String> safeCompletedExercises = {};
            for (var exercise in completedData) {
              safeCompletedExercises.add(_safeParseString(exercise));
            }
            if (mounted) {
              setState(() {
                completedExercises = safeCompletedExercises;
              });
            }
          }
        }
      }
    } catch (e, stackTrace) {
      print('Error fetching completed exercises: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> markExerciseCompleted(String exerciseName, Map<String, dynamic> exercise) async {
    try {
      print('Marking exercise completed: $exerciseName for user: ${safeUserId}');

      final response = await http.post(
        Uri.parse('$baseUrl/exercise_completions_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': safeUserId,
          'exercise_name': exerciseName,
          'date': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      print('Mark exercise response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['success'] == true) {
          // Also add to activities for tracking
          await addExerciseAsActivity(exerciseName, exercise);

          if (mounted) {
            setState(() {
              completedExercises.add(exerciseName);
            });
          }

          _showSuccessSnackBar('Exercise completed! Great job! 🎉');
        } else {
          _showErrorSnackBar(_safeParseString(data['message']) ?? 'Failed to mark exercise as completed');
        }
      }
    } catch (e, stackTrace) {
      print('Error marking exercise as completed: $e');
      print('Stack trace: $stackTrace');
      _showErrorSnackBar('Error marking exercise as completed');
    }
  }

  Future<void> addExerciseAsActivity(String exerciseName, Map<String, dynamic> exercise) async {
    try {
      print('Adding exercise as activity: $exerciseName');

      final response = await http.post(
        Uri.parse('$baseUrl/activity_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': safeUserId,
          'activity_type': exerciseName,
          'duration_minutes': _safeParseInt(exercise['duration']),
          'calories_burned': _safeParseInt(exercise['calories']),
          'date': DateTime.now().toIso8601String().split('T')[0],
        }),
      );

      print('Add activity response: ${response.body}');

      // Refresh workout data to update progress
      await fetchWorkoutData();
    } catch (e, stackTrace) {
      print('Error adding exercise as activity: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> resetProgress() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Reset Progress'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will permanently delete:'),
            SizedBox(height: 12),
            Text('• All your workout activities', style: TextStyle(color: Colors.red)),
            Text('• All nutrition records', style: TextStyle(color: Colors.red)),
            Text('• All completed exercises', style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            Text('This action cannot be undone!',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Reset All Data'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _performReset();
    }
  }

  Future<void> _performReset() async {
    try {
      // Reset activities
      await http.delete(
        Uri.parse('$baseUrl/reset_user_data.php?user_id=${widget.userId}&type=all'),
      );

      setState(() {
        muscleGroupProgress.clear();
        completedExercises.clear();
        totalWorkouts = 0;
      });

      _showSuccessSnackBar('All progress reset successfully');

      // Refresh data
      fetchWorkoutData();
      fetchCompletedExercises();
    } catch (e) {
      _showErrorSnackBar('Error resetting progress');
    }
  }

  void _processMuscleGroupData(List<Map<String, dynamic>> activities) {
    Map<String, int> progress = {
      'chest': 0,
      'arms': 0,
      'shoulders': 0,
      'abs': 0,
      'legs': 0,
      'back': 0,
    };

    totalWorkouts = activities.length;

    for (var activity in activities) {
      // Debug print to see the data structure
      print('Processing activity: $activity');

      // Safe parsing of activity data with detailed debugging
      String activityType = _safeParseString(activity['activity_type']).toLowerCase();
      print('Activity type parsed: $activityType');

      // Enhanced muscle group mapping
      if (activityType.contains('push') || activityType.contains('chest') ||
          (activityType.contains('press') && activityType.contains('chest'))) {
        progress['chest'] = (progress['chest']! + 1);
      } else if (activityType.contains('curl') || activityType.contains('tricep') ||
          activityType.contains('pull-up') || activityType.contains('dip')) {
        progress['arms'] = (progress['arms']! + 1);
      } else if (activityType.contains('squat') || activityType.contains('lunge') ||
          activityType.contains('leg') || activityType.contains('run') ||
          activityType.contains('cycling')) {
        progress['legs'] = (progress['legs']! + 1);
      } else if (activityType.contains('row') || activityType.contains('pulldown') ||
          activityType.contains('deadlift') || activityType.contains('back')) {
        progress['back'] = (progress['back']! + 1);
      } else if (activityType.contains('crunch') || activityType.contains('plank') ||
          activityType.contains('twist') || activityType.contains('ab')) {
        progress['abs'] = (progress['abs']! + 1);
      } else if (activityType.contains('shoulder') || activityType.contains('lateral') ||
          activityType.contains('shrug')) {
        progress['shoulders'] = (progress['shoulders']! + 1);
      } else {
        // Default to legs for general activities
        progress['legs'] = (progress['legs']! + 1);
      }
    }

    print('Final progress map: $progress'); // Debug line

    setState(() {
      muscleGroupProgress = progress;
    });
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    int workouts = _safeParseInt(muscleGroupProgress[muscleGroup]);
    if (workouts == 0) return Colors.grey.shade300;
    if (workouts <= 2) return Colors.orange.shade300;
    if (workouts <= 5) return Colors.blue.shade400;
    if (workouts <= 10) return Colors.green.shade400;
    return Colors.purple.shade400;
  }

  int _getMuscleGroupLevel(String muscleGroup) {
    int workouts = _safeParseInt(muscleGroupProgress[muscleGroup]);
    return (workouts / 3).floor() + 1;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner': return Colors.green;
      case 'intermediate': return Colors.orange;
      case 'advanced': return Colors.red;
      default: return Colors.blue;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildBodyPart({
    required String bodyPart,
    required double top,
    required double left,
    required double width,
    required double height,
    required String displayName,
  }) {
    Color partColor = _getMuscleGroupColor(bodyPart);
    bool isSelected = selectedBodyPart == bodyPart;
    int level = _getMuscleGroupLevel(bodyPart);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
      builder: (context, child) {
        return Positioned(
          top: top,
          left: left,
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedBodyPart = bodyPart;
              });
              _showBodyPartDialog(bodyPart, displayName);
            },
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: partColor,
                borderRadius: BorderRadius.circular(width / 4),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: partColor.withOpacity(_glowAnimation.value),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                ],
              ),
              transform: Matrix4.identity()
                ..scale(isSelected ? _pulseAnimation.value : 1.0),
              child: Stack(
                children: [
                  // Gradient overlay for 3D effect
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(width / 4),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                  // Level indicator
                  if (level > 1)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'L$level',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBodyPartDialog(String bodyPart, String displayName) {
    int workouts = _safeParseInt(muscleGroupProgress[bodyPart]);
    int level = _getMuscleGroupLevel(bodyPart);
    List<Map<String, dynamic>> exercises = muscleGroupExercises[bodyPart] ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getMuscleGroupColor(bodyPart).withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getMuscleGroupColor(bodyPart),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Level $level • $workouts workouts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (workouts % 3) / 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getMuscleGroupColor(bodyPart),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${workouts % 3}/3 to next level',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),

              SizedBox(height: 20),
              Text(
                'Recommended Exercises:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: exercises.map((exercise) => _buildExerciseCard(exercise)).toList(),
                  ),
                ),
              ),

              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getMuscleGroupColor(bodyPart),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    String exerciseName = exercise['name'];
    bool isCompleted = completedExercises.contains(exerciseName);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green.shade300 : Colors.grey.shade300,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exerciseName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green.shade800 : Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(exercise['difficulty']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  exercise['difficulty'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getDifficultyColor(exercise['difficulty']),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          Text(
            exercise['description'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12),

          Row(
            children: [
              _buildExerciseInfo(Icons.timer, '${_safeParseInt(exercise['duration'])}min', Colors.blue),
              SizedBox(width: 16),
              _buildExerciseInfo(Icons.repeat, _safeParseString(exercise['reps']), Colors.orange),
              SizedBox(width: 16),
              _buildExerciseInfo(Icons.local_fire_department, '${_safeParseInt(exercise['calories'])} cal', Colors.red),
            ],
          ),
          SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCompleted ? null : () => markExerciseCompleted(exerciseName, exercise),
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.favorite,
                size: 20,
              ),
              label: Text(
                isCompleted ? 'Completed Today!' : 'Mark as Completed',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.green.shade400 : Colors.red.shade500,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInfo(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _build3DBody() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_rotationAnimation.value * 0.3)
            ..rotateX(0.1),
          child: Container(
            width: 200,
            height: 350,
            child: Stack(
              children: [
                // Head
                _buildBodyPart(
                  bodyPart: 'head',
                  top: 10,
                  left: 75,
                  width: 50,
                  height: 60,
                  displayName: 'Head & Neck',
                ),

                // Shoulders
                _buildBodyPart(
                  bodyPart: 'shoulders',
                  top: 70,
                  left: 50,
                  width: 100,
                  height: 30,
                  displayName: 'Shoulders',
                ),

                // Arms
                _buildBodyPart(
                  bodyPart: 'arms',
                  top: 80,
                  left: 20,
                  width: 25,
                  height: 80,
                  displayName: 'Arms',
                ),
                _buildBodyPart(
                  bodyPart: 'arms',
                  top: 80,
                  left: 155,
                  width: 25,
                  height: 80,
                  displayName: 'Arms',
                ),

                // Chest
                _buildBodyPart(
                  bodyPart: 'chest',
                  top: 100,
                  left: 65,
                  width: 70,
                  height: 50,
                  displayName: 'Chest',
                ),

                // Abs
                _buildBodyPart(
                  bodyPart: 'abs',
                  top: 150,
                  left: 70,
                  width: 60,
                  height: 60,
                  displayName: 'Abs & Core',
                ),

                // Back (slightly offset to show 3D effect)
                _buildBodyPart(
                  bodyPart: 'back',
                  top: 110,
                  left: 75,
                  width: 50,
                  height: 80,
                  displayName: 'Back',
                ),

                // Legs
                _buildBodyPart(
                  bodyPart: 'legs',
                  top: 210,
                  left: 60,
                  width: 35,
                  height: 120,
                  displayName: 'Legs',
                ),
                _buildBodyPart(
                  bodyPart: 'legs',
                  top: 210,
                  left: 105,
                  width: 35,
                  height: 120,
                  displayName: 'Legs',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1).withOpacity(0.1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF6366F1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Body Development Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: resetProgress,
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Workouts',
                  totalWorkouts.toString(),
                  Icons.fitness_center,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Completed Today',
                  completedExercises.length.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          Text(
            'Muscle Group Levels:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 12),

          ...muscleGroupProgress.entries.map((entry) {
            String muscleGroup = entry.key;
            int workouts = _safeParseInt(entry.value);
            int level = _getMuscleGroupLevel(muscleGroup);

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getMuscleGroupColor(muscleGroup),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        muscleGroup[0].toUpperCase() + muscleGroup.substring(1),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Level $level',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '$workouts workouts',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Body Visualizer 3D',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: isLoading
                ? Container(
              height: 400,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                    SizedBox(height: 16),
                    Text('Loading body data...'),
                  ],
                ),
              ),
            )
                : Column(
              children: [
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.shade50,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Interactive 3D Body Model',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap on body parts to see exercises and track progress',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),

                      // 3D Body Model
                      Center(child: _build3DBody()),

                      SizedBox(height: 30),

                      // Legend
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildLegendItem('Beginner', Colors.orange.shade300),
                          _buildLegendItem('Intermediate', Colors.blue.shade400),
                          _buildLegendItem('Advanced', Colors.green.shade400),
                          _buildLegendItem('Expert', Colors.purple.shade400),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildStatsCard(),

                SizedBox(height: 100), // Space for bottom navigation
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}