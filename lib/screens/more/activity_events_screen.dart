import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/services/todoist_api_service.dart'; // Import the service AND the providers
import 'package:flutter_memos/todoist_api/lib/api.dart' as todoist;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting

// Provider to fetch activity events using the service method
// Watches the configuration status provider.
final activityEventsProvider = FutureProvider<List<todoist.ActivityEvents>>((ref) async {
  // Watch the configuration status
  final isConfigured = ref.watch(isTodoistConfiguredProvider);

  // Only fetch if configured
  if (!isConfigured) {
    print(
      "[ActivityEventsProvider] Service not configured. Returning empty list.",
    );
    return [];
  }

  // If configured, get the service instance (can use read now) and fetch
  print("[ActivityEventsProvider] Service is configured. Fetching events...");
  final service = ref.read(todoistApiServiceProvider);
  try {
    return await service.getActivityEventsFromSync();
  } catch (e) {
    print("[ActivityEventsProvider] Error fetching events: $e");
    // Propagate error to be handled by the UI's .when()
    rethrow;
  }
});

/// A screen to display activity events fetched from the Todoist Sync API.
class ActivityEventsScreen extends ConsumerWidget {
  const ActivityEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider that fetches events
    final eventsAsync = ref.watch(activityEventsProvider);
    // Watch the config status directly for UI messages if needed (optional)
    final isConfigured = ref.watch(isTodoistConfiguredProvider);
    final DateFormat dateFormat = DateFormat.yMd().add_jms(); // Example format

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Activity Log'), // Changed title slightly
        previousPageTitle: 'More', // Add back button title
      ),
      child: SafeArea( // Ensure content is below status bar/notch
        child: eventsAsync.when(
          // Show loading indicator regardless of config status initially
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, stack) {
            // Error state already logged by the provider
            return Center(child: Text('Error loading events: $err'));
          },
          data: (events) {
            // Now check configuration status for the data state
            if (!isConfigured) {
              // This case should ideally not be reached if the provider logic is correct,
              // but handle defensively.
              return const Center(child: Text('Todoist API not configured.'));
            }
            if (events.isEmpty) {
              // If configured but no events were returned
              return const Center(child: Text('No activity events found.'));
            }
            // Sort events by date descending (most recent first)
            // Create a mutable copy before sorting
            final sortedEvents = List<todoist.ActivityEvents>.from(events);
            sortedEvents.sort((a, b) => b.eventDate.compareTo(a.eventDate));

            return ListView.builder(
              itemCount: sortedEvents.length,
              itemBuilder: (context, index) {
                final e = sortedEvents[index];
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
                  // Limit length of extra data string for display
                  String extraDataStr = e.extraData.toString();
                  if (extraDataStr.length > 100) {
                    extraDataStr = '${extraDataStr.substring(0, 100)}...';
                  }
                  subtitle += '\nExtra: $extraDataStr';
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
