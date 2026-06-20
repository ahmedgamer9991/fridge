import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/services/firebase_services.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/utils/helpers.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/models/inventory_item.dart';

class StoreDashboard extends ConsumerStatefulWidget {
  const StoreDashboard({super.key});

  @override
  ConsumerState<StoreDashboard> createState() => _StoreDashboardState();
}

class _StoreDashboardState extends ConsumerState<StoreDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedCategory = 'All';
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
  void initState() {
    super.initState();
  }

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
    if (_selectedStatFilter != 'all') {
      final filterName = _statFilterMap.entries
          .firstWhere((e) => e.value == _selectedStatFilter)
          .key;
      return 'Showing: $filterName';
    }
    return storeName;
  }

  @override
  Widget build(BuildContext context) {
    final fridgesAsync = ref.watch(userFridgesProvider);
    final activeFridgeIdAsync = ref.watch(activeFridgeIdProvider);
    final activeFridgeId = activeFridgeIdAsync.value;
    final fridgeName = ref.watch(fridgeNameProvider);

    return Scaffold(
      appBar: AppHeader(
        title: _getAppBarTitle(fridgeName),
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedCategory != 'All')
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _selectedStatFilter = 'all'; // Keep this reset just in case
                  _selectedCategory = 'All';
                  _searchController.clear();
                  _isSearching = false;
                });
                _focusNode.unfocus();
              },
              tooltip: 'Clear category filter',
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

            // 1. Stats Grid (Dependant on Data)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: fridgesAsync.when(
                  data: (fridges) {
                    if (activeFridgeId != null) {
                      final itemsAsync = ref.watch(fridgeItemsProvider(activeFridgeId));
                      final items = itemsAsync.value ?? [];
                      return StatsGrid(
                        items: items,
                        selectedFilterKey: _selectedStatFilter,
                        onFilterSelected: (key) {
                          setState(() {
                            _selectedStatFilter = key;
                            _selectedCategory = 'All';
                          });
                        },
                      );
                    }
                    return const StatsGrid(items: []);
                  },
                  loading: () => const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => const StatsGrid(items: []),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 2. Search Bar (Static - Always Visible)
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

            // 3. Categories (Static - Always Visible)
            SliverToBoxAdapter(child: _buildCategories()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 4. Fridge list (Dependant on Data)
            if (fridgesAsync.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              (() {
                final fridges = fridgesAsync.value ?? [];
                
                if (fridges.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.kitchen_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text("No Fridges or Coolers Found"),
                          SizedBox(height: 8),
                          Text("Add a new fridge/cooler using the + button", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }

                final searchQuery = _searchController.text.toLowerCase().trim();

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final fridge = fridges[index];
                      final fridgeId = fridge['id'] as String;
                      final fridgeName = fridge['name'] as String? ?? 'Unnamed Fridge';
                      final isActive = activeFridgeId == fridgeId;

                      final itemsAsync = ref.watch(fridgeItemsProvider(fridgeId));
                      return itemsAsync.when(
                        data: (items) {
                          final filteredItems = _filterItems(items);
                          
                          final matchesCategoryFilter = _selectedCategory == 'All' || items.any((i) => i.category == _selectedCategory);
                          final matchesQuery = searchQuery.isEmpty || 
                                               fridgeName.toLowerCase().contains(searchQuery) || 
                                               items.any((i) => i.name.toLowerCase().contains(searchQuery));

                          if (!matchesCategoryFilter || !matchesQuery) {
                            return const SizedBox.shrink();
                          }

                          return _buildFridgeCard(
                            id: fridgeId,
                            name: fridgeName,
                            isActive: isActive,
                            items: filteredItems,
                          );
                        },
                        loading: () => const Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                        error: (err, stack) => Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text('Error loading $fridgeName'),
                            subtitle: Text(err.toString()),
                          ),
                        ),
                      );
                    },
                    childCount: fridges.length,
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
                  final newFridgeId = await ref.read(firebaseServicesProvider).createCustomFridge(name);
                  // Make the newly created fridge active
                  await ref.read(activeFridgeIdProvider.notifier).setActiveFridge(newFridgeId);
                  
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created fridge "$name"'),
                      backgroundColor: colorsPrimary,
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
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

  List<InventoryItem> _filterItems(List<InventoryItem> items) {
    if (_searchController.text.isEmpty &&
        _selectedCategory == 'All' &&
        _selectedStatFilter == 'all') {
      return items;
    }

    final query = _searchController.text.toLowerCase();
    return items.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;

      final matchesStat =
          _selectedStatFilter == 'all' ||
          (_selectedStatFilter == 'expiring' &&
              item.status == 'Expiring Soon') ||
          (_selectedStatFilter == 'spoiled' && item.status == 'Spoiled') ||
          (_selectedStatFilter == 'low_stock' && AppHelpers.isLowStock(item));

      return matchesQuery && matchesCategory && matchesStat;
    }).toList();
  }

  Widget _buildCategories() {
    final categories = ['All', ...itemCategories];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedCategory = category),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: isSelected ? Colors.green[50] : Colors.white,
                side: BorderSide(
                  color: isSelected ? const Color(0xFFE8F5E9) : colorsBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                foregroundColor: isSelected ? colorsPrimary : Colors.black,
              ),
              child: Text(category, style: const TextStyle(fontSize: 14)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFridgeCard({
    required String id,
    required String name,
    required bool isActive,
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
        border: isActive ? Border.all(color: colorsPrimary, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await ref.read(activeFridgeIdProvider.notifier).setActiveFridge(id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched active storage to "$name"'),
              backgroundColor: colorsPrimary,
              duration: const Duration(seconds: 2),
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
                          Colors.black.withValues(alpha: 0.6),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
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
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorsPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  "ACTIVE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                      ],
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
                      onPressed: () async {
                        await ref.read(activeFridgeIdProvider.notifier).setActiveFridge(id);
                        if (!mounted) return;
                        _showFridgeContents(context, name, items);
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

  void _showFridgeContents(
    BuildContext context,
    String title,
    List<InventoryItem> items,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            "No items in this section",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return InventoryItemCard(
                              title: item.name,
                              subtitle: '${item.quantity} ${item.unit}',
                              status: item.status,
                              statusColor: AppHelpers.getStatusColor(
                                item.status,
                              ),
                              expiryText: AppHelpers.formatExpiryDate(
                                item.expiryDate,
                              ),
                              onTap: () {
                                Navigator.pop(context); // Close sheet
                                Navigator.pushNamed(
                                  context,
                                  '/item-details',
                                  arguments: item.id,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
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
