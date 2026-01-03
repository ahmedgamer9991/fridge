import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fridge/screens/widgets.dart';
import 'package:fridge/services/firebase_services.dart';
import 'package:fridge/utils/constants.dart';

class EditItemScreen extends StatefulWidget {
  const EditItemScreen({super.key});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  // late String _itemId;
  Map<String, dynamic>? _itemData;
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();

  String? _selectedCategory;
  String? _selectedUnit;
  DateTime? _selectedExpiryDate;

  final List<String> _categories = [
    'Produce',
    'Dairy',
    'Meat',
    'Frozen',
    'Pantry',
    'Beverage',
  ];
  final List<String> _units = [
    'units',
    'g',
    'kg',
    'ml',
    'L',
    'oz',
    'lb',
    'pack',
  ];

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

  void _loadItemData(){
  try {
    // Get item ID from navigation arguments (now safe to access)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _itemData = args;
      
      // Get item ONCE (not a stream)
      // final item = await FirebaseServices().getItemById(_itemId);
      
      if (mounted) {
        setState(() {
          // _itemData = item;
          _isLoading = false;
          // Initialize form controllers with loaded data
          _initFormControllers(_itemData!);
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

  void _initFormControllers(Map<String, dynamic> item) {
    _nameController.text = item['name']?.toString() ?? '';
    _quantityController.text = (item['quantity'] as int?)?.toString() ?? '1';
    _selectedCategory = item['category']?.toString() ?? _categories[0];
    _selectedUnit = item['unit']?.toString() ?? _units[0];

    if (item['expiryDate'] is Timestamp) {
      _selectedExpiryDate = (item['expiryDate'] as Timestamp).toDate();
    } else if (item['expiryDate'] is DateTime) {
      _selectedExpiryDate = item['expiryDate'] as DateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasError) return const Center(child: Text('Failed to load item'));
    if (_itemData == null) return const Center(child: Text('Item not found'));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Edit Item'),
        elevation: .5,
        shadowColor: Colors.black,
      ),
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
                    border: Border.all(color: colorsBorder!),
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
              myTextForm(
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
                    items: _categories.map((category) {
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
                              borderSide: BorderSide(color: colorsBorder!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(20),
                                right: Radius.circular(8),
                              ),
                              borderSide: BorderSide(color: colorsBorder!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(20),
                                right: Radius.circular(8),
                              ),
                              borderSide: BorderSide(color: colorsBorder!),
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
                          initialValue: _selectedUnit,
                          items: _units.map((unit) {
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
                              borderSide: BorderSide(color: colorsBorder!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(8),
                                right: Radius.circular(20),
                              ),
                              borderSide: BorderSide(color: colorsBorder!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(8),
                                right: Radius.circular(20),
                              ),
                              borderSide: BorderSide(color: colorsBorder!),
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
                          initialDate: _selectedExpiryDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
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
                  ElevatedButton(
                    onPressed: () => _saveItem(_itemData!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorsPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                    ),
                    child: const Text(
                      'Save Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Cancel Button
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: colorsBorder!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveItem(Map<String, dynamic> originalItem) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter item name')));
      return;
    }

    // Prepare updates (same logic as before)
    final updates = <String, dynamic>{
      if (_nameController.text.trim() != (originalItem['name'] as String))
        'name': _nameController.text.trim(),
      if (_selectedCategory != (originalItem['category'] as String?))
        'category': _selectedCategory,
      if (_quantityController.text !=
          (originalItem['quantity'] as int).toString())
        'quantity': int.tryParse(_quantityController.text) ?? 1,
      if (_selectedUnit != (originalItem['unit'] as String?))
        'unit': _selectedUnit,
      if (_selectedExpiryDate?.millisecondsSinceEpoch !=
          (originalItem['expiryDate'] as Timestamp?)?.millisecondsSinceEpoch)
        'expiryDate': _selectedExpiryDate,
    };

    // Update using _itemId (which we have from arguments)
    FirebaseServices()
        .updateItem(_itemData!["id"] as String, updates)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully!')),
          );
          Navigator.pop(context, true);
        })
        .catchError((error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $error')));
        });
  }
}
