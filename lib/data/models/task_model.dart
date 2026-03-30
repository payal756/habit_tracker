import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 1)
class TaskModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime lockedUntil;

  @HiveField(5)
  final bool isActive;

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    required this.lockedUntil,
    this.isActive = true,
  });

  bool get isLocked => DateTime.now().isBefore(lockedUntil);
  int get daysLeft => lockedUntil.difference(DateTime.now()).inDays;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // Handle both 'id' and '_id' formats
    final id = json['id']?.toString() ?? json['_id']?.toString() ?? '';

    // Handle title
    final title = json['title']?.toString() ?? '';

    // Handle category
    final category = json['category']?.toString() ?? 'General';

    // Handle dates
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      );
    } catch (e) {
      createdAt = DateTime.now();
    }

    DateTime lockedUntil;
    try {
      lockedUntil = DateTime.parse(
        json['lockedUntil']?.toString() ??
            DateTime.now().add(const Duration(days: 21)).toIso8601String(),
      );
    } catch (e) {
      lockedUntil = DateTime.now().add(const Duration(days: 21));
    }

    // Handle isActive
    final isActive = json['isActive'] ?? true;

    return TaskModel(
      id: id,
      title: title,
      category: category,
      createdAt: createdAt,
      lockedUntil: lockedUntil,
      isActive: isActive is bool ? isActive : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'lockedUntil': lockedUntil.toIso8601String(),
      'isActive': isActive,
    };
  }
}
