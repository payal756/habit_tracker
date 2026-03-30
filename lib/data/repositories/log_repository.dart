import 'package:mahadev/data/models/daily_log_model.dart';
import 'package:mahadev/core/services/hive_service.dart';
import 'package:mahadev/core/services/api_service.dart';
import 'package:mahadev/core/utils/date_utils.dart';

class LogRepository {
  final ApiService _apiService = ApiService();

  Future<DailyLogModel> getTodayLog() async {
    final today = AppDateUtils.getStartOfDay(DateTime.now());

    // 1. Try local first
    final localLog = await HiveService.getLog(today);
    if (localLog != null) {
      // Sync in background
      _syncTodayLogInBackground();
      return localLog;
    }

    // 2. Fetch from API
    try {
      final response = await _apiService.get('/logs/today');
      final log = DailyLogModel.fromJson(response);
      await HiveService.saveLog(log);
      return log;
    } catch (e) {
      // 3. Create empty log if none exists
      final tasks = await HiveService.getTasks();
      final completions = {for (var t in tasks) t.id: false};

      return DailyLogModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: today,
        completions: completions,
      );
    }
  }

  Future<void> updateLog(DailyLogModel log) async {
    try {
      await HiveService.saveLog(log);
      await _apiService.put('/logs/today', {
        'completions': log.completions.entries
            .map((e) => {'taskId': e.key, 'completed': e.value})
            .toList(),
      });
    } catch (e) {
      // Save locally if API fails
      await HiveService.saveLog(log);
      rethrow;
    }
  }

  Future<void> _syncTodayLogInBackground() async {
    try {
      final response = await _apiService.get('/logs/today');
      final log = DailyLogModel.fromJson(response);
      await HiveService.saveLog(log);
    } catch (e) {
      print('Background log sync failed: $e');
    }
  }
}
