import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/services/firebase_services.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Eyeventory/utils/helpers.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();

  String? _selectedCategory;
  String? _selectedUnit;
  DateTime? _selectedExpiryDate;

  @override
  void initState() {
    super.initState();
    // _quantityController.text = '1';
    _selectedCategory = itemCategories[0];
    _selectedUnit = itemUnits[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    _focusNode3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: 'Add Item'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Placeholder
              Center(
                child: Container(
                  width: 300,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: colorsBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: Colors.grey[500],
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload or take a photo of the item',
                        style: TextStyle(fontSize: 14, color: colorsSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
                    // initialValue: _selectedCategory,
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
                            // contentPadding: const EdgeInsets.symmetric(
                            //   horizontal: 12,
                            //   vertical: 12,
                            // ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unit
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          // initialValue: "Select Unit",
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
                            // contentPadding: const EdgeInsets.symmetric(
                            //   horizontal: 12,
                            //   vertical: 12,
                            // ),
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
                          initialDate: DateTime.now(),
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
                  AppButton(
                    text: 'Save Item',
                    onPressed: () async {
                      final name = _nameController.text.trim();
                      if (name.isNotEmpty &&
                          _selectedCategory != null &&
                          _selectedUnit != null) {
                        // Save item logic here

                        // Use a local variable to capture context if needed, but here we can just check mounted
                        try {
                          final docId = await ref.read(firebaseServicesProvider).addItem(
                            name: name,
                            category: _selectedCategory!,
                            quantity: _quantityController.text.trim().isEmpty
                                ? '1'
                                : _quantityController.text.trim(),
                            unit: _selectedUnit!,
                            expiryDate: _selectedExpiryDate,
                          );

                          // Schedule Notifications
                          if (_selectedExpiryDate != null) {
                            final prefs = await SharedPreferences.getInstance();
                            final double threshold =
                                prefs.getDouble('notifyBeforeExpiry') ??
                                kDefaultExpiryThreshold;

                            // 1. Threshold Warning (e.g., 3 days before)
                            await NotificationService()
                                .scheduleExpiryNotification(
                                  id: AppHelpers.getHashCode(
                                    '${docId}_warning',
                                  ),
                                  itemName: name,
                                  expiryDate: _selectedExpiryDate!,
                                  daysBefore: threshold.toInt(),
                                );

                            // 2. Expiry Date Alert (0 days before - Today)
                            await NotificationService()
                                .scheduleExpiryNotification(
                                  id: AppHelpers.getHashCode(
                                    '${docId}_expired',
                                  ),
                                  itemName: name,
                                  expiryDate: _selectedExpiryDate!,
                                  daysBefore: 0,
                                );
                          }

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item added successfully!'),
                            ),
                          );
                          Navigator.pop(context);
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter item name'),
                          ),
                        );
                        return;
                      }
                    },
                  ),
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
}
