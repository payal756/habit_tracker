import 'package:mahadev/core/utils/date_utils.dart';
import 'package:mahadev/data/models/daily_log_model.dart';
import 'package:mahadev/core/services/hive_service.dart';
import 'package:mahadev/core/services/api_service.dart';

class AnalyticsRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      // Fetch from API
      final response = await _apiService.get('/analytics');
      print(' Analytics from API: $response');
      return response;
    } catch (e) {
      print(' API analytics failed, calculating locally: $e');
      // Calculate locally if API fails
      return await _calculateLocalAnalytics();
    }
  }

  Future<Map<String, dynamic>> _calculateLocalAnalytics() async {
    print(' Calculating local analytics...');

    final tasks = await HiveService.getTasks();
    final today = DateTime.now();
    final weekAgo = DateTime(today.year, today.month, today.day - 6);
    final logs = await HiveService.getLogsInRange(weekAgo, today);

    print('  Tasks count: ${tasks.length}, Logs count: ${logs.length}');

    final dailyCompletions = <Map<String, dynamic>>[];
    var totalCompleted = 0;
    var currentStreak = 0;
    var bestStreak = 0;

    for (var i = 0; i < 7; i++) {
      final date = DateTime(today.year, today.month, today.day - i);
      final log = logs.firstWhere(
        (l) => AppDateUtils.isSameDay(l.date, date),
        orElse: () => DailyLogModel(id: '', date: date, completions: {}),
      );

      var percentage = 0.0;
      var completedCount = 0;

      if (tasks.isNotEmpty) {
        completedCount = log.completedCount;
        percentage = (completedCount / tasks.length) * 100;
        totalCompleted += completedCount;

        if (percentage >= 80) {
          currentStreak++;
          bestStreak = bestStreak > currentStreak ? bestStreak : currentStreak;
        } else {
          currentStreak = 0;
        }
      }

      dailyCompletions.add({
        'date': date.toIso8601String().split('T')[0],
        'percentage': percentage.round(),
        'completed': completedCount,
        'total': tasks.length,
      });
    }

    final overallCompletion = tasks.isNotEmpty
        ? (totalCompleted / (tasks.length * 7)) * 100
        : 0;

    final consistencyScore = ((bestStreak * 15) + (overallCompletion * 0.5))
        .round();

    final result = {
      'dailyCompletions': dailyCompletions.reversed.toList(),
      'overallCompletion': overallCompletion.round(),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'consistencyScore': consistencyScore > 100 ? 100 : consistencyScore,
      'totalTasks': tasks.length,
    };

    print('  Local analytics result: $result');
    return result;
  }
}
