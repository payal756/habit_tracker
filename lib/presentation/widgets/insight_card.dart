import 'package:flutter/material.dart';

class InsightCard extends StatelessWidget {
  final String message;
  final String type; // 'positive', 'suggestion', 'tip'
  final VoidCallback? onTap;

  const InsightCard({
    super.key,
    required this.message,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, title) = _getTypeData();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, String) _getTypeData() {
    switch (type) {
      case 'positive':
        return (Icons.emoji_events, Colors.amber, '🎉 Achievement');
      case 'suggestion':
        return (Icons.lightbulb, Colors.purple, '💡 Suggestion');
      case 'tip':
        return (Icons.tips_and_updates, Colors.blue, '✨ Tip');
      default:
        return (Icons.info, Colors.grey, '  Insight');
    }
  }
}
