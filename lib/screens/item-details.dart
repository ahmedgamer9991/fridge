import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fridge/services/firebase_services.dart';
import 'package:fridge/utils/constants.dart';

class ItemDetailsScreen extends StatefulWidget {
  const ItemDetailsScreen({super.key});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late String _itemId;
  Map<String, dynamic>? _itemData;
  bool _isLoading = true;
  bool _hasError = false;
  // late bool updated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadItemData();
      }
    });
  }

  Future<void> _loadItemData() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _itemId = args;
        final item = await FirebaseServices().getItemById(_itemId);

        if (mounted) {
          setState(() {
            _itemData = item;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Invalid navigation arguments');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          debugPrint('Error loading item: $e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          _itemData?['name'] ?? 'Item Details',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        // actions: [
        //   PopupMenuButton<String>(
        //     icon: const Icon(Icons.more_vert, color: Colors.black),
        //     onSelected: (value) {
        //       if (value == 'delete') {
        //         _showDeleteConfirmation();
        //       }
        //     },
        //     itemBuilder: (context) => [
        //       const PopupMenuItem(
        //         value: 'delete',
        //         child: Text('Delete Item', style: TextStyle(color: Colors.red)),
        //       ),
        //     ],
        //   ),
        // ],
        elevation: .5,
        shadowColor: Colors.black,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load item details',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _loadItemData();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorsPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_itemData == null) {
      return const Center(child: Text('Item not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          _buildProductImage(),
          const SizedBox(height: 20),

          // Product Header
          _buildProductDetails(),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorsBorder!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_drink_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Item image will appear here',
            style: TextStyle(fontSize: 14, color: colorsSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    final status = _itemData?['status'] as String? ?? 'Fresh';
    Color statusColor;
    // String statusText;
    // switch (status) {
    //   case 'Fresh':
    //     statusColor = const Color(0xFF2E7D32);
    //     break;
    //   case 'Expiring Soon':
    // statusColor = const Color(0xFFFF6F00);
    //     break;
    //   case 'Spoiled':
    //     statusColor = const Color(0xFFD32F2F);
    //     break;
    //   default:
    //     statusColor = Colors.grey;
    // }
    switch (status) {
      case 'Expiring Soon':
        statusColor = const Color(0xFFFFA726);
        // statusText = 'Expiring Soon';
        break;
      case 'Spoiled':
        statusColor = const Color(0xFFD32F2F);
        // statusText = 'Spoiled';
        break;
      case 'Fresh':
        statusColor = const Color(0xFF2E7D32);
        break;
      default:
        statusColor = Colors.grey;
      // statusText = 'Fresh';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: .5),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            text: TextSpan(
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.2,
              ),
              children: [
                TextSpan(text: _itemData?['name'] as String? ?? 'Unnamed Item'),
                WidgetSpan(
                  alignment: .middle,
                  child: Container(
                    margin: EdgeInsets.only(left: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildProductDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildProductDetailsCard() {
    final expiryDate = _itemData?['expiryDate'] as Timestamp?;
    String expiryText = 'No expiry date';

    if (expiryDate != null) {
      final date = expiryDate.toDate();
      expiryText = '${date.day}/${date.month}/${date.year}';
    }

    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.scale,
          label: 'Quantity',
          value:
              '${_itemData?['quantity'] ?? 1} ${_itemData?['unit'] ?? 'units'}',
        ),
        const Divider(height: 15, thickness: .5),
        SizedBox(height: 15),
        _buildDetailRow(
          icon: Icons.calendar_today,
          label: 'Expires on',
          value: expiryText,
        ),
        const Divider(height: 15, thickness: .5),
        SizedBox(height: 15),
        _buildDetailRow(
          icon: Icons.category,
          label: 'Category',
          value: _itemData?['category'] as String? ?? 'Uncategorized',
        ),
        const Divider(height: 15, thickness: .5),
        SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: .w500),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: .5),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Edit Button
          _actionButton(
            backgroundColor: colorsPrimary,
            icon: Icons.edit_outlined,
            onPressed: () async {
              Map<String, dynamic> items = {"id": _itemId, ..._itemData!};
              final updated = await Navigator.pushNamed(
                context,
                '/edit-item',
                arguments: items, //todo itemData
              );
              // print(updated);
              if (updated == true) _loadItemData();
            },
            textColor: Colors.black,
            title: "Edit Item",
          ),
          const SizedBox(height: 12),

          // Mark as Consumed Button
          _actionButton(
            onPressed: () {
              _updateItemStatus("consumed");
            },
            backgroundColor: Colors.white,
            icon: Icons.check_box_outlined,
            textColor: Colors.black,
            title: "Mark as Consumed",
          ),
          const SizedBox(height: 12),

          // Mark as Thrown Away Button
          _actionButton(
            onPressed: () {
              _updateItemStatus("thrown_away");
            },
            backgroundColor: Colors.white,
            icon: Icons.delete,
            textColor: Colors.black,
            title: "Mark as Trown Away",
          ),
          const SizedBox(height: 12),

          // Delete Button
          _actionButton(
            onPressed: () {
              _showDeleteConfirmation();
            },
            backgroundColor: const Color(0xFFD32F2F),
            icon: Icons.cancel_outlined,
            textColor: Colors.white,
            title: "Delete Item",
          ),
        ],
      ),
    );
  }

  SizedBox _actionButton({
    required VoidCallback? onPressed,
    required Color? backgroundColor,
    required IconData? icon,
    required Color? textColor,
    required String? title,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: backgroundColor == Colors.white
              ? BorderSide(color: colorsBorder!)
              : null,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: textColor),
              const SizedBox(width: 8),
              Text(
                title ?? "forgot the title",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateItemStatus(String status) {
    FirebaseServices()
        .updateItem(_itemId, {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item marked as $status'),
              backgroundColor: colorsPrimary,
            ),
          );
          Navigator.pop(context);
        })
        .catchError((error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $error')));
        });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              try {
                await FirebaseServices().deleteItem(_itemId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $error')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
