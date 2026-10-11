import '../core/helpers.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  Product({
    String? id,
    required this.name,
    required this.price,
    this.description = '',
    this.isActive = true,
    DateTime? createdAt,
  })  : id = id ?? generateId(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': toDbString(createdAt),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: fromDbString(map['created_at'] as String),
    );
  }

  Product copyWith({
    String? name,
    double? price,
    String? description,
    bool? isActive,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, price: $price)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
