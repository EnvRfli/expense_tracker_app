import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // 'income' or 'expense'

  @HiveField(3)
  String iconCodePoint; // Icon data untuk consistency

  @HiveField(4)
  String colorValue; // Color hex value

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  bool isDefault; // Kategori bawaan sistem

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
    required this.colorValue,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  // Convert to JSON untuk Google Drive backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  // Create from JSON untuk restore dari Google Drive
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      iconCodePoint: json['iconCodePoint'],
      colorValue: json['colorValue'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isDefault: json['isDefault'] ?? false,
    );
  }

  // Copy with untuk update
  CategoryModel copyWith({
    String? name,
    String? type,
    String? iconCodePoint,
    String? colorValue,
    bool? isActive,
    DateTime? updatedAt,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
