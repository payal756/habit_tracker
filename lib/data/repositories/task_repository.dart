import 'package:mahadev/domain/repositories/task_repository_interface.dart';
import 'package:mahadev/data/models/task_model.dart';
import 'package:mahadev/core/services/hive_service.dart';
import 'package:mahadev/core/services/api_service.dart';

class TaskRepository implements ITaskRepository {
  final ApiService _apiService = ApiService();

  @override
  Future<List<TaskModel>> getTasks({bool forceRefresh = false}) async {
    try {
      // 1. First load from Hive (instant UI)
      final localTasks = await HiveService.getTasks();

      // 2. Fetch from API in background
      if (!forceRefresh) {
        _syncTasksInBackground();
      } else {
        await _syncTasksInBackground();
      }

      return localTasks;
    } catch (e) {
      print('  Error getting tasks: $e');
      // Fallback to local if API fails
      return await HiveService.getTasks();
    }
  }

  @override
  Future<TaskModel> addTask(String title, String category) async {
    try {
      print('  Adding task: $title ($category)');
      final response = await _apiService.post('/tasks', {
        'title': title,
        'category': category,
      });

      print('  Task added successfully: $response');

      // The response should be a Map containing the task data
      final task = TaskModel.fromJson(response);
      await HiveService.addTask(task);
      return task;
    } catch (e) {
      print('  Error adding task: $e');
      rethrow;
    }
  }

  @override
  Future<void> syncTasks() async {
    await _syncTasksInBackground();
  }

  Future<void> _syncTasksInBackground() async {
    try {
      print('  Syncing tasks from API...');
      final response = await _apiService.get('/tasks');

      print('  API Response: $response');

      // The response is always a Map, tasks might be in 'data' key
      List<dynamic> tasksList = [];

      // Check if response has a 'data' key (from our wrapper)
      if (response.containsKey('data') && response['data'] is List) {
        tasksList = response['data'];
      }
      // Check if response itself is a List (wrapped in map)
      else if (response.values.any((v) => v is List)) {
        final listValue = response.values.firstWhere(
          (v) => v is List,
          orElse: () => null,
        );
        if (listValue != null) {
          tasksList = listValue as List;
        }
      }
      // Check if response has a '_id' or 'id' (single task)
      else if (response.containsKey('_id') || response.containsKey('id')) {
        tasksList = [response];
      }

      if (tasksList.isNotEmpty) {
        final tasks = tasksList
            .map((t) {
              try {
                return TaskModel.fromJson(t as Map<String, dynamic>);
              } catch (e) {
                print('  Error parsing task: $e');
                return null;
              }
            })
            .where((t) => t != null)
            .cast<TaskModel>()
            .toList();

        if (tasks.isNotEmpty) {
          await HiveService.saveTasks(tasks);
          print('  Synced ${tasks.length} tasks from API');
        } else {
          print('  No valid tasks found in response');
        }
      } else {
        print('  No tasks found from API');
      }
    } catch (e) {
      print('  Background sync failed: $e');
    }
  }
}
