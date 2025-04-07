import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
// Keep specific framework imports needed
import 'package:flutter/services.dart'; // Add import for keyboard events
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/server_config.dart'; // Import ServerConfig model
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
import 'package:flutter_memos/providers/ui_providers.dart'
    as ui_providers; // Add import
// Import MemosBody
import 'package:flutter_memos/screens/memos/memos_body.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart'; // Add import
import 'package:flutter_memos/widgets/advanced_filter_panel.dart'; // Add import for AdvancedFilterPanel
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemosScreen extends ConsumerStatefulWidget {
  const MemosScreen({super.key});

  @override
  ConsumerState<MemosScreen> createState() => _MemosScreenState();
}

class _MemosScreenState extends ConsumerState<MemosScreen>
    with KeyboardNavigationMixin<MemosScreen> {
  // ScrollController and RefreshIndicatorKey are now managed within MemosBody
  final FocusNode _focusNode =
      FocusNode(); // Keep FocusNode for the screen level

  @override
  void initState() {
    super.initState();
    // Load initial preferences (including the quick filter preset)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loadFilterPreferencesProvider); // Load saved preset
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Dispose the focus node
    super.dispose(); // Must call super
  }


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

    // Watch the selected quick filter preset key
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    // Get the label for the current preset for the title
    final currentPresetLabel =
        quickFilterPresets[selectedPresetKey]?.label ?? 'Memos';

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
                // Update middle text to show current quick filter preset label
                middle: Text(currentPresetLabel),
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
                    // REMOVED: Old filter dropdown button (_buildFilterButton)
                    // Create new memo button
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minSize: 0,
                      onPressed: () {
                        // Use the root navigator to push the route
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed('/new-memo');
                        // Refresh is handled by MemosNotifier observing changes
                      },
                      child: const Icon(CupertinoIcons.add),
                    ),
                  ],
                ),
              ),
      child: SafeArea(
        // Add SafeArea
        child: Focus(
          // Wrap the body content
          focusNode: _focusNode,
          autofocus: true, // Try to grab focus automatically
          onKeyEvent: _handleKeyEvent, // Use the handler
          // Add Column to place SearchBar and Filter Control above the list
          child: Column(
            children: [
              // Add Search Bar here if not in multi-select mode
              if (!isMultiSelectMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16.0,
                    8.0,
                    16.0,
                    0.0,
                  ), // Reduced bottom padding
                  child: _buildSearchBar(), // Build the search bar widget
                ),

              // Add Quick Filter Segmented Control if not in multi-select mode
              if (!isMultiSelectMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: _buildQuickFilterControl(),
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

  // Build the Quick Filter Segmented Control
  Widget _buildQuickFilterControl() {
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final theme = CupertinoTheme.of(context);

    // Define the segments for the control, excluding the 'custom' preset
    // Use icons if available, otherwise just text
    final Map<String, Widget> segments = {
      for (var preset in quickFilterPresets.values)
        if (preset.key != 'custom') // Exclude 'custom' from segments
          preset.key: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 6.0,
            ), // Adjust padding
            child: Row(
              // Use Row for icon + text
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (preset.icon != null)
                  Icon(
                    preset.icon,
                    size: 18, // Adjust icon size
                    // Color will be handled by the segmented control state
                  ),
                if (preset.icon != null)
                  const SizedBox(width: 4), // Spacing between icon and text
                Text(preset.label),
              ],
            ),
          ),
    };

    return SizedBox(
      // Constrain width if needed
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<String>(
        // Set groupValue to null if 'custom' is selected, otherwise use the key
        groupValue: selectedPresetKey == 'custom' ? null : selectedPresetKey,
        thumbColor: theme.primaryColor, // Use theme color for thumb
        backgroundColor: CupertinoColors.secondarySystemFill.resolveFrom(
          context,
        ),
        onValueChanged: (String? newPresetKey) {
          if (newPresetKey != null) {
            if (kDebugMode) {
              print('[MemosScreen] Quick filter selected: $newPresetKey');
            }
            // Update the preset provider
            ref.read(quickFilterPresetProvider.notifier).state = newPresetKey;
            // Clear any raw filter from the advanced panel if a quick preset is chosen
            if (ref.read(rawCelFilterProvider).isNotEmpty) {
              ref.read(rawCelFilterProvider.notifier).state = '';
            }
            // Trigger a refresh (MemosNotifier should react to combinedFilterProvider change)
            // ref.read(memosNotifierProvider.notifier).refresh(); // Usually not needed if notifier watches combinedFilterProvider
            // Save preference
            ref.read(filterPreferencesProvider)(newPresetKey);
          }
        },
        children: segments,
      ),
    );
  }

  void _showAdvancedFilterPanel(BuildContext context) {
    // Show the advanced filter panel using showCupertinoModalPopup
    showCupertinoModalPopup(
      context: context,
      // Make the background dismissible
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Use the AdvancedFilterPanel widget directly
        return DraggableScrollableSheet(
          initialChildSize: 0.8, // Start at 80% height
          minChildSize: 0.4, // Minimum height when dragging down
          maxChildSize: 0.9, // Maximum height
          expand: false,
          builder: (_, scrollController) {
            // Pass the scroll controller to the panel if it needs it
            // For now, we wrap the panel itself
            return AdvancedFilterPanel(onClose: () => Navigator.pop(context));
          },
        );
        /* // Previous implementation without DraggableScrollableSheet
        return SizedBox(
          // Set height to 80% of screen height
          height: MediaQuery.of(context).size.height * 0.8,
          child: AdvancedFilterPanel(onClose: () => Navigator.pop(context)),
        );
        */
      },
    );
  }

  // REMOVED: _showFilterActionSheet method
  // REMOVED: _buildFilterButton method

  // Method to build the server switcher button (remains unchanged)
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

  // Method to show the server selection action sheet (remains unchanged)
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
                    // Ensure settings route exists and is handled correctly
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
                        // Explicitly invalidate the memos notifier to trigger a refresh
                        ref.invalidate(memosNotifierProvider);
                        if (kDebugMode) {
                          print(
                            '[MemosScreen] Invalidated memosNotifierProvider after server switch.',
                          );
                        }
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

  // Build the search bar widget (remains unchanged)
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
          // MemosNotifier should react to combinedFilterProvider change if search is part of it
          // Or trigger refresh explicitly if search is handled separately
          ref.read(memosNotifierProvider.notifier).refresh();
        } else if (isLocalSearch) {
          // If local search is enabled, no server refresh needed on text change
          // The filtering happens client-side via filteredMemosProvider
        }
      },
      onSubmitted: (value) {
        // Trigger server search on submit if local search is disabled
        final isLocalSearch = ref.read(localSearchEnabledProvider);
        if (!isLocalSearch) {
          ref.read(memosNotifierProvider.notifier).refresh();
        }
      },
    );
  }

  // Function to handle the move process for a specific memo (remains unchanged)
  void _handleMoveMemoToServer(String memoId) {
    if (kDebugMode) {
      print(
        '[MemosScreen] _handleMoveMemoToServer called for memo ID: $memoId',
      );
    }

    // 1. Get available servers
    final multiServerState = ref.read(multiServerConfigProvider);
    final servers = multiServerState.servers;
    final activeServerId = multiServerState.activeServerId;
    final availableTargetServers =
        servers.where((s) => s.id != activeServerId).toList();

    if (kDebugMode) {
      print(
        '[MemosScreen] Found ${availableTargetServers.length} target servers.',
      );
    }

    if (availableTargetServers.isEmpty) {
      // Show dialog: No other servers available
      showCupertinoDialog(
        context: context, // Use context from the State class
        builder:
            (ctx) => CupertinoAlertDialog(
              title: const Text('No Other Servers'),
              content: const Text(
                'You need to configure at least one other server to move memos.',
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
      );
      return;
    }

    // 2. Show CupertinoActionSheet to select target server
    showCupertinoModalPopup<ServerConfig>(
      context: context, // Use context from the State class
      builder:
          (sheetContext) => CupertinoActionSheet(
            title: const Text('Move Memo To...'),
            actions:
                availableTargetServers
                    .map(
                      (server) => CupertinoActionSheetAction(
                        child: Text(server.name ?? server.serverUrl),
                        onPressed: () {
                          if (kDebugMode) {
                            print(
                              '[MemosScreen] Selected target server: ${server.name ?? server.id}',
                            );
                          }
                          Navigator.pop(
                            sheetContext,
                            server,
                          ); // Return selected server
                        },
                      ),
                    )
                    .toList(),
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(sheetContext),
            ),
          ),
    ).then((selectedServer) {
      if (selectedServer != null) {
        // 3. Call the moveMemoProvider if a server was selected
        if (kDebugMode) {
          print(
            '[MemosScreen] Calling moveMemoProvider for memo $memoId to server ${selectedServer.id}',
          );
        }
        final moveParams = MoveMemoParams(
          memoId: memoId,
          targetServer: selectedServer,
        );
        // Consider showing a loading indicator here
        ref
            .read(moveMemoProvider(moveParams))()
            .then((_) {
              if (kDebugMode) {
                print('[MemosScreen] Move successful for memo $memoId');
              }
              // Optional: Show success feedback
              if (mounted) {
                // Check mounted after async operation
                showCupertinoDialog(
                  context: context, // Use context from the State class
                  builder:
                      (ctx) => CupertinoAlertDialog(
                        title: const Text('Move Successful'),
                        content: Text(
                          'Memo moved to ${selectedServer.name ?? selectedServer.serverUrl}.',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                );
              }
            })
            .catchError((error, stackTrace) {
              // Include stackTrace for better debugging
              if (kDebugMode) {
                print('[MemosScreen] Move failed for memo $memoId: $error');
                print(stackTrace); // Print stack trace
              }
              // Show error dialog
              if (mounted) {
                // Check mounted after async operation
                showCupertinoDialog(
                  context: context, // Use context from the State class
                  builder:
                      (ctx) => CupertinoAlertDialog(
                        title: const Text('Move Failed'),
                        // Provide a more user-friendly error message
                        content: Text(
                          'Could not move memo. Error: ${error.toString()}',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                );
              }
            });
      } else {
        if (kDebugMode) {
          print('[MemosScreen] No target server selected.');
        }
      }
    });
  }

  // Simplified _buildMemosList to delegate to MemosBody (remains unchanged)
  Widget _buildMemosList(MemosState memosState, List<Memo> visibleMemos) {
    return MemosBody(
      onMoveMemoToServer: _handleMoveMemoToServer,
    );
  }
}
