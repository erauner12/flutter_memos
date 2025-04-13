import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
// Keep specific framework imports needed
import 'package:flutter/material.dart'; // Import Material for Tooltip
import 'package:flutter/services.dart'; // Add import for keyboard events
import 'package:flutter_memos/models/memo.dart';
// Updated imports per Change 1:
import 'package:flutter_memos/models/server_config.dart'; // Import ServerConfig model
import 'package:flutter_memos/providers/filter_providers.dart';
// Import MCP provider
import 'package:flutter_memos/providers/mcp_server_config_provider.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
// Import CloudKit Service Provider
import 'package:flutter_memos/providers/service_providers.dart';
// Import Settings providers (API Keys etc.)
import 'package:flutter_memos/providers/settings_provider.dart';
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
  // Add the ScrollController here
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose(); // Dispose the scroll controller
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
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamed('/memo-detail', arguments: {'memoId': selectedId});
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
      FocusScope.of(context).unfocus();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (kDebugMode) {
      print(
        '[MemosScreen _handleKeyEvent] Received key: ${event.logicalKey.keyLabel}',
      );
      print(
        '[MemosScreen _handleKeyEvent] FocusNode has focus: ${node.hasFocus}',
      );
    }

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
    final memosState = ref.watch(memosNotifierProvider);
    final visibleMemos = ref.watch(visibleMemosListProvider);
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final currentPresetLabel =
        quickFilterPresets[selectedPresetKey]?.label ?? 'Memos';
    final isMultiSelectMode = ref.watch(
      ui_providers.memoMultiSelectModeProvider,
    );
    final selectedIds = ref.watch(
      ui_providers.selectedMemoIdsForMultiSelectProvider,
    );

    return CupertinoPageScaffold(
      navigationBar:
          isMultiSelectMode
              ? _buildMultiSelectNavBar(selectedIds.length)
              : CupertinoNavigationBar(
                transitionBetweenRoutes: false,
                leading: _buildServerSwitcherButton(),
                middle: GestureDetector(
                  onTap: () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Container(
                    color: CupertinoColors.transparent,
                    child: Text(currentPresetLabel),
                  ),
                ),
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
                      child: const Icon(CupertinoIcons.checkmark_seal,
                    ),
                    ),
                    // Advanced filter button
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minSize: 0,
                      onPressed: () => _showAdvancedFilterPanel(context),
                      child: const Icon(CupertinoIcons.tuningfork),
                    ),
                    // Create new memo button
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minSize: 0,
                      onPressed: () {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed('/new-memo');
                      },
                      child: const Icon(CupertinoIcons.add),
                    ),
                    // Add Reset Button (Temporary placement) per Change 2
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minSize: 0,
                      onPressed:
                          _showResetConfirmationDialog, // Call confirmation dialog
                      child: const Tooltip(
                        message: 'Reset All Cloud & Local Data',
                        child: Icon(
                          CupertinoIcons.exclamationmark_octagon,
                          color: CupertinoColors.systemRed, // Make it stand out
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      child: SafeArea(
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Column(
            children: [
              if (!isMultiSelectMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
                  child: _buildSearchBar(),
                ),
              if (!isMultiSelectMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: _buildQuickFilterControl(),
                ),
              Expanded(child: _buildMemosList(memosState, visibleMemos)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterControl() {
    final selectedPresetKey = ref.watch(quickFilterPresetProvider);
    final theme = CupertinoTheme.of(context);

    final Map<String, Widget> segments = {
      for (var preset in quickFilterPresets.values)
        if (preset.key != 'custom')
          preset.key: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (preset.icon != null)
                  Icon(
                    preset.icon,
                    size: 18,
                  ),
                if (preset.icon != null) const SizedBox(width: 4),
                Text(preset.label),
              ],
            ),
          ),
    };

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: selectedPresetKey == 'custom' ? null : selectedPresetKey,
        thumbColor: theme.primaryColor,
        backgroundColor: CupertinoColors.secondarySystemFill.resolveFrom(
          context,
        ),
        onValueChanged: (String? newPresetKey) {
          if (newPresetKey != null) {
            if (kDebugMode) {
              print('[MemosScreen] Quick filter selected: $newPresetKey');
            }
            ref.read(quickFilterPresetProvider.notifier).state = newPresetKey;
            if (ref.read(rawCelFilterProvider).isNotEmpty) {
              ref.read(rawCelFilterProvider.notifier).state = '';
            }
            ref.read(filterPreferencesProvider)(newPresetKey);
          }
        },
        children: segments,
      ),
    );
  }

  void _showAdvancedFilterPanel(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return AdvancedFilterPanel(onClose: () => Navigator.pop(context));
          },
        );
      },
    );
  }

  Widget _buildServerSwitcherButton() {
    final activeServer = ref.watch(activeServerConfigProvider);
    final serverName =
        activeServer?.name ?? activeServer?.serverUrl ?? 'No Server';
    final truncatedName =
        serverName.length > 15
            ? '${serverName.substring(0, 12)}...'
            : serverName;

    return CupertinoButton(
      padding: const EdgeInsets.only(left: 8.0),
      onPressed: () => _showServerSelectionSheet(context, ref),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.square_stack_3d_down_right, size: 20),
          const SizedBox(width: 4),
          Text(
            truncatedName,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          const Icon(CupertinoIcons.chevron_down, size: 14),
        ],
      ),
    );
  }

  void _showServerSelectionSheet(BuildContext context, WidgetRef ref) {
    final multiServerState = ref.read(multiServerConfigProvider);
    final servers = multiServerState.servers;
    final activeServerId = multiServerState.activeServerId;
    final notifier = ref.read(multiServerConfigProvider.notifier);

    if (servers.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('No Servers'),
              content: const Text(
                'Please add a server configuration in Settings.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Settings'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pushNamed('/settings');
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
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Switch Active Server'),
            actions:
                servers.map((server) {
                  final bool isActive = server.id == activeServerId;
                  return CupertinoActionSheetAction(
                    isDefaultAction: isActive,
                    onPressed: () {
                      if (!isActive) {
                        if (kDebugMode) {
                          print(
                            '[MemosScreen] Setting active server to: ${server.name ?? server.id}',
                          );
                        }
                        notifier.setActiveServer(server.id);
                        ref.invalidate(memosNotifierProvider);
                        if (kDebugMode) {
                          print(
                            '[MemosScreen] Invalidated memosNotifierProvider after server switch.',
                          );
                        }
                      }
                      Navigator.pop(context);
                    },
                    child: Text(server.name ?? server.serverUrl),
                  );
                }).toList(),
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }

  Widget _buildSearchBar() {
    final searchQuery = ref.watch(searchQueryProvider);
    final TextEditingController controller = TextEditingController(
      text: searchQuery,
    );
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return CupertinoSearchTextField(
      controller: controller,
      placeholder: 'Search memos...',
      style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
      decoration: BoxDecoration(
        color: CupertinoColors.systemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(10.0),
      ),
      onChanged: (value) {
        ref.read(searchQueryProvider.notifier).state = value;
        final isLocalSearch = ref.read(localSearchEnabledProvider);
        if (!isLocalSearch && value.isNotEmpty) {
          ref.read(memosNotifierProvider.notifier).refresh();
        }
      },
      onSubmitted: (value) {
        final isLocalSearch = ref.read(localSearchEnabledProvider);
        if (!isLocalSearch) {
          ref.read(memosNotifierProvider.notifier).refresh();
        }
      },
    );
  }

  void _handleMoveMemoToServer(String memoId) {
    if (kDebugMode) {
      print(
        '[MemosScreen] _handleMoveMemoToServer called for memo ID: $memoId',
      );
    }

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
      showCupertinoDialog(
        context: context,
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

    showCupertinoModalPopup<ServerConfig>(
      context: context,
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
                          Navigator.pop(sheetContext, server);
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
        if (kDebugMode) {
          print(
            '[MemosScreen] Calling moveMemoProvider for memo $memoId to server ${selectedServer.id}',
          );
        }
        final moveParams = MoveMemoParams(
          memoId: memoId,
          targetServer: selectedServer,
        );
        ref
            .read(moveMemoProvider(moveParams))()
            .then((_) {
              if (kDebugMode) {
                print('[MemosScreen] Move successful for memo $memoId');
              }
              if (mounted) {
                showCupertinoDialog(
                  context: context,
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
              if (kDebugMode) {
                print('[MemosScreen] Move failed for memo $memoId: $error');
                print(stackTrace);
              }
              if (mounted) {
                showCupertinoDialog(
                  context: context,
                  builder:
                      (ctx) => CupertinoAlertDialog(
                        title: const Text('Move Failed'),
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

  Widget _buildMemosList(MemosState memosState, List<Memo> visibleMemos) {
    return MemosBody(
      scrollController: _scrollController,
      onMoveMemoToServer: _handleMoveMemoToServer,
    );
  }

  // --- Reset Logic ---
  /// Shows a confirmation dialog before performing the full data reset.
  void _showResetConfirmationDialog() {
    // Ensure context is valid before showing dialog
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => CupertinoAlertDialog(
            title: const Text('Reset All Cloud & Local Data?'),
            content: const Text(
              'WARNING: This will permanently delete ALL Memos server configurations, MCP server configurations, and saved API keys (Todoist, OpenAI, Gemini) from this device AND from your iCloud account.\n\nThis action cannot be undone and is intended for recovery purposes only.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Reset Data'),
                onPressed: () {
                  Navigator.pop(dialogContext); // Close the dialog first
                  // Call the reset asynchronously without awaiting here
                  _performFullReset();
                },
              ),
            ],
          ),
    );
  }

  /// Performs the full reset of CloudKit and local data.
  Future<void> _performFullReset() async {
    if (kDebugMode) {
      print('[MemosScreen] Starting full data reset...');
    }

    // Optional: Show a loading indicator (e.g., using a state variable and conditional UI)
    // setState(() => _isResetting = true); // Example

    bool cloudSuccess = true;
    String cloudErrorMessage = '';

    try {
      final cloudKitService = ref.read(cloudKitServiceProvider);

      // Delete CloudKit Data - Await each deletion attempt
      if (kDebugMode)
        print('[MemosScreen] Deleting CloudKit ServerConfig records...');
      bool deleteServersSuccess = await cloudKitService.deleteAllRecordsOfType(
        'ServerConfig',
      );
      if (!deleteServersSuccess) {
        cloudSuccess = false;
        cloudErrorMessage += 'Failed to delete ServerConfig records. ';
        if (kDebugMode)
          print('[MemosScreen] Failed CloudKit ServerConfig deletion.');
      }

      if (kDebugMode)
        print('[MemosScreen] Deleting CloudKit McpServerConfig records...');
      bool deleteMcpSuccess = await cloudKitService.deleteAllRecordsOfType(
        'McpServerConfig',
      );
      if (!deleteMcpSuccess) {
        cloudSuccess = false;
        cloudErrorMessage += 'Failed to delete McpServerConfig records. ';
        if (kDebugMode)
          print('[MemosScreen] Failed CloudKit McpServerConfig deletion.');
      }

      if (kDebugMode)
        print('[MemosScreen] Deleting CloudKit UserSettings record...');
      bool deleteSettingsSuccess =
          await cloudKitService.deleteUserSettingsRecord();
      if (!deleteSettingsSuccess) {
        cloudSuccess = false;
        cloudErrorMessage += 'Failed to delete UserSettings record. ';
        if (kDebugMode)
          print('[MemosScreen] Failed CloudKit UserSettings deletion.');
      }

      if (!cloudSuccess) {
        if (kDebugMode)
          print(
            '[MemosScreen] CloudKit deletion finished with errors: $cloudErrorMessage',
          );
      } else {
        if (kDebugMode)
          print('[MemosScreen] CloudKit deletion finished successfully.');
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(
          '[MemosScreen] Critical error during CloudKit deletion phase: $e\n$s',
        );
      }
      cloudSuccess = false;
      cloudErrorMessage =
          'A critical error occurred during CloudKit deletion: $e';
    }

    // Reset Local Notifiers and Cache (always attempt this, even if CloudKit failed)
    try {
      if (kDebugMode)
        print('[MemosScreen] Resetting local notifiers and cache...');
      // Use read().notifier for StateNotifiers
      await ref.read(multiServerConfigProvider.notifier).resetStateAndCache();
      await ref.read(mcpServerConfigProvider.notifier).resetStateAndCache();
      await ref
          .read(todoistApiKeyProvider.notifier)
          .clear(); // Uses set('') internally
      await ref.read(openAiApiKeyProvider.notifier).clear();
      await ref.read(openAiModelIdProvider.notifier).clear();
      await ref.read(geminiApiKeyProvider.notifier).clear();
      if (kDebugMode) print('[MemosScreen] Local reset finished.');
    } catch (e, s) {
      if (kDebugMode) {
        print('[MemosScreen] Error during local notifier reset phase: $e\n$s');
      }
      // Log error, but don't necessarily mark overall success as false just for local errors
      cloudErrorMessage += '\nAn error also occurred during local data reset.';
    }

    // Optional: Hide loading indicator
    // if (mounted) setState(() => _isResetting = false); // Example

    // Show final feedback dialog only if the widget is still mounted
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder:
            (BuildContext finalDialogContext) => CupertinoAlertDialog(
              title: Text(
                cloudSuccess ? 'Reset Complete' : 'Reset Partially Failed',
              ),
              content: Text(
                cloudSuccess
                    ? 'All cloud and local configurations have been reset. Please restart the app or navigate to Settings to reconfigure.'
                    : 'Local data has been reset, but errors occurred during CloudKit deletion. $cloudErrorMessage\nPlease check your iCloud data manually via Settings > Apple ID > iCloud > Manage Account Storage, then restart the app.',
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(finalDialogContext);
                    ref.invalidate(loadServerConfigProvider);
                    if (kDebugMode) {
                      print(
                        '[MemosScreen] Reset complete. Invalidated loadServerConfigProvider.',
                      );
                    }
                  },
                ),
              ],
            ),
      );
    } else {
      if (kDebugMode) {
        print(
          '[MemosScreen] Widget unmounted before final reset dialog could be shown.',
        );
      }
    }
  }
  // --- End Reset Logic ---
}
