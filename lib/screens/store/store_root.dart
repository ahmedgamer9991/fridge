import 'package:flutter/material.dart';
import 'package:Eyeventory/screens/store/notifications_screen.dart';
import 'package:Eyeventory/screens/shared/profile.dart';
import 'package:Eyeventory/screens/store/store_dashboard.dart';
import 'package:Eyeventory/screens/store/store_insights.dart';
import 'package:Eyeventory/utils/constants.dart';

class StoreRoot extends StatefulWidget {
  const StoreRoot({super.key});

  @override
  State<StoreRoot> createState() => _StoreRootState();
}

class _StoreRootState extends State<StoreRoot> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const StoreDashboard(),
      const StoreInsights(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black, offset: Offset(0, 4), blurRadius: 4),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: colorsPrimary,
          unselectedItemColor: colorsSecondary,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inventory', // Dashboard
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notification',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
