import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/services/firebase_services.dart';
import 'package:Eyeventory/utils/error_utils.dart';
import 'package:Eyeventory/models/inventory_item.dart';
import 'package:Eyeventory/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Eyeventory/utils/helpers.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  const EditItemScreen({super.key});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  InventoryItem? _itemData;

  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();

  String? _selectedCategory;
  String? _selectedUnit;
  DateTime? _selectedExpiryDate;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    super.dispose();
  }

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
      // Get item ID from navigation arguments
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        final item = ref.read(inventoryItemByIdProvider(args));
        if (item != null) {
          if (mounted) {
            setState(() {
              _itemData = item;
              _isLoading = false;
              // Initialize form controllers with loaded data
              _initFormControllers(_itemData!);
            });
          }
        } else {
          final itemFromDb = await ref.read(firebaseServicesProvider).getItem(args);
          if (mounted) {
            setState(() {
              _itemData = itemFromDb;
              _isLoading = false;
              // Initialize form controllers with loaded data
              _initFormControllers(_itemData!);
            });
          }
        }
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

  void _initFormControllers(InventoryItem item) {
    _nameController.text = item.name;
    _quantityController.text = item.quantity;
    _selectedCategory = item.category;
    _selectedUnit = item.unit;
    _selectedExpiryDate = item.expiryDate;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasError) return const Center(child: Text('Failed to load item'));
    if (_itemData == null) return const Center(child: Text('Item not found'));
    return Scaffold(
      appBar: AppHeader(title: 'Edit Item'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Placeholder
              // todo to get the item image
              Center(
                child: Container(
                  width: 300,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: colorsBorder),
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: AssetImage(_itemData != null ? AppHelpers.getItemImage(_itemData!.name) : 'assets/img_placeholder.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Item Name Input
              AppTextFormField(
                title: 'Item Name',
                focusNode: _focusNode1,
                onTapOutside: (event) => _focusNode1.unfocus(),
                controller: _nameController,
                hintText: 'e.g., Milk, Apples, Chicken Breast',
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    items: itemCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: textBorder,
                      enabledBorder: textBorder,
                      focusedBorder: textBorder,
                      hintText: 'Select Category',
                    ),
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quantity & Unit Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quantity & Unit',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Quantity
                      Expanded(
                        child: TextField(
                          focusNode: _focusNode2,
                          onTapOutside: (event) => _focusNode2.unfocus(),
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(20),
                                right: Radius.circular(8),
                              ),
                              borderSide: BorderSide(color: colorsBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(20),
                                right: Radius.circular(8),
                              ),
                              borderSide: BorderSide(color: colorsBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(20),
                                right: Radius.circular(8),
                              ),
                              borderSide: BorderSide(color: colorsBorder),
                            ),
                            hintText: 'e.g., 3',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unit
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedUnit,
                          items: itemUnits.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedUnit = value),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(8),
                                right: Radius.circular(20),
                              ),
                              borderSide: BorderSide(color: colorsBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(8),
                                right: Radius.circular(20),
                              ),
                              borderSide: BorderSide(color: colorsBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(8),
                                right: Radius.circular(20),
                              ),
                              borderSide: BorderSide(color: colorsBorder),
                            ),
                            hintText: 'Select Unit',
                          ),
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Expiry Date Picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expiry Date',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: textBorder,
                      enabledBorder: textBorder,
                      focusedBorder: textBorder,
                    ),
                    child: InkWell(
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedExpiryDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (selectedDate != null) {
                          setState(() => _selectedExpiryDate = selectedDate);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedExpiryDate != null
                                  ? '${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}'
                                  : 'Pick a date',
                              style: TextStyle(
                                color: _selectedExpiryDate != null
                                    ? Colors.black
                                    : colorsSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 42),

              // Action Buttons
              Column(
                crossAxisAlignment: .stretch,
                children: [
                  // Save Button
                  AppButton(text: 'Save Item', onPressed: _saveItem),
                  const SizedBox(height: 12),
                  // Cancel Button
                  AppButton(
                    text: 'Cancel',
                    type: AppButtonType.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter item name')));
      return;
    }

    if (_itemData == null) return;

    final updatedItem = _itemData!.copyWith(
      name: name,
      quantity: _quantityController.text,
      unit: _selectedUnit,
      category: _selectedCategory,
      expiryDate: _selectedExpiryDate,
    );

    try {
      await ref.read(firebaseServicesProvider).updateItem(updatedItem);

      // Reschedule Notifications
      if (_selectedExpiryDate != null) {
        final prefs = await SharedPreferences.getInstance();
        final double threshold =
            prefs.getDouble('notifyBeforeExpiry') ?? kDefaultExpiryThreshold;
        final docId = updatedItem.id;

        // Cancel old ones just in case (though overwrite works, cancelling ensures clean slate if IDs somehow changed logic)
        // Actually overwrite is identical ID, so it's fine.

        // 1. Threshold Warning
        await NotificationService().scheduleExpiryNotification(
          id: AppHelpers.getHashCode('${docId}_warning'),
          itemName: name,
          expiryDate: _selectedExpiryDate!,
          daysBefore: threshold.toInt(),
        );

        // 2. Expiry Day Alert
        await NotificationService().scheduleExpiryNotification(
          id: AppHelpers.getHashCode('${docId}_expired'),
          itemName: name,
          expiryDate: _selectedExpiryDate!,
          daysBefore: 0,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully!')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ErrorUtils.showErrorSnackBar(context, ErrorUtils.parseError(error));
    }
  }
}
