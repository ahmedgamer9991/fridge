import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/services/firebase_services.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/utils/helpers.dart';
import 'package:Eyeventory/models/inventory_item.dart';
import 'package:Eyeventory/screens/store/store_fridge_inventory.dart';

class StoreDashboard extends ConsumerStatefulWidget {
  const StoreDashboard({super.key});

  @override
  ConsumerState<StoreDashboard> createState() => _StoreDashboardState();
}

class _StoreDashboardState extends ConsumerState<StoreDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedStatFilter = 'all';
  Timer? _debounce;
  bool _isSearching = false;

  final Map<String, String> _statFilterMap = {
    'Total Items': 'all',
    'Expiring Soon': 'expiring',
    'Low Stock': 'low_stock',
    'Spoiled/Expired': 'spoiled',
  };

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _isSearching = value.isNotEmpty;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {}); // Trigger rebuild to apply filter
      }
    });
  }

  String _getAppBarTitle(String storeName) {
    if (_isSearching) {
      return 'Searching...';
    }
    return storeName;
  }

  @override
  Widget build(BuildContext context) {
    final fridgesAsync = ref.watch(userFridgesProvider);
    final storeName = ref.watch(storeNameProvider);

    // 1. Gather all fridges to calculate combined stats and perform filtering
    final fridges = fridgesAsync.value ?? [];
    final List<InventoryItem> allItems = [];

    // Dynamically watch each fridge's items to compute combined stats and filter reactively
    for (final fridge in fridges) {
      final fridgeId = fridge['id'] as String;
      final itemsAsync = ref.watch(fridgeItemsProvider(fridgeId));
      final items = itemsAsync.value ?? [];
      allItems.addAll(items);
    }

    final searchQuery = _searchController.text.toLowerCase().trim();

    // Check if a cooler card should be shown based on search query
    bool matchesFridge(String fridgeName, List<InventoryItem> items) {
      // Apply Search Query only
      if (searchQuery.isEmpty) return true;

      final matchesFridgeName = fridgeName.toLowerCase().contains(searchQuery);
      final matchesItemName = items.any((i) =>
          i.name.toLowerCase().contains(searchQuery) ||
          i.category.toLowerCase().contains(searchQuery));

      return matchesFridgeName || matchesItemName;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: _getAppBarTitle(storeName),
        automaticallyImplyLeading: false,
        actions: [
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _isSearching = false;
                });
                _focusNode.unfocus();
              },
              tooltip: 'Clear search',
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                _focusNode.unfocus();
                setState(() {
                  _isSearching = false;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 1. Combined Stats Grid (Dependant on Data)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StatsGrid(
                  items: allItems,
                  selectedFilterKey: 'all',
                  onFilterSelected: null,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 2. Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppSearchBar(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    setState(() {
                      _searchController.clear();
                      _focusNode.unfocus();
                      _isSearching = false;
                    });
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 3. Fridge List
            if (fridgesAsync.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              (() {
                final filteredFridges = fridges.where((fridge) {
                  final fridgeId = fridge['id'] as String;
                  final fridgeName = fridge['name'] as String? ?? 'Unnamed Fridge';
                  final itemsAsync = ref.watch(fridgeItemsProvider(fridgeId));
                  final items = itemsAsync.value ?? [];
                  return matchesFridge(fridgeName, items);
                }).toList();

                if (filteredFridges.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.kitchen_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isNotEmpty || _selectedStatFilter != 'all'
                                ? "No matching coolers found"
                                : "No Fridges or Coolers Found",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchQuery.isNotEmpty || _selectedStatFilter != 'all'
                                ? "Try clearing search or filters"
                                : "Add a new fridge/cooler using the + button",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final fridge = filteredFridges[index];
                      final fridgeId = fridge['id'] as String;
                      final fridgeName = fridge['name'] as String? ?? 'Unnamed Fridge';

                      final itemsAsync = ref.watch(fridgeItemsProvider(fridgeId));
                      final items = itemsAsync.value ?? [];

                      return _buildFridgeCard(
                        id: fridgeId,
                        name: fridgeName,
                        items: items,
                      );
                    },
                    childCount: filteredFridges.length,
                  ),
                );
              }()),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFridgeDialog(context),
        backgroundColor: colorsPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFridgeCard({
    required String id,
    required String name,
    required List<InventoryItem> items,
  }) {
    final int itemCount = items.length;
    final int expiring = items.where((i) => i.status == 'Expiring Soon').length;
    final int spoiled = items.where((i) => i.status == 'Spoiled').length;

    final List<Color> colors = [
      Colors.green.shade100,
      Colors.blue.shade100,
      Colors.cyan.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
    ];
    final Color headerColor = colors[id.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoreFridgeInventoryScreen(
                fridgeId: id,
                initialFridgeName: name,
              ),
            ),
          );
        },
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat(
                        Icons.inventory_2_outlined,
                        "$itemCount Items",
                        Colors.black,
                      ),
                      _buildMiniStat(
                        Icons.timer_outlined,
                        "$expiring Expiring",
                        statusExpiring,
                      ),
                      _buildMiniStat(
                        Icons.cancel_outlined,
                        "$spoiled Spoiled",
                        statusSpoiled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreFridgeInventoryScreen(
                              fridgeId: id,
                              initialFridgeName: name,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorsPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("View Details"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFridgeDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Fridge/Cooler'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Drink Display, Produce Cooler',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(firebaseServicesProvider).createCustomFridge(name);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created fridge "$name"'),
                      backgroundColor: colorsPrimary,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
