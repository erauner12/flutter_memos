import 'package:flutter/material.dart';

class MemoCard extends StatelessWidget {
  final String content;
  final bool pinned;
  final String? createdAt;
  final String? updatedAt;
  final bool showTimeStamps;
  final String? highlightTimestamp;
  final String? timestampType;
  final VoidCallback? onTap;

  const MemoCard({
    super.key,
    required this.content,
    this.pinned = false,
    this.createdAt,
    this.updatedAt,
    this.showTimeStamps = false,
    this.highlightTimestamp,
    this.timestampType,
    this.onTap,
  });

  // Helper method to format date strings for display
  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            12.0,
            12.0,
            36.0,
            12.0,
          ), // Extra padding on right for archive button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              if (pinned)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Pinned',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              if (highlightTimestamp != null)
                // Display the highlighted timestamp (based on sort mode)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        timestampType == 'Updated'
                            ? Icons.update
                            : Icons.calendar_today,
                        size: 12,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$timestampType: $highlightTimestamp',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Show detailed timestamps if needed
              if (showTimeStamps && (createdAt != null || updatedAt != null))
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (createdAt != null)
                        Text(
                          'Created: ${_formatDateTime(createdAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (updatedAt != null)
                        Text(
                          'Updated: ${_formatDateTime(updatedAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
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
}
