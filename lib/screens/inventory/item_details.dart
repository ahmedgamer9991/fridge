import 'package:flutter/material.dart';
import 'package:fridge/services/firebase_services.dart';
import 'package:fridge/utils/constants.dart';
import 'package:fridge/widgets/widgets.dart';
import 'package:fridge/utils/helpers.dart';
import 'package:fridge/utils/error_utils.dart';
import 'package:fridge/models/inventory_item.dart';
import 'package:fridge/services/notification_service.dart';

class ItemDetailsScreen extends StatefulWidget {
  const ItemDetailsScreen({super.key});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late String _itemId;
  InventoryItem? _itemData;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
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
        final item = await FirebaseServices().getItem(_itemId);

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
          _errorMessage = ErrorUtils.parseError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: _itemData?.name ?? 'Item Details',
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
            Text(
              _errorMessage ?? 'Failed to load item details',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
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
        border: Border.all(color: colorsBorder),
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
    final status = _itemData?.status ?? 'Fresh';
    Color statusColor = AppHelpers.getStatusColor(status);

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
                TextSpan(
                  text: _itemData?.name ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
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
          const SizedBox(height: 8),
          Text(
            '${_itemData?.quantity ?? ''} ${_itemData?.unit ?? ''}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildProductDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildProductDetailsCard() {
    final expiryDate = _itemData?.expiryDate;
    String expiryText = AppHelpers.formatExpiryDate(expiryDate);

    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.scale,
          label: 'Quantity',
          value: '${_itemData?.quantity ?? 1} ${_itemData?.unit ?? 'units'}',
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
          icon: Icons.add_box_outlined,
          label: 'Added On',
          value: _formatDate(_itemData?.createdAt),
        ),
        const Divider(height: 15, thickness: .5),
        SizedBox(height: 15),
        _buildDetailRow(
          icon: Icons.category,
          label: 'Category',
          value: _itemData?.category ?? 'Uncategorized',
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
              Navigator.pushNamed(
                context,
                '/edit-item',
                arguments: _itemData?.id,
              ).then((_) {
                // Reload item data when coming back from edit screen
                _loadItemData();
              });
            },
            textColor: Colors.white,
            title: "Edit Item",
          ),
          const SizedBox(height: 12),

          // Mark as Consumed Button
          _actionButton(
            onPressed: () {
              _updateItemStatus("Consumed");
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
              _updateItemStatus("Thrown Away");
            },
            backgroundColor: Colors.white,
            icon: Icons.delete,
            textColor: Colors.black,
            title: "Mark as Thrown Away",
          ),
          const SizedBox(height: 12),

          // Delete Button
          _actionButton(
            onPressed: () {
              _showDeleteConfirmation();
            },
            backgroundColor: statusSpoiled,
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
              ? BorderSide(color: colorsBorder)
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

  Future<void> _updateItemStatus(String status) async {
    if (_itemData == null) return;
    try {
      final updatedItem = _itemData!.copyWith(status: status);
      await FirebaseServices().updateItem(updatedItem);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item marked as $status'),
          backgroundColor: colorsPrimary,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ErrorUtils.showErrorSnackBar(context, ErrorUtils.parseError(error));
    }
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

                // Cancel notifications
                await NotificationService().cancelNotification(
                  AppHelpers.getHashCode('${_itemId}_warning'),
                );
                await NotificationService().cancelNotification(
                  AppHelpers.getHashCode('${_itemId}_expired'),
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } catch (error) {
                if (!mounted) return;
                ErrorUtils.showErrorSnackBar(
                  context,
                  ErrorUtils.parseError(error),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
