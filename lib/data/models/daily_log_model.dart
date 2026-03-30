import 'package:hive/hive.dart';

part 'daily_log_model.g.dart';

@HiveType(typeId: 2)
class DailyLogModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final Map<String, bool> completions; // taskId -> completed

  DailyLogModel({
    required this.id,
    required this.date,
    required this.completions,
  });

  double get completionPercentage {
    if (completions.isEmpty) return 0;
    final completed = completions.values.where((v) => v).length;
    return (completed / completions.length) * 100;
  }

  int get completedCount => completions.values.where((v) => v).length;

  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      id: json['_id'] ?? json['id'] ?? '',
      date: DateTime.parse(json['date']),
      completions: Map<String, bool>.from(json['completions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'date': date.toIso8601String(),
      'completions': completions,
    };
  }
}
