import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/services/firebase_services.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/utils/helpers.dart';
import 'package:Eyeventory/models/inventory_item.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  bool _isSearching = false;
  String _selectedStatFilter = 'all';
  final Map<String, String> _statFilterMap = {
    'Total Items': 'all',
    'Expiring Soon': 'expiring',
    'Low Stock': 'low_stock',
    'Spoiled/Expired': 'spoiled',
  };

  Widget _buildInventoryList(List<InventoryItem> items, bool isLoading) {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }



    // Apply search filter
    final filteredItems = _filterItems(items);

    if (filteredItems.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildItemCard(filteredItems[index]),
        childCount: filteredItems.length,
      ),
    );
  }

  List<InventoryItem> _filterItems(List<InventoryItem> items) {
    final searchTerm = _searchController.text.toLowerCase().trim();
    List<InventoryItem> filtered = items.where((item) {
      if (_selectedCategory == 'All') return true;
      return item.category == _selectedCategory;
    }).toList();

    // Apply stat filter second
    filtered = _applyStatFilter(filtered);

    if (searchTerm.isEmpty) {
      _isSearching = false;
      return filtered;
    }

    _isSearching = true;
    return filtered.where((item) {
      final itemName = item.name.toLowerCase();
      final category = item.category.toLowerCase();
      final status = item.status.toLowerCase();
      return itemName.contains(searchTerm) ||
          category.contains(searchTerm) ||
          status.contains(searchTerm);
    }).toList();
  }

  List<InventoryItem> _applyStatFilter(List<InventoryItem> items) {
    switch (_selectedStatFilter) {
      case 'all':
        return items;
      case 'expiring':
        return items.where((item) => item.status == 'Expiring Soon').toList();
      case 'low_stock':
        return items.where((item) => AppHelpers.isLowStock(item)).toList();
      case 'spoiled':
        return items.where((item) => item.status == 'Spoiled').toList();
      default:
        return items;
    }
  }

  // Low Stock logic moved to AppHelpers

  void _onSearchChanged(String value) {
    // Cancel previous debounce timer
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _isSearching = value.isNotEmpty;

    // Set new timer
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          // The filter will be applied in the build method
        });
      }
    });
  }

  String _getAppBarTitle(List<InventoryItem> items, String fridgeName) {
    if (_isSearching) {
      return '${_filterItems(items).length} results';
    }

    if (_selectedStatFilter != 'all') {
      final filterName = _statFilterMap.entries
          .firstWhere((e) => e.value == _selectedStatFilter)
          .key;
      return 'Showing: $filterName';
    }

    return fridgeName;
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final items = inventoryAsync.value ?? [];
    final isLoading = inventoryAsync.isLoading && items.isEmpty;
    final fridgeName = ref.watch(fridgeNameProvider);

    return Scaffold(
      appBar: AppHeader(
        title: _getAppBarTitle(items, fridgeName),
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
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // Stats Grid (2x2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildStatsGrid(items),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _searchBar(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Scrollable Category Chips
            SliverToBoxAdapter(child: _buildScrollableCategories()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Item List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: _buildInventoryList(items, isLoading),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ), // Bottom padding for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-item');
          // ScaffoldMessenger.of(
          //   context,
          // ).showSnackBar(const SnackBar(content: Text('Add new item')));
        },
        backgroundColor: colorsPrimary,
        shape: CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _searchBar() {
    return AppSearchBar(
      controller: _searchController,
      focusNode: _focusNode,
      onChanged: _onSearchChanged,
      onClear: () {
        _searchController.clear();
        _focusNode.unfocus(); // Hide keyboard
        setState(() {
          _isSearching = false;
        });
      },
    );
  }

  Widget _buildStatsGrid(List<InventoryItem> items) {
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

  Widget _buildScrollableCategories() {
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

  Widget _buildItemCard(InventoryItem item) {
    return InventoryItemCard(
      title: item.name,
      subtitle: '${item.quantity} ${item.unit}',
      status: item.status,
      statusColor: AppHelpers.getStatusColor(item.status),
      expiryText: AppHelpers.formatExpiryDate(item.expiryDate),
      onTap: () {
        Navigator.pushNamed(context, '/item-details', arguments: item.id);
      },
    );
  }

  Widget _buildEmptyState() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No items found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check your spelling',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.inventory_2, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No items in inventory',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first item using the + button',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
