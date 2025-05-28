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
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
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
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddActivityDialog();
        },
        child: Icon(Icons.add),
        tooltip: 'Add Activity',
      ),
    );
  }
}