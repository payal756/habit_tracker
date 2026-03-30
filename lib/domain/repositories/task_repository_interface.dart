import 'package:mahadev/data/models/task_model.dart';

abstract class ITaskRepository {
  Future<List<TaskModel>> getTasks({bool forceRefresh = false});
  Future<TaskModel> addTask(String title, String category);
  Future<void> syncTasks();
}
