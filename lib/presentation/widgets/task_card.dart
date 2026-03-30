import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final bool isCompleted;
  final ValueChanged<bool> onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = DateTime.parse(
      task['lockedUntil'],
    ).isAfter(DateTime.now());
    final daysLeft = DateTime.parse(
      task['lockedUntil'],
    ).difference(DateTime.now()).inDays;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => onToggle(!isCompleted),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isCompleted ? Colors.green.shade50 : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: isCompleted,
                      onChanged: (value) => onToggle(value ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      activeColor: theme.primaryColor,
                      side: BorderSide(
                        color: isCompleted
                            ? theme.primaryColor
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted ? Colors.grey : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(
                                task['category'],
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              task['category'],
                              style: TextStyle(
                                fontSize: 11,
                                color: _getCategoryColor(task['category']),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isLocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$daysLeft days left',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isLocked && isCompleted)
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              ],
            ),
          ),
        ),
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
        return Colors.grey;
    }
  }
}
