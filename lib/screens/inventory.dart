import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fridge/services/firebase_services.dart';
import 'package:fridge/utils/constants.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  final List<Map<String, dynamic>> _allItems = [];
  bool _isSearching = false;
  String _selectedStatFilter = 'all';
  final Map<String, String> _statFilterMap = {
    'Total Items': 'all',
    'Expiring Soon': 'expiring',
    'Low Stock': 'low_stock',
    'Spoiled/Expired': 'spoiled',
  };

  StreamBuilder<List<Map<String, dynamic>>> _buildInventoryList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseServices().getItemsWithStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];

        // Store all items for search
        if (!_isSearching && items.isNotEmpty) {
          _allItems.clear();
          _allItems.addAll(items);
        }

        // Apply search filter
        final filteredItems = _filterItems(items);

        if (filteredItems.isEmpty) {
          return _buildEmptyState();
        }

        return Column(children: filteredItems.map(_buildItemCard).toList());
      },
    );
  }

  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> items) {
    final searchTerm = _searchController.text.toLowerCase().trim();
    List<Map<String, dynamic>> filtered = items.where((item) {
      if (_selectedCategory == 'All') return true;
      return (item['category'] as String?) == _selectedCategory;
    }).toList();

    // Apply stat filter second
    filtered = _applyStatFilter(filtered);

    if (searchTerm.isEmpty) {
      _isSearching = false;
      return filtered;
    }

    _isSearching = true;
    return filtered.where((item) {
      final itemName = (item['name'] as String).toLowerCase();
      final category = (item['category'] as String?)?.toLowerCase() ?? '';
      final status = (item['status'] as String).toLowerCase();
      return itemName.contains(searchTerm) ||
          category.contains(searchTerm) ||
          status.contains(searchTerm);
    }).toList();
  }

  List<Map<String, dynamic>> _applyStatFilter(
    List<Map<String, dynamic>> items,
  ) {
    switch (_selectedStatFilter) {
      case 'all':
        return items;
      case 'expiring':
        return items
            .where((item) => item['status'] == 'Expiring Soon')
            .toList();
      case 'low_stock':
        return items.where(_isLowStock).toList();
      case 'spoiled':
        return items.where((item) => item['status'] == 'Spoiled').toList();
      default:
        return items;
    }
  }

  bool _isLowStock(Map<String, dynamic> item) {
    int quantity = item['quantity'] as int;
    String unit = item['unit'] as String;

    if (unit == 'units' || unit == 'pack') {
      return quantity <= 2;
    } else if (unit == 'g' || unit == 'ml') {
      return quantity <= 100;
    } else if (unit == 'kg' || unit == 'L') {
      return quantity <= 0.5;
    }
    return quantity <= 2;
  }
  // todo make it one function if possible
  // int _calculateLowStock(List<Map<String, dynamic>> items) {
  //   // Define low stock threshold (customize as needed)
  //   return items.where((item) {
  //     int quantity = item['quantity'] as int;
  //     String unit = item['unit'] as String;

  //     // Different thresholds for different units
  //     if (unit == 'units' || unit == 'pack') {
  //       return quantity <= 2;
  //     } else if (unit == 'g' || unit == 'ml') {
  //       return quantity <= 100;
  //     } else if (unit == 'kg' || unit == 'L') {
  //       return quantity <= 0.5;
  //     }
  //     return quantity <= 2;
  //   }).length;
  // }

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

  Text _getAppBarTitle() {
    if (_isSearching) {
      return Text('${_filterItems(_allItems).length} results');
    }

    if (_selectedStatFilter != 'all') {
      final filterName = _statFilterMap.entries
          .firstWhere((e) => e.value == _selectedStatFilter)
          .key;
      return Text('Showing: $filterName');
    }

    return const Text('My Home Fridge');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: _getAppBarTitle(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
        elevation: .5,
        shadowColor: Colors.black,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    // Stats Grid (2x2)
                    _buildStatsGrid(),
                    const SizedBox(height: 16),

                    // Search Bar
                    _searchBar(),
                    const SizedBox(height: 12),

                    // Scrollable Category Chips
                    _buildScrollableCategories(),
                    const SizedBox(height: 12),

                    // Item List
                    _buildInventoryList(),
                    const SizedBox(height: 7),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add item screen
          Navigator.pushNamed(context, '/add-item');
          // ScaffoldMessenger.of(
          //   context,
          // ).showSnackBar(const SnackBar(content: Text('Add new item')));
        },
        backgroundColor: colorsPrimary,
        child: const Icon(Icons.add, color: Colors.white),
        shape: CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  TextField _searchBar() {
    return TextField(
      onTapOutside: (event) {
        _focusNode.unfocus();
        if (_searchController.text.isEmpty) {
          setState(() {});
        }
      },
      focusNode: _focusNode,
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search, color: colorsSecondary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close, color: colorsSecondary),
                onPressed: () {
                  _searchController.clear();
                  _focusNode.unfocus(); // Hide keyboard
                  setState(() {
                    _isSearching = false;
                  });
                },
              )
            : null,
        hintText: 'Search food items...',
        hintStyle: TextStyle(color: colorsSecondary),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorsBorder!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorsBorder!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorsPrimary),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseServices().getItemsWithStatus(),
      builder: (context, snapshot) {
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   return _buildLoadingStatsGrid();
        // }

        final items = snapshot.data ?? [];

        int totalItems = items.length;
        int expiringSoon = items
            .where((item) => item['status'] == 'Expiring Soon')
            .length;
        int lowStock = items.where(_isLowStock).length;
        int spoiled = items.where((item) => item['status'] == 'Spoiled').length;

        final stats = [
          {
            'label': 'Total Items',
            'value': '$totalItems',
            'icon': Icons.checklist,
            'color': colorsPrimary,
            'filterKey': 'all',
          },
          {
            'label': 'Expiring Soon',
            'value': '$expiringSoon',
            'icon': Icons.timer,
            'color': const Color(0xFFFF6F00),
            'filterKey': 'expiring',
          },
          {
            'label': 'Low Stock',
            'value': '$lowStock',
            'icon': Icons.shopping_bag,
            'color': const Color(0xFFE6C000),
            'filterKey': 'low_stock',
          },
          {
            'label': 'Spoiled/Expired',
            'value': '$spoiled',
            'icon': Icons.cancel,
            'color': const Color(0xFFD32F2F),
            'filterKey': 'spoiled',
          },
        ];

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats.map((stat) {
            final isActive = _selectedStatFilter == stat['filterKey'];
            final baseColor = stat['color'] as Color;
            final activeColor = baseColor.withValues(alpha: 0.9);

            return SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      // Toggle filter: if already selected, reset to 'all'
                      if (_selectedStatFilter == stat['filterKey'] &&
                          stat['filterKey'] != 'all') {
                        _selectedStatFilter = 'all';
                      } else {
                        _selectedStatFilter = stat['filterKey'] as String;
                      }
                      // Reset category filter when stat filter changes
                      _selectedCategory = 'All';
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Card(
                    elevation: isActive ? 4.0 : 2.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      // side: BorderSide(color: colorsBorder!),
                    ),
                    color: isActive ? activeColor : baseColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: .start,
                        children: [
                          Icon(
                            stat['icon'] as IconData,
                            size: 25,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  stat['value'] as String,
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  stat['label'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: .w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Widget _buildLoadingStatsGrid() {
  //   return Wrap(
  //     spacing: 8,
  //     runSpacing: 8,
  //     children: List.generate(4, (index) {
  //       return SizedBox(
  //         width: (MediaQuery.of(context).size.width - 48) / 2,
  //         height: 96,
  //         child: Card(
  //           elevation: 2.5,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           color: Colors.grey[200],
  //           child: Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Row(
  //               children: [
  //                 Container(
  //                   width: 25,
  //                   height: 25,
  //                   decoration: BoxDecoration(
  //                     color: Colors.grey[300],
  //                     borderRadius: BorderRadius.circular(4),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       Container(
  //                         width: 40,
  //                         height: 25,
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey[300],
  //                           borderRadius: BorderRadius.circular(4),
  //                         ),
  //                       ),
  //                       const SizedBox(height: 4),
  //                       Container(
  //                         width: 80,
  //                         height: 14,
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey[300],
  //                           borderRadius: BorderRadius.circular(4),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     }),
  //   );
  // }

  Widget _buildScrollableCategories() {
    final categories = [
      'All',
      'Produce',
      'Dairy',
      'Meat',
      'Frozen',
      'Pantry',
      'Beverage',
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
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
                backgroundColor: isSelected ? Colors.green[50] : Colors.white,
                side: BorderSide(
                  color: isSelected ? const Color(0xFFE8F5E9) : colorsBorder!,
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

  Widget _buildItemCard(Map<String, dynamic> item) {
    Color statusColor;
    switch (item['status']) {
      case 'Fresh':
        statusColor = const Color(0xFF2E7D32);
        break;
      case 'Expiring Soon':
        statusColor = const Color(0xFFFF6F00);
        break;
      case 'Spoiled':
        statusColor = const Color(0xFFD32F2F);
        break;
      default:
        statusColor = Colors.grey;
    }

    String expiryText = 'No expiry date';
    final expiryDate = item['expiryDate'] as Timestamp?;
    if (expiryDate != null) {
      final date = expiryDate.toDate();
      final now = DateTime.now();
      final daysUntilExpiry = date.difference(now).inDays;

      if (daysUntilExpiry <= 0) {
        expiryText =
            'Expired ${(-daysUntilExpiry).toString()} day${daysUntilExpiry == -1 ? '' : 's'} ago';
      } else if (daysUntilExpiry == 1) {
        expiryText = 'Expires tomorrow';
      } else if (daysUntilExpiry <= 7) {
        expiryText = 'Expires in $daysUntilExpiry days';
      } else {
        expiryText = 'Expires on ${date.day}/${date.month}/${date.year}';
      }
    }

    return Material(
      color: Colors.transparent,
      borderRadius: .circular(12),
      child: Card(
        color: Colors.white,
        elevation: 0.3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorsBorder!, width: .7),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          borderRadius: .circular(12),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/item-details',
              arguments: item['id'] as String,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Image/Icon
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.local_drink, color: Colors.grey[700]),
                ),
                const SizedBox(width: 12),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item['quantity']} ${item['unit']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              item['status'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              expiryText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
