import 'package:flutter/material.dart';
import 'package:Eyeventory/screens/home/home_root.dart';
import 'package:Eyeventory/screens/store/store_root.dart';

import 'package:Eyeventory/models/inventory_item.dart';

class Root extends StatelessWidget {
  final String userRole;
  final List<InventoryItem>? initialItems;

  const Root({super.key, required this.userRole, this.initialItems});

  @override
  Widget build(BuildContext context) {
    if (userRole == 'store') {
      return StoreRoot(initialItems: initialItems);
    }
    return HomeRoot(initialItems: initialItems);
  }
}
