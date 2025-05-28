import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class DataTrackerPage extends StatefulWidget {
  final int userId;

  const DataTrackerPage({Key? key, required this.userId}) : super(key: key);

  @override
  _DataTrackerPageState createState() => _DataTrackerPageState();
}

class _DataTrackerPageState extends State<DataTrackerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> activities = [];
  List<dynamic> nutrition = [];
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    await fetchActivities();
    await fetchNutrition();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/activity_api.php?user_id=${widget.userId}&date=${selectedDate.toIso8601String().split('T')[0]}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            activities = data['data'];
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error fetching activities');
    }
  }

  Future<void> fetchNutrition() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nutrition_api.php?user_id=${widget.userId}&date=${selectedDate.toIso8601String().split('T')[0]}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            nutrition = data['data'];
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error fetching nutrition');
    }
  }

  Future<void> addActivity(String type, int duration, int calories) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/activity_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'activity_type': type,
          'duration_minutes': duration,
          'calories_burned': calories,
          'date': selectedDate.toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showSuccessSnackBar('Activity added successfully');
          fetchActivities();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error adding activity');
    }
  }

  Future<void> addNutrition(String food, int calories, String mealType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nutrition_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'food_item': food,
          'calories': calories,
          'meal_type': mealType,
          'date': selectedDate.toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showSuccessSnackBar('Nutrition added successfully');
          fetchNutrition();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error adding nutrition');
    }
  }

  Future<void> deleteActivity(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/activity_api.php?id=$id'),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Activity deleted');
        fetchActivities();
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting activity');
    }
  }

  Future<void> deleteNutrition(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/nutrition_api.php?id=$id'),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Nutrition item deleted');
        fetchNutrition();
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting nutrition');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddActivityDialog() {
    final typeController = TextEditingController();
    final durationController = TextEditingController();
    final caloriesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Activity'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                decoration: InputDecoration(
                  labelText: 'Activity Type',
                  hintText: 'e.g., Running, Cycling, Swimming',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: caloriesController,
                decoration: InputDecoration(
                  labelText: 'Calories Burned',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (typeController.text.isNotEmpty &&
                  durationController.text.isNotEmpty &&
                  caloriesController.text.isNotEmpty) {
                addActivity(
                  typeController.text,
                  int.tryParse(durationController.text) ?? 0,
                  int.tryParse(caloriesController.text) ?? 0,
                );
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddNutritionDialog() {
    final foodController = TextEditingController();
    final caloriesController = TextEditingController();
    String mealType = 'breakfast';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Nutrition'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: foodController,
                  decoration: InputDecoration(
                    labelText: 'Food Item',
                    hintText: 'e.g., Apple, Sandwich, Salad',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: caloriesController,
                  decoration: InputDecoration(
                    labelText: 'Calories',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: mealType,
                      isExpanded: true,
                      items: ['breakfast', 'lunch', 'dinner', 'snack']
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type[0].toUpperCase() + type.substring(1)),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          mealType = value!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (foodController.text.isNotEmpty &&
                    caloriesController.text.isNotEmpty) {
                  addNutrition(
                    foodController.text,
                    int.tryParse(caloriesController.text) ?? 0,
                    mealType,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Your Data'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.fitness_center), text: 'Activities'),
            Tab(icon: Icon(Icons.restaurant), text: 'Nutrition'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Date',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                      fetchData();
                    }
                  },
                  icon: Icon(Icons.calendar_today),
                  label: Text('Change'),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                // Activities tab
                activities.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No activities recorded',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap + to add your first activity',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.fitness_center, color: Colors.white),
                        ),
                        title: Text(
                          activity['activity_type'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${activity['duration_minutes']} min • ${activity['calories_burned']} cal',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => deleteActivity(activity['id']),
                        ),
                      ),
                    );
                  },
                ),

                // Nutrition tab
                nutrition.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No meals recorded',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap + to add your first meal',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: nutrition.length,
                  itemBuilder: (context, index) {
                    final food = nutrition[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getMealColor(food['meal_type']),
                          child: Icon(Icons.restaurant, color: Colors.white),
                        ),
                        title: Text(
                          food['food_item'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${food['meal_type'][0].toUpperCase() + food['meal_type'].substring(1)} • ${food['calories']} cal',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => deleteNutrition(food['id']),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddActivityDialog();
          } else {
            _showAddNutritionDialog();
          }
        },
        child: Icon(Icons.add),
        tooltip: _tabController.index == 0 ? 'Add Activity' : 'Add Meal',
      ),
    );
  }

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.purple;
      case 'snack':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }
}