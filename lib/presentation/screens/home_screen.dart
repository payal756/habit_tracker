import 'package:flutter/material.dart';
import 'package:mahadev/core/services/api_service.dart';
import 'package:mahadev/core/services/hive_service.dart';
import 'package:mahadev/data/models/user_model.dart';
import 'package:mahadev/data/models/task_model.dart';
import 'package:mahadev/data/models/daily_log_model.dart';
import 'package:mahadev/presentation/widgets/task_card.dart';
import 'package:mahadev/presentation/screens/profile_screen.dart';
import 'package:mahadev/core/utils/date_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<TaskModel> _tasks = [];
  Map<String, dynamic> _analytics = {};
  UserModel? _userData;
  DailyLogModel? _todayLog;
  List<Map<String, dynamic>> _insights = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Load user data
      _userData = await HiveService.getUser();
      debugPrint('👤 Current user: ${_userData?.email} (ID: ${_userData?.id})');

      // Load tasks
      _tasks = await HiveService.getTasks();
      debugPrint('  Loaded ${_tasks.length} tasks from Hive');

      // Get today's log (this will automatically create a new one if it's a new day)
      _todayLog = await _getOrCreateTodayLog();
      debugPrint(' Today\'s log date: ${_todayLog?.date}');
      debugPrint(
        '  Completed tasks: ${_todayLog?.completedCount}/${_tasks.length}',
      );

      // Sync with API in background
      await _syncTasksFromApi();

      // Load analytics
      try {
        _analytics = await _apiService.get('/analytics');
      } catch (e) {
        _analytics = {};
      }

      // Load insights
      _insights = await _getInsights();
    } catch (e) {
      debugPrint('  Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncTasksFromApi() async {
    try {
      debugPrint('  Syncing tasks from API...');
      final response = await _apiService.get('/tasks');

      List<dynamic> tasksList = [];

      // Handle different response formats
      if (response.containsKey('data') && response['data'] is List) {
        tasksList = response['data'];
      } else if (response.containsKey('tasks') && response['tasks'] is List) {
        tasksList = response['tasks'];
      } else if (response.values.any((v) => v is List)) {
        final listValue = response.values.firstWhere(
          (v) => v is List,
          orElse: () => null,
        );
        if (listValue != null) tasksList = listValue as List;
      } else if (response.containsKey('_id') || response.containsKey('id')) {
        tasksList = [response];
      }

      if (tasksList.isNotEmpty) {
        final tasks = tasksList
            .map((t) {
              try {
                return TaskModel.fromJson(t as Map<String, dynamic>);
              } catch (e) {
                debugPrint('  Error parsing task: $e');
                return null;
              }
            })
            .where((t) => t != null)
            .cast<TaskModel>()
            .toList();

        if (tasks.isNotEmpty) {
          await HiveService.saveTasks(tasks);
          setState(() {
            _tasks = tasks;
          });
          debugPrint('  Synced ${tasks.length} tasks from API');
        }
      } else {
        debugPrint(' No tasks found from API');
      }
    } catch (e) {
      debugPrint('  Background sync failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getInsights() async {
    try {
      final response = await _apiService.get('/ai-insights');
      return response['insights'] ?? [];
    } catch (e) {
      return [
        {
          'type': 'tip',
          'message': 'Complete tasks daily to build strong habits!',
        },
        {'type': 'suggestion', 'message': 'Start with small, achievable goals'},
      ];
    }
  }

  Future<void> _logout() async {
    await HiveService.clearAll();
    await _apiService.clearToken();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    String selectedCategory = 'Health';
    final categories = [
      'Health',
      'Fitness',
      'Productivity',
      'Learning',
      'Personal',
      'Work',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: MediaQuery.of(context).size.width * 0.06,
              right: MediaQuery.of(context).size.width * 0.06,
              top: 24,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create New Task',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What habit do you want to build?',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'e.g., Morning Meditation',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: categories.map((category) {
                      final Color categoryColor = _getCategoryColor(category);
                      return ChoiceChip(
                        label: Text(category),
                        selected: selectedCategory == category,
                        onSelected: (selected) {
                          if (selected)
                            setModalState(() => selectedCategory = category);
                        },
                        selectedColor: categoryColor,
                        backgroundColor: categoryColor.withOpacity(0.1),
                        labelStyle: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          color: selectedCategory == category
                              ? Colors.white
                              : categoryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: selectedCategory == category
                              ? Colors.transparent
                              : categoryColor.withOpacity(0.3),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          // In _showAddTaskSheet, when adding a task:
                          onPressed: () async {
                            if (titleController.text.isNotEmpty) {
                              Navigator.pop(context);

                              try {
                                // Add task to API
                                final response = await _apiService
                                    .post('/tasks', {
                                      'title': titleController.text,
                                      'category': selectedCategory,
                                    });

                                // Create task model
                                final newTask = TaskModel.fromJson(response);

                                // Add to local tasks list
                                _tasks.add(newTask);
                                await HiveService.addTask(newTask);

                                // Update today's log to include the new task
                                if (_todayLog != null) {
                                  final updatedCompletions =
                                      Map<String, bool>.from(
                                        _todayLog!.completions,
                                      );
                                  updatedCompletions[newTask.id] = false;

                                  final updatedLog = DailyLogModel(
                                    id: _todayLog!.id,
                                    date: _todayLog!.date,
                                    completions: updatedCompletions,
                                  );

                                  await HiveService.saveLog(updatedLog);
                                  setState(() {
                                    _todayLog = updatedLog;
                                  });

                                  // Sync with API
                                  final completionsList = updatedCompletions
                                      .entries
                                      .map(
                                        (entry) => ({
                                          'taskId': entry.key,
                                          'completed': entry.value,
                                        }),
                                      )
                                      .toList();
                                  await _apiService.put('/logs/today', {
                                    'completions': completionsList,
                                  });
                                }

                                // Refresh data
                                await _loadData();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Task "${titleController.text}" added successfully!',
                                      ),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error: ${e.toString().replaceAll('Exception: ', '')}',
                                      ),
                                      backgroundColor: Colors.red.shade600,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Add Task',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Health':
        return const Color(0xFFEF4444);
      case 'Fitness':
        return const Color(0xFFF59E0B);
      case 'Productivity':
        return const Color(0xFF3B82F6);
      case 'Learning':
        return const Color(0xFF8B5CF6);
      case 'Personal':
        return const Color(0xFF10B981);
      case 'Work':
        return const Color(0xFF06B6D4);
      default:
        return Theme.of(context).primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = _userData?.name.split(' ').first ?? 'User';
    final completionRate = _analytics['overallCompletion'] ?? 0;
    final streak = _analytics['currentStreak'] ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          // Tasks Tab
          _buildTasksTabContent(userName, completionRate, streak),

          // Analytics Tab
          _buildAnalyticsTabContent(),

          // Profile Tab
          ProfileScreen(
            userData: _userData,
            onRefresh: _loadData,
            onLogout: () {
              _logout();
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddTaskSheet,
              backgroundColor: theme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTasksTabContent(
    String userName,
    int completionRate,
    int streak,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.05,
                screenHeight * 0.05,
                screenWidth * 0.05,
                screenHeight * 0.03,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $userName 👋',
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ready for today?',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.biotech,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_userData?.coins ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$completionRate%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Today\'s Progress',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: completionRate / 100,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$streak',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Day Streak',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Tasks List
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final isCompleted =
                          _todayLog?.completions[task.id] ?? false;

                      debugPrint(
                        '📝 Task: ${task.title}, Completed: $isCompleted',
                      );

                      return Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.03),
                        child: TaskCard(
                          task: {
                            '_id': task.id,
                            'title': task.title,
                            'category': task.category,
                            'lockedUntil': task.lockedUntil.toIso8601String(),
                          },
                          isCompleted: isCompleted,
                          onToggle: (completed) async {
                            debugPrint(
                              '  Toggling task: ${task.title} to $completed',
                            );
                            await _toggleTaskCompletion(task, completed);
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTaskCompletion(TaskModel task, bool completed) async {
    try {
      debugPrint('  Toggling task: ${task.title} to $completed');

      //final today = DateUtils.getStartOfDay(DateTime.now());

      // Get today's log (create if doesn't exist)
      DailyLogModel currentLog = await _getOrCreateTodayLog();

      // Update completion status
      final updatedCompletions = Map<String, bool>.from(currentLog.completions);
      updatedCompletions[task.id] = completed;

      final updatedLog = DailyLogModel(
        id: currentLog.id,
        date: currentLog.date,
        completions: updatedCompletions,
      );

      // Save to Hive locally
      await HiveService.saveLog(updatedLog);

      // Update local state
      setState(() {
        _todayLog = updatedLog;
      });

      // Sync with API
      final completionsList = updatedCompletions.entries
          .map((entry) => ({'taskId': entry.key, 'completed': entry.value}))
          .toList();

      await _apiService.put('/logs/today', {'completions': completionsList});

      debugPrint('  Log synced with API');

      // Refresh analytics after completion
      try {
        _analytics = await _apiService.get('/analytics');
        setState(() {});
      } catch (e) {
        debugPrint('Error refreshing analytics: $e');
      }

      // Show feedback
      if (mounted) {
        final completedCount = updatedCompletions.values.where((v) => v).length;
        final totalTasks = updatedCompletions.length;
        final completionPercentage = totalTasks > 0
            ? (completedCount / totalTasks) * 100
            : 0;

        String message;
        Color snackbarColor;

        if (completed) {
          if (completionPercentage == 100) {
            message = '🎉 Perfect! All tasks completed! +10 coins';
            snackbarColor = Colors.amber;
          } else if (completionPercentage >= 80) {
            message = '🌟 Great progress! +5 coins';
            snackbarColor = Colors.green;
          } else {
            message = '  Task completed! Keep going!';
            snackbarColor = Colors.green;
          }
        } else {
          message = 'Task marked as incomplete';
          snackbarColor = Colors.orange;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(color: Colors.white)),
            backgroundColor: snackbarColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('  Error toggling task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<DailyLogModel> _getOrCreateTodayLog() async {
    final today = AppDateUtils.getStartOfDay(DateTime.now());

    // Check if we have today's log in memory
    if (_todayLog != null && DateUtils.isSameDay(_todayLog!.date, today)) {
      return _todayLog!;
    }

    // Check Hive for today's log
    final hiveLog = await HiveService.getLog(today);
    if (hiveLog != null) {
      return hiveLog;
    }

    // Create new log with all tasks set to incomplete
    final tasks = await HiveService.getTasks();
    final completions = <String, bool>{};
    for (var task in tasks) {
      completions[task.id] = false;
    }

    final newLog = DailyLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: today,
      completions: completions,
    );

    // Save to Hive
    await HiveService.saveLog(newLog);

    // Try to sync with API
    try {
      final completionsList = completions.entries
          .map((entry) => ({'taskId': entry.key, 'completed': entry.value}))
          .toList();
      await _apiService.put('/logs/today', {'completions': completionsList});
    } catch (e) {
      debugPrint('  Could not sync new log with API: $e');
    }

    return newLog;
  }

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: 40,
        ),
        child: Column(
          children: [
            Icon(
              Icons.task_outlined,
              size: screenWidth * 0.2,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: screenWidth * 0.04),
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              'Start your 21-day journey by adding a task',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth * 0.06),
            ElevatedButton.icon(
              onPressed: _showAddTaskSheet,
              icon: const Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: Text(
                'Add Your First Task',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTabContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final dailyCompletions = _analytics['dailyCompletions'] as List? ?? [];
    final overall = _analytics['overallCompletion'] ?? 0;
    final streak = _analytics['currentStreak'] ?? 0;
    final bestStreak = _analytics['bestStreak'] ?? 0;
    final consistency = _analytics['consistencyScore'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            SizedBox(height: 35),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Progress',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '$overall%',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.08,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.trending_up,
                                color: Colors.white.withOpacity(0.8),
                                size: 24,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$streak',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Day Streak',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: overall / 100,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: screenWidth * 0.03,
              crossAxisSpacing: screenWidth * 0.03,
              childAspectRatio: 1.3,
              children: [
                _buildModernStatCard(
                  title: 'Completion Rate',
                  value: '$overall%',
                  icon: Icons.trending_up,
                  color: Colors.blue,
                  subtitle: 'of tasks completed',
                ),
                _buildModernStatCard(
                  title: 'Current Streak',
                  value: '$streak days',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  subtitle: 'days in a row',
                ),
                _buildModernStatCard(
                  title: 'Best Streak',
                  value: '$bestStreak days',
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                  subtitle: 'record streak',
                ),
                _buildModernStatCard(
                  title: 'Consistency Score',
                  value: '$consistency',
                  icon: Icons.insights,
                  color: Colors.green,
                  subtitle: 'out of 100',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Weekly Progress Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Progress',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Last 7 days',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weekly Chart
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Bars
                  SizedBox(
                    height: 140, // Reduced from 160 to 140
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: dailyCompletions.map((day) {
                        final percentage = day['percentage'] ?? 0;
                        final date = DateTime.parse(day['date']);
                        final dayNames = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        final isToday = AppDateUtils.isToday(date);

                        // Calculate bar height (max 100px, min 4px)
                        final barHeight = (percentage / 100) * 100;

                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: barHeight.clamp(4.0, 100.0),
                                width: screenWidth * 0.06,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      isToday
                                          ? theme.primaryColor
                                          : theme.primaryColor.withOpacity(0.6),
                                      isToday
                                          ? theme.primaryColor
                                          : theme.primaryColor.withOpacity(0.4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(screenWidth * 0.02),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dayNames[date.weekday - 1],
                                style: TextStyle(
                                  fontSize: screenWidth * 0.028,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isToday
                                      ? theme.primaryColor
                                      : theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$percentage%',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.022,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 6),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // AI Insights Section
            if (_insights.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.pink.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Insights',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._insights.map(
                (insight) => Padding(
                  padding: EdgeInsets.only(bottom: screenWidth * 0.03),
                  child: _buildModernInsightCard(
                    message: insight['message'],
                    type: insight['type'],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method for modern stat cards
  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.025),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // Helper method for modern insight cards
  Widget _buildModernInsightCard({
    required String message,
    required String type,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String title;

    switch (type) {
      case 'positive':
        icon = Icons.emoji_events;
        color = Colors.amber;
        title = 'Achievement';
        break;
      case 'suggestion':
        icon = Icons.lightbulb;
        color = Colors.purple;
        title = 'Suggestion';
        break;
      case 'tip':
        icon = Icons.tips_and_updates;
        color = Colors.blue;
        title = 'Tip';
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
        title = 'Insight';
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.cardColor, color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
