import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
// Keep specific framework imports needed
import 'package:flutter/services.dart'; // Add import for keyboard events
import 'package:flutter_memos/models/memo.dart';
// import 'package:flutter_memos/models/server_config.dart'; // Remove this import
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
import 'package:flutter_memos/providers/ui_providers.dart'
    as ui_providers; // Add import
// Import MemosBody
import 'package:flutter_memos/screens/memos/memos_body.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart'; // Add import
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemosScreen extends ConsumerStatefulWidget {
  const MemosScreen({super.key});

  @override
  ConsumerState<MemosScreen> createState() => _MemosScreenState();
}

class _MemosScreenState extends ConsumerState<MemosScreen>
    with KeyboardNavigationMixin<MemosScreen> {
  // ScrollController and RefreshIndicatorKey are now managed within MemosBody
  // final ScrollController _scrollController = ScrollController();
  // final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  //     GlobalKey<RefreshIndicatorState>();
  final FocusNode _focusNode =
      FocusNode(); // Keep FocusNode for the screen level

  @override
  void initState() {
    super.initState();
    // Scroll listener is now managed within MemosBody
    // _scrollController.addListener(_onScroll);
    // Request focus after the first frame to ensure the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if the widget is still mounted
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    // ScrollController is now managed within MemosBody
    // _scrollController.removeListener(_onScroll);
    // _scrollController.dispose();
    _focusNode.dispose(); // Dispose the focus node
    super.dispose(); // Must call super
  }

  // _onScroll is now handled within MemosBody

  // Build the CupertinoNavigationBar when in multi-select mode
  CupertinoNavigationBar _buildMultiSelectNavBar(int selectedCount) {
    return CupertinoNavigationBar(
      transitionBetweenRoutes: false, // Disable default hero animation
      // Use leading for the cancel button
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          if (kDebugMode) {
            print('[MemosScreen] Exit multi-select via Cancel button');
          }
          ref.read(ui_providers.toggleMemoMultiSelectModeProvider)();
        },
        child: const Icon(CupertinoIcons.clear),
      ),
      middle: Text('$selectedCount Selected'),
      // Use trailing for action buttons
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delete button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            minSize: 0,
            onPressed:
                selectedCount > 0
                    ? () {
                      // TODO: Implement multi-delete logic
                      // Show confirmation dialog first
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (context) => CupertinoAlertDialog(
                              title: Text('Delete $selectedCount Memos?'),
                              content: const Text(
                                'This action cannot be undone.',
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: const Text('Delete'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // TODO: Actual deletion logic here...
                                    if (kDebugMode) {
                                      print(
                                        '[MemosScreen] Multi-delete action triggered (not implemented)',
                                      );
                                    }
                                    // Optionally show a CupertinoDialog for feedback if needed
                                    // showCupertinoDialog(...);
                                  },
                                ),
                              ],
                            ),
                      );
                    }
                    : null,
            child: Icon(
              CupertinoIcons.delete,
              color:
                  selectedCount > 0
                      ? CupertinoColors.destructiveRed
                      : CupertinoColors.inactiveGray,
            ),
          ),
          // Archive button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            minSize: 0,
            onPressed:
                selectedCount > 0
                    ? () {
                      // TODO: Implement multi-archive logic
                      if (kDebugMode) {
                        print(
                          '[MemosScreen] Multi-archive action triggered (not implemented)',
                        );
                      }
                      // Optionally show a CupertinoDialog for feedback if needed
                      // showCupertinoDialog(...);
                    }
                    : null,
            child: Icon(
              CupertinoIcons.archivebox,
              color:
                  selectedCount > 0
                      ? CupertinoTheme.of(context).primaryColor
                      : CupertinoColors.inactiveGray,
            ),
          ),
        ],
      ),
    );
  }

  // _onRefresh is now handled within MemosBody

  // Add keyboard navigation methods
  void _selectNextMemo() {
    final memos = ref.read(filteredMemosProvider);
    if (kDebugMode) {
      print(
        '[MemosScreen _selectNextMemo] Called. Filtered memos count: ${memos.length}',
      );
    }

    if (memos.isEmpty) return;

    final currentId = ref.read(ui_providers.selectedMemoIdProvider);
    int currentIndex = -1;
    if (currentId != null) {
      currentIndex = memos.indexWhere((memo) => memo.id == currentId);
    }

    // Use the mixin's helper function
    final nextIndex = getNextIndex(currentIndex, memos.length);

    if (nextIndex != -1) {
      final nextMemoId = memos[nextIndex].id;
      ref.read(ui_providers.selectedMemoIdProvider.notifier).state = nextMemoId;
      if (kDebugMode) {
        print(
          '[MemosScreen _selectNextMemo] Updated selectedMemoIdProvider to: $nextMemoId',
        );
      }
    }
  }

  void _selectPreviousMemo() {
    final memos = ref.read(filteredMemosProvider);
    if (kDebugMode) {
      print(
        '[MemosScreen _selectPreviousMemo] Called. Filtered memos count: ${memos.length}',
      );
    }

    if (memos.isEmpty) return;

    final currentId = ref.read(ui_providers.selectedMemoIdProvider);
    int currentIndex = -1;
    if (currentId != null) {
      currentIndex = memos.indexWhere((memo) => memo.id == currentId);
    }

    // Use the mixin's helper function
    final prevIndex = getPreviousIndex(currentIndex, memos.length);

    if (prevIndex != -1) {
      final prevMemoId = memos[prevIndex].id;
      ref.read(ui_providers.selectedMemoIdProvider.notifier).state = prevMemoId;
      if (kDebugMode) {
        print(
          '[MemosScreen _selectPreviousMemo] Updated selectedMemoIdProvider to: $prevMemoId',
        );
      }
    }
  }

  void _viewSelectedMemo() {
    final selectedId = ref.read(ui_providers.selectedMemoIdProvider);
    if (selectedId != null) {
      if (kDebugMode) {
        print('[MemosScreen] Viewing selected memo: ID $selectedId');
      }
      // Ensure context is valid before navigating
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed(
          '/memo-detail',
          arguments: {'memoId': selectedId},
        );
      }
    }
  }

  void _clearSelectionOrUnfocus() {
    final selectedId = ref.read(ui_providers.selectedMemoIdProvider);
    if (selectedId != null) {
      if (kDebugMode) {
        print('[MemosScreen] Clearing selection via Escape');
      }
      ref.read(ui_providers.selectedMemoIdProvider.notifier).state = null;
    } else {
      // If nothing is selected, unfocus any text fields etc.
      FocusScope.of(context).unfocus();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Only handle key down events
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (kDebugMode) {
      print(
        '[MemosScreen _handleKeyEvent] Received key: ${event.logicalKey.keyLabel}',
      );
      print(
        '[MemosScreen _handleKeyEvent] FocusNode has focus: ${node.hasFocus}',
      );
    }

    // Use the mixin's handler
    final result = handleKeyEvent(
      event,
      ref,
      onUp: _selectPreviousMemo,
      onDown: _selectNextMemo,
      onSubmit: _viewSelectedMemo,
      onEscape: _clearSelectionOrUnfocus,
    );

    if (kDebugMode) {
      print(
        '[MemosScreen _handleKeyEvent] Mixin handleKeyEvent result: $result',
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the memos notifier state
    final memosState = ref.watch(memosNotifierProvider);

    // Watch visible memos list (filtered by hiddenMemoIds)
    final visibleMemos = ref.watch(visibleMemosListProvider);

    // Watch current filter
    final currentFilter = ref.watch(filterKeyProvider);

    // Watch multi-select mode and selected IDs
    final isMultiSelectMode = ref.watch(
      ui_providers.memoMultiSelectModeProvider,
    );
    final selectedIds = ref.watch(
      ui_providers.selectedMemoIdsForMultiSelectProvider,
    );

    // Use CupertinoPageScaffold
    return CupertinoPageScaffold(
      // Use CupertinoNavigationBar
      navigationBar:
          isMultiSelectMode
              ? _buildMultiSelectNavBar(
                selectedIds.length,
              ) // Use the new Cupertino Nav Bar
              : CupertinoNavigationBar(
              transitionBetweenRoutes:
                  false, // Disable default hero animation
              // Add Server Switcher to leading
              leading: _buildServerSwitcherButton(),
              // Adjust middle text if needed, or keep as is
              middle: Text('Memos (${currentFilter.toUpperCase()})'),
              // Combine actions into the trailing widget
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Multi-select button
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    minSize: 0,
                    onPressed:
                        () =>
                            ref.read(
                              ui_providers.toggleMemoMultiSelectModeProvider,
                            )(),
                    child: const Icon(
                      CupertinoIcons.checkmark_seal,
                    ), // Example icon
                  ),
                  // Advanced filter button
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    minSize: 0,
                    onPressed: () => _showAdvancedFilterPanel(context),
                    child: const Icon(CupertinoIcons.tuningfork),
                  ),
                  // Filter dropdown (Keep Material for now, replace later)
                  _buildFilterButton(),
                  // Create new memo button
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    minSize: 0,
                    onPressed: () {
                      // Use the root navigator to push the route
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed('/new-memo').then((_) {
                        // Refresh after returning from new memo screen
                        // No longer needed here, MemosNotifier should refresh automatically
                        // ref.read(memosNotifierProvider.notifier).refresh();
                      });
                    },
                    child: const Icon(CupertinoIcons.add),
                  ),
                ],
              ),
              // Search bar needs a different approach in Cupertino.
              // Option 1: Place it below the Nav Bar using a Column in the body.
              // Option 2: Use CupertinoSearchTextField (requires more integration).
              // Let's go with Option 1 for now.
              ), // Added comma here
      child: SafeArea(
        // Add SafeArea
        child: Focus(
          // Wrap the body content
          focusNode: _focusNode,
          autofocus: true, // Try to grab focus automatically
          onKeyEvent: _handleKeyEvent, // Use the handler
          // Add Column to place SearchBar above the list
          child: Column(
            children: [
              // Add Search Bar here if not in multi-select mode
              if (!isMultiSelectMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: _buildSearchBar(), // Build the search bar widget
                ),

              // Main list of memos
              Expanded(child: _buildMemosList(memosState, visibleMemos)),
            ],
          ),
        ),
      ),
      // Remove FloatingActionButtons - actions moved to NavBar
    );
  }

  void _showAdvancedFilterPanel(BuildContext context) {
    // Show the advanced filter panel using showCupertinoModalPopup
    // Note: DraggableScrollableSheet behavior needs custom implementation if required.
    // This example shows a fixed-height modal popup.
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        // You might need to adjust the height or make it scrollable
        // depending on the content of the filter panel.
        return SizedBox(
          // Example: Set height to 80% of screen height
          height: MediaQuery.of(context).size.height * 0.8,
          child: _buildAdvancedFilterPanel(
            ScrollController(),
          ), // Pass a new ScrollController
        );
      },
    );
  }

  // Define the AdvancedFilterPanel
  Widget _buildAdvancedFilterPanel(ScrollController scrollController) {
    // Use CupertinoTheme for background color
    final theme = CupertinoTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Use Cupertino theme color
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              // Use withAlpha instead of deprecated withOpacity
              color: CupertinoColors.systemGrey.withAlpha(
                77,
              ), // Approx 0.3 opacity
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Advanced Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Replace IconButton with CupertinoButton
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.clear_thick),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Filter content - to be implemented
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16.0),
              children: const [
                Text('Filter options will be implemented here'),
                // TODO: Implement actual filter options
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to show the filter selection action sheet
  void _showFilterActionSheet(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.read(filterKeyProvider);
    final availableFilters = {
      'all': 'All Memos',
      'inbox': 'Inbox',
      'archive': 'Archive',
      // Add more filters here if needed
    };

    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Select Filter'),
            actions:
                availableFilters.entries.map((entry) {
                  return CupertinoActionSheetAction(
                    isDefaultAction: entry.key == currentFilter,
                    onPressed: () {
                      ref.read(filterKeyProvider.notifier).state = entry.key;
                      Navigator.pop(context); // Close the action sheet
                    },
                    child: Text(entry.value),
                  );
                }).toList(),
            cancelButton: CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Updated to use CupertinoButton and trigger the action sheet
  Widget _buildFilterButton() {
    final currentFilter = ref.watch(filterKeyProvider);
    final filterLabel =
        {'all': 'All', 'inbox': 'Inbox', 'archive': 'Archive'}[currentFilter] ??
        currentFilter; // Fallback to key if label not found

    // Use a CupertinoButton to trigger the action sheet
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      minSize: 0,
      onPressed: () => _showFilterActionSheet(context, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Use Text instead of Chip for a more Cupertino feel
          Text(
            filterLabel,
            style: TextStyle(
              color: CupertinoTheme.of(context).primaryColor,
              fontSize: 14, // Adjust size as needed
            ),
          ),
          const SizedBox(width: 4),
          // Correct Icon constructor: size and color are named parameters
          Icon(
            CupertinoIcons.chevron_down, // Use Cupertino icon
            size: 16, // Pass size as named argument
            color:
                CupertinoTheme.of(
                  context,
                ).primaryColor, // Pass color as named argument
          ),
        ],
      ),
    );
  }

  // Method to build the server switcher button
  Widget _buildServerSwitcherButton() {
    final activeServer = ref.watch(activeServerConfigProvider);
    final serverName = activeServer?.name ?? activeServer?.serverUrl ?? 'No Server';
    final truncatedName = serverName.length > 15 ? '${serverName.substring(0, 12)}...' : serverName;

    return CupertinoButton(
      padding: const EdgeInsets.only(left: 8.0), // Adjust padding as needed
      onPressed: () => _showServerSelectionSheet(context, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.square_stack_3d_down_right, size: 20), // Example icon
          const SizedBox(width: 4),
          Text(
            truncatedName,
            style: const TextStyle(fontSize: 14), // Adjust style as needed
            overflow: TextOverflow.ellipsis,
          ),
          const Icon(CupertinoIcons.chevron_down, size: 14),
        ],
      ),
    );
  }

  // Method to show the server selection action sheet
  void _showServerSelectionSheet(BuildContext context, WidgetRef ref) {
    final multiServerState = ref.read(multiServerConfigProvider);
    final servers = multiServerState.servers;
    final activeServerId = multiServerState.activeServerId;
    final notifier = ref.read(multiServerConfigProvider.notifier);

    if (servers.isEmpty) {
      // Optionally show a message or navigate to settings
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('No Servers'),
          content: const Text('Please add a server configuration in Settings.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Settings'),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.of(context, rootNavigator: true).pushNamed('/settings');
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Switch Active Server'),
        actions: servers.map((server) {
          final bool isActive = server.id == activeServerId;
          return CupertinoActionSheetAction(
            isDefaultAction: isActive, // Highlight the active server
            onPressed: () {
              if (!isActive) {
                if (kDebugMode) {
                  print('[MemosScreen] Setting active server to: ${server.name ?? server.id}');
                }
                notifier.setActiveServer(server.id);
                // MemosNotifier should auto-refresh due to dependency on apiServiceProvider
              }
              Navigator.pop(context); // Close the action sheet
            },
            child: Text(server.name ?? server.serverUrl),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // Build the search bar widget
  Widget _buildSearchBar() {
    final searchQuery = ref.watch(searchQueryProvider);
    final TextEditingController controller = TextEditingController(
      text: searchQuery,
    );
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    ); // Place cursor at the end

    // Use CupertinoSearchTextField for a native look
    return CupertinoSearchTextField(
      controller: controller,
      placeholder: 'Search memos...',
      // Style based on theme
      style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
      decoration: BoxDecoration(
        color: CupertinoColors.systemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(10.0),
      ),
      // prefixIcon and suffixIcon are built-in
      onChanged: (value) {
        // Update the search query provider as user types
        ref.read(searchQueryProvider.notifier).state = value;

        // If value is non-empty and we have local search disabled, we might want
        // to trigger a server search after debouncing
        final isLocalSearch = ref.read(localSearchEnabledProvider);
        if (!isLocalSearch && value.isNotEmpty) {
          // In a real app, you'd add debouncing logic here
          // For now, we'll refresh immediately when local search is disabled
          ref.read(memosNotifierProvider.notifier).refresh();
        }
      },
    );
  }

  // Simplified _buildMemosList to delegate to MemosBody
  Widget _buildMemosList(MemosState memosState, List<Memo> visibleMemos) {
    // The logic for displaying loading, error, empty, and data states,
    // including the ListView.builder and RefreshIndicator,
    // is now handled within the MemosBody widget.
    return const MemosBody();
  }
}
