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
  final String source; // "camera" or "manual"
  final String shelfId;
  final String shelfName;
  final String? createdBy;

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
    this.source = 'manual',
    this.shelfId = 'A',
    this.shelfName = 'Top Shelf',
    this.createdBy,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map, String docId) {
    final source = map['source'] as String? ?? 'manual';
    final shelfId = map['shelfId'] as String? ?? 'A';
    final shelfName = map['shelfName'] as String? ?? 'Top Shelf';

    final detected = map['detected'] as Map<String, dynamic>? ?? {};
    final userOverrides = map['userOverrides'] as Map<String, dynamic>? ?? {};

    final String name = map['name'] as String? ??
        userOverrides['name'] as String? ??
        detected['name'] as String? ??
        'Unknown Item';

    final String quantity = userOverrides['quantity']?.toString() ??
        detected['quantity']?.toString() ??
        map['quantity']?.toString() ??
        '1';

    final String unit = userOverrides['unit'] as String? ??
        detected['unit'] as String? ??
        map['unit'] as String? ??
        'units';

    final String status = userOverrides['status'] as String? ??
        detected['freshness'] as String? ??
        map['status'] as String? ??
        'Fresh';

    final String category = userOverrides['category'] as String? ??
        detected['category'] as String? ??
        map['category'] as String? ??
        'Others';

    final DateTime? expiryDate = (userOverrides['expiryDate'] as Timestamp?)?.toDate() ??
        (detected['expiryDate'] as Timestamp?)?.toDate() ??
        (map['expiryDate'] as Timestamp?)?.toDate();

    final DateTime? createdAt = (map['createdAt'] as Timestamp?)?.toDate();
    final DateTime? updatedAt = (map['updatedAt'] as Timestamp?)?.toDate();

    final String? imageUrl = userOverrides['imageUrl'] as String? ??
        detected['imageUrl'] as String? ??
        map['imageUrl'] as String?;

    final String? notes = userOverrides['notes'] as String? ??
        detected['notes'] as String? ??
        map['notes'] as String?;

    return InventoryItem(
      id: docId,
      name: name,
      quantity: quantity,
      unit: unit,
      status: status,
      category: category,
      expiryDate: expiryDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      imageUrl: imageUrl,
      notes: notes,
      source: source,
      shelfId: shelfId,
      shelfName: shelfName,
      createdBy: userOverrides['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'source': source,
      'shelfId': shelfId,
      'shelfName': shelfName,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'userOverrides': {
        'quantity': quantity,
        'unit': unit,
        'status': status,
        'category': category,
        'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
        'imageUrl': imageUrl,
        'notes': notes,
        'createdBy': createdBy,
      }
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
    String? source,
    String? shelfId,
    String? shelfName,
    String? createdBy,
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
      source: source ?? this.source,
      shelfId: shelfId ?? this.shelfId,
      shelfName: shelfName ?? this.shelfName,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
