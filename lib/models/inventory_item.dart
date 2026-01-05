import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final String quantity; // e.g., "0.5" or "1"
  final String unit; // e.g., "kg", "units"
  final DateTime? expiryDate;
  final String status; // "Fresh", "Expiring Soon", "Spoiled"
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String category;
  final String? imageUrl;
  final String? notes;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.status,
    required this.category,
    this.expiryDate,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
    this.notes,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map, String docId) {
    return InventoryItem(
      id: docId,
      name: map['name'] as String? ?? 'Unknown Item',
      quantity: map['quantity']?.toString() ?? '0',
      unit: map['unit'] as String? ?? 'units',
      status: map['status'] as String? ?? 'Fresh',
      category: map['category'] as String? ?? 'Others',
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      imageUrl: map['imageUrl'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'status': status,
      'category': category,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'imageUrl': imageUrl,
      'notes': notes,
    };
  }

  InventoryItem copyWith({
    String? name,
    String? quantity,
    String? unit,
    String? status,
    String? category,
    DateTime? expiryDate,
    String? imageUrl,
    String? notes,
  }) {
    return InventoryItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }
}
