import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/screens/home/home_root.dart';
import 'package:Eyeventory/screens/store/store_root.dart';
import 'package:Eyeventory/services/firebase_services.dart';

class Root extends ConsumerWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final userRole = profileAsync.value?['role'] as String? ?? 'home';

    if (userRole == 'store') {
      return const StoreRoot();
    }
    return const HomeRoot();
  }
}
