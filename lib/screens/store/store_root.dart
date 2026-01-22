import 'package:flutter/material.dart';
import 'package:fridge/screens/shared/grocery.dart';
import 'package:fridge/screens/shared/profile.dart';
import 'package:fridge/screens/store/store_dashboard.dart';
import 'package:fridge/screens/store/store_insights.dart';
import 'package:fridge/utils/constants.dart';

class StoreRoot extends StatefulWidget {
  const StoreRoot({super.key});

  @override
  State<StoreRoot> createState() => _StoreRootState();
}

class _StoreRootState extends State<StoreRoot> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    StoreDashboard(),
    StoreInsights(),
    GroceryScreen(isStoreUser: true),
    ProfileScreen(),
  ];

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
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Inventory', // Dashboard
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inbox_outlined),
              activeIcon: Icon(Icons.inbox),
              label: 'Low Stock',
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
