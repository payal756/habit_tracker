import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:mahadev/data/models/user_model.dart';
import 'package:mahadev/data/models/task_model.dart';
import 'package:mahadev/data/models/daily_log_model.dart';
import 'package:mahadev/core/utils/date_utils.dart';

class HiveService {
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      print('  Hive initialized');
    } catch (e) {
      print('  Hive initialization failed: $e');
      rethrow;
    }
  }

  // Generic string box for JSON storage (no adapters needed)
  static Future<Box<String>> _getBox(String name) async {
    try {
      return await Hive.openBox<String>(name);
    } catch (e) {
      print('  Error opening box $name: $e');
      rethrow;
    }
  }

  // ============ CLEAR ALL DATA ============
  static Future<void> clearAll() async {
    try {
      // Close all open boxes first
      await Hive.close();

      // Delete boxes from disk
      await Hive.deleteBoxFromDisk('user');
      await Hive.deleteBoxFromDisk('tasks');
      await Hive.deleteBoxFromDisk('logs');

      // Reopen boxes (they will be empty)
      await Hive.openBox<String>('user');
      await Hive.openBox<String>('tasks');
      await Hive.openBox<String>('logs');

      print('  All Hive data cleared');
    } catch (e) {
      print('  Error clearing Hive: $e');
      // Force delete if normal deletion fails
      try {
        await Hive.deleteFromDisk();
        await Hive.initFlutter();
        await Hive.openBox<String>('user');
        await Hive.openBox<String>('tasks');
        await Hive.openBox<String>('logs');
      } catch (e2) {
        print('  Force clear failed: $e2');
      }
    }
  }

  // ============ USER OPERATIONS ============
  static Future<void> saveUser(UserModel user) async {
    try {
      final box = await _getBox('user');
      final jsonData = json.encode(user.toJson());
      await box.put('current', jsonData);
      print('  User saved: ${user.name} (ID: ${user.id})');
    } catch (e) {
      print('  Error saving user: $e');
      rethrow;
    }
  }

  static Future<UserModel?> getUser() async {
    try {
      final box = await _getBox('user');
      final jsonStr = box.get('current');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final data = json.decode(jsonStr);
          return UserModel.fromJson(data);
        } catch (e) {
          print('  Error parsing user data: $e');
          // Clear corrupted data
          await box.delete('current');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('  Error getting user: $e');
      return null;
    }
  }

  // ============ TASK OPERATIONS ============
  static Future<void> saveTasks(List<TaskModel> tasks) async {
    try {
      final box = await _getBox('tasks');
      final jsonList = tasks
          .map((task) {
            try {
              return task.toJson();
            } catch (e) {
              print('  Error converting task to JSON: $e');
              return null;
            }
          })
          .where((json) => json != null)
          .toList();

      await box.put('all', json.encode(jsonList));
      print('  ${jsonList.length} tasks saved to Hive');
    } catch (e) {
      print('  Error saving tasks: $e');
      rethrow;
    }
  }

  static Future<List<TaskModel>> getTasks() async {
    try {
      final box = await _getBox('tasks');
      final jsonStr = box.get('all');

      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final List<dynamic> jsonList = json.decode(jsonStr);
          final tasks = <TaskModel>[];

          for (var json in jsonList) {
            try {
              if (json is Map<String, dynamic>) {
                tasks.add(TaskModel.fromJson(json));
              }
            } catch (e) {
              print('  Error parsing individual task: $e');
              print('   Task data: $json');
            }
          }

          print(' Loaded ${tasks.length} tasks from Hive');
          return tasks;
        } catch (e) {
          print('  Error decoding tasks JSON: $e');
          // Clear corrupted data
          await box.delete('all');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('  Error getting tasks: $e');
      return [];
    }
  }

  static Future<void> addTask(TaskModel task) async {
    try {
      final tasks = await getTasks();
      tasks.add(task);
      await saveTasks(tasks);
      print('  Task added to Hive: ${task.title} (Total: ${tasks.length})');
    } catch (e) {
      print('  Error adding task: $e');
      rethrow;
    }
  }

  static Future<void> updateTask(TaskModel task) async {
    try {
      final tasks = await getTasks();
      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        tasks[index] = task;
        await saveTasks(tasks);
        print('  Task updated in Hive: ${task.title}');
      }
    } catch (e) {
      print('  Error updating task: $e');
      rethrow;
    }
  }

  static Future<void> deleteTask(String taskId) async {
    try {
      final tasks = await getTasks();
      tasks.removeWhere((t) => t.id == taskId);
      await saveTasks(tasks);
      print('  Task deleted from Hive: $taskId');
    } catch (e) {
      print('  Error deleting task: $e');
      rethrow;
    }
  }

  // ============ DAILY LOG OPERATIONS ============
  static Future<void> saveLog(DailyLogModel log) async {
    try {
      final box = await _getBox('logs');
      final key = AppDateUtils.normalizeDate(log.date).toIso8601String();
      final jsonData = json.encode(log.toJson());
      await box.put(key, jsonData);
      print('  Log saved for ${key}');
    } catch (e) {
      print('  Error saving log: $e');
      rethrow;
    }
  }

  static Future<DailyLogModel?> getLog(DateTime date) async {
    try {
      final box = await _getBox('logs');
      final key = AppDateUtils.normalizeDate(date).toIso8601String();
      final jsonStr = box.get(key);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final data = json.decode(jsonStr);
          return DailyLogModel.fromJson(data);
        } catch (e) {
          print('  Error parsing log for $key: $e');
          // Clear corrupted data
          await box.delete(key);
          return null;
        }
      }
      return null;
    } catch (e) {
      print('  Error getting log: $e');
      return null;
    }
  }

  static Future<List<DailyLogModel>> getLogsInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final box = await _getBox('logs');
      final logs = <DailyLogModel>[];

      for (var key in box.keys) {
        final jsonStr = box.get(key);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            final data = json.decode(jsonStr);
            final logDate = DateTime.parse(data['date']);
            if (logDate.isAfter(start) && logDate.isBefore(end)) {
              logs.add(DailyLogModel.fromJson(data));
            }
          } catch (e) {
            print('  Error parsing log for key $key: $e');
            // Skip corrupted entry
          }
        }
      }

      print(
        '  Found ${logs.length} logs between ${start.toIso8601String()} and ${end.toIso8601String()}',
      );
      return logs;
    } catch (e) {
      print('  Error getting logs in range: $e');
      return [];
    }
  }

  static Future<DailyLogModel?> getTodayLog() async {
    try {
      final today = AppDateUtils.getStartOfDay(DateTime.now());
      return await getLog(today);
    } catch (e) {
      print('  Error getting today\'s log: $e');
      return null;
    }
  }

  // ============ RESET ALL DATA ============
  static Future<void> resetAllData() async {
    try {
      await Hive.deleteBoxFromDisk('user');
      await Hive.deleteBoxFromDisk('tasks');
      await Hive.deleteBoxFromDisk('logs');
      print('  All Hive data reset');
    } catch (e) {
      print('  Error resetting data: $e');
    }
  }
}
