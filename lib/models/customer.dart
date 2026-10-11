import '../core/helpers.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final DateTime createdAt;

  Customer({
    String? id,
    required this.name,
    required this.phone,
    DateTime? createdAt,
  })  : id = id ?? generateId(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'created_at': toDbString(createdAt),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      createdAt: fromDbString(map['created_at'] as String),
    );
  }

  Customer copyWith({
    String? name,
    String? phone,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'Customer(id: $id, name: $name, phone: $phone)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
