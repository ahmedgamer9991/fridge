import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fridge/services/firebase_services.dart';
import 'package:fridge/utils/constants.dart';
import 'package:fridge/widgets/widgets.dart';
import 'package:fridge/models/inventory_item.dart';

class StoreDashboard extends StatefulWidget {
  const StoreDashboard({super.key});

  @override
  State<StoreDashboard> createState() => _StoreDashboardState();
}

class _StoreDashboardState extends State<StoreDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedCategory = 'All';
  String _selectedStatFilter = 'all';
  Timer? _debounce;
  bool _isSearching = false;
  late Stream<List<InventoryItem>> _itemsStream;

  final Map<String, String> _statFilterMap = {
    'Total Items': 'all',
    'Expiring Soon': 'expiring',
    'Low Stock': 'low_stock',
    'Spoiled/Expired': 'spoiled',
  };

  @override
  void initState() {
    super.initState();
    _itemsStream = FirebaseServices().getItems();
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
    return Scaffold(
      appBar: AppHeader(
        title: _getAppBarTitle(),
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedStatFilter != 'all' || _selectedCategory != 'All')
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _selectedStatFilter = 'all';
                  _selectedCategory = 'All';
                  _searchController.clear();
                  _isSearching = false;
                });
                _focusNode.unfocus();
              },
              tooltip: 'Clear all filters',
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
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
                child: StreamBuilder<List<InventoryItem>>(
                  stream: _itemsStream,
                  builder: (context, snapshot) {
                    // If loading, show placeholder or spinner only here?
                    // Or just show stats with 0?
                    // Usually StatsGrid handles empty lists gracefully since we pass list.
                    // But we must handle 'waiting'.

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return StatsGrid(
                      items: snapshot.data ?? [],
                      selectedFilterKey: _selectedStatFilter,
                      onFilterSelected: (key) {
                        setState(() {
                          _selectedStatFilter = key;
                        });
                      },
                    );
                  },
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
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 4. Fridge Sections (Dependant on Data)
            StreamBuilder<List<InventoryItem>>(
              stream: _itemsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final allItems = snapshot.data ?? [];
                final filteredItems = _filterItems(allItems);

                // If search yields no results
                if (filteredItems.isEmpty &&
                    (_isSearching || _selectedCategory != 'All')) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text("No Items Found"),
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
                    childCount: 3, // Fridge A, B, C
                  ),
                );
              },
            ),

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
          (_selectedStatFilter == 'low_stock' &&
              _isLowStock(
                item,
              )); // Reusing low stock logic if possible or duplicating

      return matchesQuery && matchesCategory && matchesStat;
    }).toList();
  }

  // Duplicated generic low stock logic for filtering
  bool _isLowStock(InventoryItem item) {
    try {
      final q = double.parse(item.quantity);
      if (item.unit == 'units' || item.unit == 'pack') return q <= 2;
      if (item.unit == 'g' || item.unit == 'ml') return q <= 100;
      if (item.unit == 'kg' || item.unit == 'L') return q <= 0.5;
      return q <= 2;
    } catch (_) {
      return false;
    }
  }

  Widget _buildCategories() {
    final categories = ['All', ...itemCategories];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return OutlinedButton(
            onPressed: () => setState(() => _selectedCategory = cat),
            style: OutlinedButton.styleFrom(
              backgroundColor: isSelected ? Colors.transparent : Colors.white,
              side: BorderSide(color: isSelected ? Colors.black : colorsBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              foregroundColor: Colors.black,
            ),
            child: Text(
              cat,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
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
    // Map existing categories to "Fridges" to match the design aesthetics

    String title;
    String subtitle;
    List<InventoryItem> fridgeItems;
    // Color or Image placeholder
    Color color;

    if (index == 0) {
      // Fridge A: Produce (Fruits & Veggies)
      title = "Fridge A";
      subtitle = "Fruits & Veggies";
      fridgeItems = allItems.where((i) => i.category == 'Produce').toList();
      color = Colors.green.shade100;
    } else if (index == 1) {
      // Fridge B: Meat
      title = "Fridge B";
      subtitle = "Meats & Poultry";
      fridgeItems = allItems.where((i) => i.category == 'Meat').toList();
      color = Colors.red.shade100;
    } else if (index == 2) {
      // Fridge C: Dairy
      title = "Fridge C";
      subtitle = "Dairy Products";
      fridgeItems = allItems.where((i) => i.category == 'Dairy').toList();
      color = Colors.blue.shade100;
    } else {
      return null;
    }

    // Only show fridge if it implies items matches filters,
    // OR show empty stats if strict.
    // Let's show filtered stats.

    int itemCount = fridgeItems.length;
    int expiring = fridgeItems.where((i) => i.status == 'Expiring Soon').length;
    int spoiled = fridgeItems.where((i) => i.status == 'Spoiled').length;

    return {
      'title': title,
      'subtitle': subtitle,
      'itemCount': itemCount,
      'expiring': expiring,
      'spoiled': spoiled,
      'color': color,
      'items': fridgeItems, // Passed if we want to navigate to details
    };
  }

  Widget _buildFridgeCard(Map<String, dynamic> data) {
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
              color: data['color'], // Fallback color
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              // TODO: Add actual image per design if available
              // image: DecorationImage(image: ... fit: BoxFit.cover)
            ),
            child: Stack(
              children: [
                // Gradient overlay for text readability
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
                      // Navigate to details or filtered list
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF386641,
                      ), // Dark green from design
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
