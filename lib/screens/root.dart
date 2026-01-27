import 'package:flutter/material.dart';
import 'package:Eyeventory/screens/home/home_root.dart';
import 'package:Eyeventory/screens/store/store_root.dart';
import 'package:Eyeventory/services/firebase_services.dart';
import 'package:Eyeventory/screens/shared/loading.dart';

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      final userData = await FirebaseServices().getUserProfile();
      if (mounted) {
        setState(() {
          _userRole = userData?['role'] as String? ?? 'home'; // Default to home
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error or default to home
      if (mounted) {
        setState(() {
          _userRole = 'home';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    if (_userRole == 'store') {
      return const StoreRoot();
    }

    return const HomeRoot();
  }
}
