import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class InsightsPage extends StatefulWidget {
  final int userId;

  const InsightsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _InsightsPageState createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  Map<String, dynamic> stats = {};
  bool isLoading = true;
  int selectedDays = 7;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats_api.php?user_id=${widget.userId}&days=$selectedDays'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            stats = data;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching stats: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBreakdown() {
    if (stats['activity_breakdown'] == null || stats['activity_breakdown'].isEmpty) {
      return Card(
        elevation: 2,
        child: Container(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No activities recorded in this period',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...stats['activity_breakdown'].map<Widget>((activity) {
              // Add comprehensive null safety checks
              final totalCaloriesBurned = stats['activity_stats']?['total_calories_burned'];
              final activityCalories = activity['total_calories'];

              // Safely convert to double with null checks
              double totalBurned = 0.0;
              double calories = 0.0;

              if (totalCaloriesBurned != null) {
                totalBurned = double.tryParse(totalCaloriesBurned.toString()) ?? 0.0;
              }

              if (activityCalories != null) {
                calories = double.tryParse(activityCalories.toString()) ?? 0.0;
              }

              final percentage = totalBurned > 0 ? (calories / totalBurned * 100) : 0.0;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(activity['activity_type'] ?? 'Unknown Activity'),
                      Text('${calories.toInt()} cal'),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${activity['count'] ?? 0} sessions',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  double _calculateBMI() {
    if (stats['user_metrics'] != null &&
        stats['user_metrics']['height_cm'] != null &&
        stats['user_metrics']['weight_kg'] != null) {
      final height = stats['user_metrics']['height_cm'] / 100;
      final weight = stats['user_metrics']['weight_kg'];
      return weight / (height * height);
    }
    return 0.0;
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insights & Analytics'),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchStats,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Period selector
              Container(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Show data for: '),
                    SizedBox(width: 16),
                    SegmentedButton<int>(
                      selected: {selectedDays},
                      onSelectionChanged: (Set<int> selected) {
                        setState(() {
                          selectedDays = selected.first;
                        });
                        fetchStats();
                      },
                      segments: [
                        ButtonSegment(
                          value: 7,
                          label: Text('7 days'),
                        ),
                        ButtonSegment(
                          value: 14,
                          label: Text('14 days'),
                        ),
                        ButtonSegment(
                          value: 30,
                          label: Text('30 days'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BMI Card
                    if (stats['user_metrics'] != null && stats['user_metrics']['bmi'] != null)
                      Card(
                        elevation: 4,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getBMIColor(stats['user_metrics']['bmi'].toDouble()).withOpacity(0.2),
                                _getBMIColor(stats['user_metrics']['bmi'].toDouble()).withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Body Mass Index (BMI)',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                stats['user_metrics']['bmi'].toString(),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: _getBMIColor(stats['user_metrics']['bmi'].toDouble()),
                                ),
                              ),
                              Text(
                                _getBMICategory(stats['user_metrics']['bmi'].toDouble()),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: _getBMIColor(stats['user_metrics']['bmi'].toDouble()),
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.height, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    '${stats['user_metrics']['height_cm']} cm',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  SizedBox(width: 16),
                                  Icon(Icons.monitor_weight, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    '${stats['user_metrics']['weight_kg']} kg',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 20),

                    // Activity and Nutrition Summary
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Total Activities',
                            stats['activity_stats']?['total_activities']?.toString() ?? '0',
                            Icons.fitness_center,
                            Colors.blue,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            'Total Duration',
                            '${stats['activity_stats']?['total_duration_minutes'] ?? 0} min',
                            Icons.timer,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Calories Burned',
                            stats['activity_stats']?['total_calories_burned']?.toString() ?? '0',
                            Icons.local_fire_department,
                            Colors.red,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            'Calories Consumed',
                            stats['nutrition_stats']?['total_calories_consumed']?.toString() ?? '0',
                            Icons.restaurant,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Net Calories Card
                    Card(
                      elevation: 4,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (stats['net_calories'] ?? 0) >= 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              (stats['net_calories'] ?? 0) >= 0
                                  ? Colors.green.withOpacity(0.05)
                                  : Colors.red.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Net Calories',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  (stats['net_calories'] ?? 0) >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: (stats['net_calories'] ?? 0) >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  size: 32,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${stats['net_calories'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: (stats['net_calories'] ?? 0) >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              (stats['net_calories'] ?? 0) >= 0
                                  ? 'Calorie Deficit'
                                  : 'Calorie Surplus',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Average Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Avg. Daily Calories',
                            stats['nutrition_stats']?['avg_daily_calories']?.toString() ?? '0',
                            Icons.calendar_today,
                            Colors.purple,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            'Avg. Workout Time',
                            '${stats['activity_stats']?['avg_duration_minutes'] ?? 0} min',
                            Icons.access_time,
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Activity Breakdown
                    _buildActivityBreakdown(),

                    SizedBox(height: 20),

                    // Insights Summary
                    Card(
                      elevation: 2,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildInsightRow(
                              Icons.info_outline,
                              'You\'ve been active for ${stats['activity_stats']?['total_activities'] ?? 0} sessions in the last $selectedDays days',
                              Colors.blue,
                            ),
                            SizedBox(height: 8),
                            _buildInsightRow(
                              Icons.local_fire_department,
                              'Average ${stats['activity_stats']?['avg_calories_burned'] ?? 0} calories burned per workout',
                              Colors.orange,
                            ),
                            SizedBox(height: 8),
                            _buildInsightRow(
                              Icons.restaurant,
                              'Daily average intake: ${stats['nutrition_stats']?['avg_daily_calories'] ?? 0} calories',
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}