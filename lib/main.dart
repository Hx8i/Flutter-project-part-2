import 'package:flutter/material.dart';
import 'data_tracker_page.dart';
import 'insights_page.dart';

// Change this to your PHP server URL
const String baseUrl = 'http://hadiproject.atwebpages.com/';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titleSpacing: 16,
          toolbarHeight: 56,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.grey.shade500,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final int userId = 1; // Default user ID

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DataTrackerPage(userId: userId),
      InsightsPage(userId: userId),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: AppBar(
              title: Text(
                'Fitness Tracker',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              elevation: 0,
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.fitness_center, 'Track Data'),
                _buildNavItem(1, Icons.analytics, 'Insights'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Color(0xFF6366F1) : Colors.grey.shade500,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Color(0xFF6366F1) : Colors.grey.shade500,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}