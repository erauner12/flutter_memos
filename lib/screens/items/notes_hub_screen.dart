import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotesHubScreen extends ConsumerWidget {
  const NotesHubScreen({super.key});

  void _navigateToAddServer(BuildContext context) {
    // Navigate to the main settings screen, assuming server management is there
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (context) => const SettingsScreen(isInitialSetup: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversState = ref.watch(multiServerConfigProvider);
    final servers = serversState.servers;
    final isLoading = serversState.servers.isEmpty && ref.watch(loadServerConfigProvider).isLoading; // Check if initial load is happening
    final theme = CupertinoTheme.of(context);

    final separator = Container(
      height: 1,
      color: CupertinoColors.separator.resolveFrom(context),
      margin: const EdgeInsets.only(left: 56), // Indent separator past icon
    );

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Select Notes Server'),
        // No back button needed on the hub screen
        automaticallyImplyLeading: false,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // --- Loading State ---
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              ),

            // --- Empty State ---
            if (!isLoading && servers.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.cloud_bolt,
                        size: 50,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Servers Configured',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          'Add a Memos or Blinko server in Settings to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CupertinoButton.filled(
                        onPressed: () => _navigateToAddServer(context),
                        child: const Text('Go to Settings'),
                      ),
                    ],
                  ),
                ),
              ),

            // --- Server List ---
            if (servers.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final server = servers[index];
                      final isLast = index == servers.length - 1;

                      Widget tile = CupertinoListTile(
                        backgroundColor: theme.barBackgroundColor,
                        leading: Icon(
                          server.serverType == ServerType.blinko
                              ? CupertinoIcons.bolt_fill
                              : CupertinoIcons.news_solid, // Or differentiate Memos/Blinko
                          color: theme.primaryColor,
                          size: 24,
                        ),
                        title: Text(
                          server.name ?? server.serverUrl,
                          style: theme.textTheme.textStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          server.serverUrl,
                          style: theme.textTheme.tabLabelTextStyle,
                           maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(CupertinoIcons.forward),
                        onTap: () {
                          // Navigate using the nested navigator for the tab
                          Navigator.of(context).pushNamed('/notes/${server.id}');
                        },
                        // Add long-press for actions if needed later
                        // onLongPress: () => _showServerActions(context, ref, server),
                      );

                      if (!isLast) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [tile, separator],
                        );
                      } else {
                        return tile; // No separator after the last item
                      }
                    },
                    childCount: servers.length,
                  ),
                ),
              ),

            // --- Add New Server Button ---
            SliverPadding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 20.0), // Add padding
              sliver: SliverToBoxAdapter(
                child: Container(
                  color: CupertinoTheme.of(context).barBackgroundColor,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    onPressed: () => _navigateToAddServer(context),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.add_circled,
                          color: CupertinoColors.systemGreen,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Add or Manage Servers',
                            style: CupertinoTheme.of(context).textTheme.textStyle,
                          ),
                        ),
                        const Icon(CupertinoIcons.gear_alt_fill, size: 20, color: CupertinoColors.secondaryLabel),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget similar to WorkbenchInstanceTile but simpler for servers
class CupertinoListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;

  const CupertinoListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DefaultTextStyle(
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle(
                      style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle,
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
