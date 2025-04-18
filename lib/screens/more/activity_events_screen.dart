import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/services/todoist_api_service.dart'; // Import the service
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting

// Provider to fetch activity events using the service method
final activityEventsProvider = FutureProvider<List<todoist.ActivityEvents>>((ref) async {
  // Access the singleton instance of the service
  final service = TodoistApiService();
  // Check if configured before fetching
  if (!service.isConfigured) {
    // Return empty list or throw an error if not configured
    print("Todoist API not configured. Cannot fetch activity events.");
    return [];
  }
  // Call the method that uses performSync with ['activity']
  return service.getActivityEventsFromSync();
});

/// A screen to display activity events fetched from the Todoist Sync API.
class ActivityEventsScreen extends ConsumerWidget {
  const ActivityEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(activityEventsProvider);
    final DateFormat dateFormat = DateFormat.yMd().add_jms(); // Example format

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Activity Log'), // Changed title slightly
        previousPageTitle: 'More', // Add back button title
      ),
      child: SafeArea( // Ensure content is below status bar/notch
        child: eventsAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, stack) {
            print("Error loading activity events: $err\n$stack"); // Log error
            return Center(child: Text('Error loading events: $err'));
          },
          data: (events) {
            if (events.isEmpty) {
              // Check if the service was configured before showing "No events"
              final service = TodoistApiService();
              if (!service.isConfigured) {
                return const Center(child: Text('Todoist API not configured.'));
              }
              return const Center(child: Text('No activity events found.'));
            }
            // Sort events by date descending (most recent first)
            events.sort((a, b) => b.eventDate.compareTo(a.eventDate));

            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final e = events[index];
                // Build a more informative subtitle
                String subtitle = 'Type: ${e.objectType}, ID: ${e.objectId}';
                if (e.parentProjectId != null) {
                  subtitle += '\nProject ID: ${e.parentProjectId}';
                }
                if (e.parentItemId != null) {
                  subtitle += '\nParent Item ID: ${e.parentItemId}';
                }
                if (e.initiatorId != null) {
                  subtitle += '\nInitiator ID: ${e.initiatorId}';
                }
                // Add extra data if present and not empty
                if (e.extraData != null && e.extraData!.isNotEmpty) {
                  subtitle += '\nExtra: ${e.extraData.toString()}';
                }

                return CupertinoListTile(
                  title: Text('${e.eventType} - ${dateFormat.format(e.eventDate.toLocal())}'),
                  subtitle: Text(subtitle),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Reusable CupertinoListTile (copied from plan for completeness)
class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  const CupertinoListTile({required this.title, this.subtitle, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 4.0), // Adjusted padding
          child: DefaultTextStyle(
            style: CupertinoTheme.of(context).textTheme.textStyle,
            child: title,
          ),
        ),
        if (subtitle != null) Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0), // Adjusted padding
          child: DefaultTextStyle(
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            child: subtitle!,
          ),
        ),
        Container(
          height: 1,
          color: CupertinoColors.separator.resolveFrom(context),
          margin: const EdgeInsets.only(left: 16.0), // Indent separator
        ),
      ],
    );
  }
}
