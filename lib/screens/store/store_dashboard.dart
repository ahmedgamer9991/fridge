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

  String _getAppBarTitle() {
    if (_isSearching) {
      return 'Searching...';
    }
    if (_selectedStatFilter != 'all') {
      final filterName = _statFilterMap.entries
          .firstWhere((e) => e.value == _selectedStatFilter)
          .key;
      return 'Showing: $filterName';
    }
    return 'My Home Fridge';
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final allItems = inventoryAsync.value ?? [];
    final isLoading = inventoryAsync.isLoading && allItems.isEmpty;

    return Scaffold(
      appBar: AppHeader(
        title: _getAppBarTitle(),
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
                child: isLoading
                    ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : StatsGrid(
                        items: allItems,
                        // Interaction disabled for store dashboard
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

            // 4. Fridge Sections (Dependant on Data)
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              (() {
                final filteredItems = _filterItems(allItems);

                // If search yields no results
                if (filteredItems.isEmpty &&
                    (_isSearching || _selectedCategory != 'All')) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text("No Items Found"),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final fridgeData = _getFridgeData(index, filteredItems);
                      if (fridgeData == null) return const SizedBox.shrink();
                      return _buildFridgeCard(fridgeData);
                    },
                    childCount: 4, // Fridge A, B, Freezer, Pantry
                  ),
                );
              }()),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
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

  Map<String, dynamic>? _getFridgeData(
    int index,
    List<InventoryItem> allItems,
  ) {
    String title;
    String subtitle;
    List<InventoryItem> fridgeItems;
    Color color;

    if (index == 0) {
      // Fridge A: Produce
      title = "Fridge Section A";
      subtitle = "Fruits & Veggies";
      fridgeItems = allItems.where((i) => i.category == 'Produce').toList();
      color = Colors.green.shade100;
    } else if (index == 1) {
      // Fridge B: Essentials
      title = "Fridge Section B";
      subtitle = "Meats & Dairy";
      fridgeItems = allItems
          .where((i) => i.category == 'Meat' || i.category == 'Dairy')
          .toList();
      color = Colors.blue.shade100;
    } else if (index == 2) {
      // Freezer
      title = "Freezer";
      subtitle = "Frozen Goods";
      fridgeItems = allItems.where((i) => i.category == 'Frozen').toList();
      color = Colors.cyan.shade100;
    } else if (index == 3) {
      // Pantry
      title = "Pantry & Shelves";
      subtitle = "Dry Goods & Beverages";
      fridgeItems = allItems
          .where((i) => i.category == 'Pantry' || i.category == 'Beverage' || i.category == 'Others')
          .toList();
      color = Colors.orange.shade100;
    } else {
      return null;
    }

    int itemCount = fridgeItems.length;
    int expiring = fridgeItems.where((i) => i.status == 'Expiring Soon').length;
    int spoiled = fridgeItems.where((i) => i.status == 'Spoiled').length;

    // Only return if we want to show empty sections? Yes, to show potential storage.
    return {
      'title': title,
      'subtitle': subtitle,
      'itemCount': itemCount,
      'expiring': expiring,
      'spoiled': spoiled,
      'color': color,
      'items': fridgeItems,
    };
  }

  Widget _buildFridgeCard(Map<String, dynamic> data) {
    final List<InventoryItem> items = data['items'] as List<InventoryItem>;

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image / Header Section
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: data['color'],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
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
                  child: Text(
                    "${data['title']} - ${data['subtitle']}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat(
                      Icons.inventory_2_outlined,
                      "${data['itemCount']} Items",
                      Colors.black,
                    ),
                    _buildMiniStat(
                      Icons.timer_outlined,
                      "${data['expiring']} Expiring",
                      statusExpiring,
                    ),
                    _buildMiniStat(
                      Icons.cancel_outlined,
                      "${data['spoiled']} Spoiled",
                      statusSpoiled,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showFridgeContents(context, data['title'], items);
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: items.isEmpty
                      ? Center(
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
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
