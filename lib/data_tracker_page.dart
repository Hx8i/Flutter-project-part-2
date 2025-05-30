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
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message, style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
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
            Text(message, style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.white],
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
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.fitness_center, color: Colors.blue.shade700, size: 24),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Add New Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildTextField(
                controller: typeController,
                label: 'Activity Type',
                hint: 'e.g., Running, Cycling, Swimming',
                icon: Icons.directions_run,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: durationController,
                label: 'Duration (minutes)',
                hint: 'Enter duration',
                icon: Icons.timer,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: caloriesController,
                label: 'Calories Burned',
                hint: 'Enter calories',
                icon: Icons.local_fire_department,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text('Cancel', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text('Add Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade50, Colors.white],
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
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.restaurant, color: Colors.green.shade700, size: 24),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Add Nutrition',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildTextField(
                  controller: foodController,
                  label: 'Food Item',
                  hint: 'e.g., Apple, Sandwich, Salad',
                  icon: Icons.fastfood,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: caloriesController,
                  label: 'Calories',
                  hint: 'Enter calories',
                  icon: Icons.local_fire_department,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          'Meal Type',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...['breakfast', 'lunch', 'dinner', 'snack'].map((type) =>
                          RadioListTile<String>(
                            title: Text(
                              type[0].toUpperCase() + type.substring(1),
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            value: type,
                            groupValue: mealType,
                            onChanged: (value) {
                              setState(() {
                                mealType = value!;
                              });
                            },
                            activeColor: Colors.green.shade600,
                            dense: true,
                          ),
                      ).toList(),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text('Cancel', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text('Add Nutrition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
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
              titlePadding: EdgeInsets.only(bottom: 56),
              title: Text(
                'Track Your Data',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(48),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFF6366F1),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center, size: 20),
                          SizedBox(width: 8),
                          Text('Activities', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant, size: 20),
                          SizedBox(width: 8),
                          Text('Nutrition', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1).withOpacity(0.1), Colors.white],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Date',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_getFormattedDate(selectedDate)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
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
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xFF6366F1),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                        fetchData();
                      }
                    },
                    icon: Icon(Icons.calendar_today, size: 18),
                    label: Text('Change', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
                : TabBarView(
              controller: _tabController,
              children: [
                _buildActivitiesTab(),
                _buildNutritionTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (_tabController.index == 0) {
              _showAddActivityDialog();
            } else {
              _showAddNutritionDialog();
            }
          },
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(
            _tabController.index == 0 ? 'Add Activity' : 'Add Meal',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: Color(0xFF6366F1),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildActivitiesTab() {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 48,
                color: Colors.blue.shade400,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No activities recorded',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start tracking your fitness journey',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddActivityDialog,
              icon: Icon(Icons.add),
              label: Text('Add First Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              activity['activity_type'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(
                    '${activity['duration_minutes']} min',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.local_fire_department, size: 16, color: Colors.orange.shade600),
                  SizedBox(width: 4),
                  Text(
                    '${activity['calories_burned']} cal',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: () => _showDeleteDialog(() => deleteActivity(activity['id'])),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutritionTab() {
    if (nutrition.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant,
                size: 48,
                color: Colors.green.shade400,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No meals recorded',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start tracking your nutrition',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddNutritionDialog,
              icon: Icon(Icons.add),
              label: Text('Add First Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: nutrition.length,
      itemBuilder: (context, index) {
        final food = nutrition[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_getMealColor(food['meal_type']).withOpacity(0.1), Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getMealColor(food['meal_type']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getMealIcon(food['meal_type']),
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              food['food_item'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMealColor(food['meal_type']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      food['meal_type'][0].toUpperCase() + food['meal_type'].substring(1),
                      style: TextStyle(
                        color: _getMealColor(food['meal_type']),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.local_fire_department, size: 16, color: Colors.orange.shade600),
                  SizedBox(width: 4),
                  Text(
                    '${food['calories']} cal',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: () => _showDeleteDialog(() => deleteNutrition(food['id'])),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_sunny_outlined;
      case 'dinner':
        return Icons.nightlight_round;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
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