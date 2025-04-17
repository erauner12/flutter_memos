import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem model
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/api_providers.dart' as api_providers;
// Import note_providers instead of memo_providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/services/note_api_service.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define the provider locally within the form file
// Keep name createNoteProvider, uses NoteItem
final createNoteProvider = Provider<
  Future<NoteItem> Function(NoteItem note, {ServerConfig? targetServerOverride})
>((ref) {
  final baseApiService = ref.watch(api_providers.apiServiceProvider);
  return (note, {targetServerOverride}) async {
    if (baseApiService is! NoteApiService) {
      throw Exception('Active service does not support note operations.');
    }
    final NoteApiService apiService = baseApiService; // Cast
    return apiService.createNote(
      note,
      targetServerOverride: targetServerOverride,
    );
  };
});

class NewNoteForm extends ConsumerStatefulWidget { // Renamed class
  const NewNoteForm({super.key}); // Renamed constructor

  @override
  ConsumerState<NewNoteForm> createState() => _NewNoteFormState(); // Renamed class
}

class _NewNoteFormState extends ConsumerState<NewNoteForm> // Renamed class
    with KeyboardNavigationMixin<NewNoteForm> { // Renamed class
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _formFocusNode = FocusNode(debugLabel: 'NewNoteFormFocus'); // Renamed debug label

  bool _loading = false;
  String? _error;
  bool _showMarkdownHelp = false;
  bool _previewMode = false;
  ServerConfig? _selectedServerConfig;

  @override
  void initState() {
    super.initState();
    _selectedServerConfig = ref.read(activeServerConfigProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_contentFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    _formFocusNode.dispose();
    super.dispose();
  }

  Widget _buildMarkdownHelpItem(String syntax, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              syntax,
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: CupertinoColors.secondarySystemFill
                    .resolveFrom(context),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: MarkdownBody(data: description, shrinkWrap: true),
          ),
        ],
      ),
    );
  }

  void _showServerSelection() {
    final multiServerState = ref.read(multiServerConfigProvider);
    final servers = multiServerState.servers;

    if (servers.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('No Servers Available'),
              content: const Text(
                'Please configure a server in Settings first.',
              ),
              actions: [
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
            title: const Text('Select Target Server'),
            actions:
                servers.map((server) {
                  final bool isSelected =
                      server.id == _selectedServerConfig?.id;
                  return CupertinoActionSheetAction(
                    isDefaultAction: isSelected,
                    onPressed: () {
                      setState(() {
                        _selectedServerConfig = server;
                      });
                      Navigator.pop(context);
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

  Future<void> _handleCreateNote() async { // Renamed method
    final content = _contentController.text.trim();

    if (_selectedServerConfig == null) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('No Server Selected'),
                content: const Text(
                  'Please select a target server for this note.', // Updated text
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      }
      return;
    }

    if (content.isEmpty) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Empty Note'), // Updated text
                content: const Text('Please enter some content for your note.'), // Updated text
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      }
      return;
    }

    if (kDebugMode) {
      print('[NewNoteForm] Creating new note via _handleCreateNote'); // Updated log identifier
      print(
        '[NewNoteForm] Target Server: ${_selectedServerConfig?.name ?? _selectedServerConfig?.id}', // Updated log identifier
      );
      print('[NewNoteForm] Content length: ${content.length} characters'); // Updated log identifier
      if (content.length < 200) {
        print('[NewNoteForm] Content: "$content"'); // Updated log identifier
      } else {
        print(
          '[NewNoteForm] Content preview: "${content.substring(0, 197)}..."', // Updated log identifier
        );
      }
      final urlRegex = RegExp(r'(https?://[^\s]+)|([\w-]+://[^\s]+)');
      final matches = urlRegex.allMatches(content);
      if (matches.isNotEmpty) {
        print('[NewNoteForm] URLs in content:'); // Updated log identifier
        for (final match in matches) {
          print('[NewNoteForm]   - ${match.group(0)}'); // Updated log identifier
        }
      }
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final newNote = NoteItem(
        id: 'temp',
        content: content,
        visibility: NoteVisibility.public,
        pinned: false,
        state: NoteState.normal,
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
        displayTime: DateTime.now(),
      );

      // Use the locally defined createNoteProvider
      final createdNote = await ref.read(createNoteProvider)(
        newNote,
        targetServerOverride: _selectedServerConfig,
      );

      if (kDebugMode) {
        print(
          '[NewNoteForm] Note created successfully on server ${_selectedServerConfig?.id} with ID: ${createdNote.id}', // Updated log identifier
        );
      }

      final activeServerId = ref.read(activeServerConfigProvider)?.id;
      if (_selectedServerConfig?.id == activeServerId) {
        // Use provider from note_providers
        ref.invalidate(note_providers.notesNotifierProvider);
      }

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/item-detail', // Use new route
          arguments: {'itemId': createdNote.id}, // Pass itemId
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NewNoteForm] Error creating note: $e'); // Updated log identifier
      }
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });

        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text('Failed to create note: ${e.toString()}'),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _formFocusNode,
      onKeyEvent: (node, event) {
        if (kDebugMode) {
          print(
            '[NewNoteForm] Received key event: ${event.logicalKey.keyLabel}', // Updated log identifier
          );
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            final metaPressed =
                HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.meta,
                ) ||
                HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.metaLeft,
                ) ||
                HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.metaRight,
                );
            print(
              '[NewNoteForm] Enter key pressed. Meta key pressed: $metaPressed', // Updated log identifier
            );
          }
        }

        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            (HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.meta,
                ) ||
                HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.metaLeft,
                ) ||
                HardwareKeyboard.instance.isLogicalKeyPressed(
                  LogicalKeyboardKey.metaRight,
                ))) {
          if (!_loading) {
            if (kDebugMode) {
              print(
                '[NewNoteForm] Command+Enter detected, calling _handleCreateNote', // Updated log identifier
              );
            }
            _handleCreateNote(); // Use renamed method
          } else {
            if (kDebugMode) {
              print(
                '[NewNoteForm] Command+Enter detected, but already loading', // Updated log identifier
              );
            }
          }
          return KeyEventResult.handled;
        }

        final result = handleKeyEvent(
          event,
          ref,
          onEscape: () {
            if (_contentFocusNode.hasFocus) {
              _contentFocusNode.unfocus();
              _formFocusNode.requestFocus();
            } else {
              Navigator.of(context).pop();
            }
          },
        );

        return result;
      },
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            CupertinoFormSection.insetGrouped(
              header: const Text('TARGET SERVER'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Server'),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerRight,
                    onPressed: _showServerSelection,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _selectedServerConfig?.name ??
                              _selectedServerConfig?.serverUrl ??
                              'Select Server',
                          style: TextStyle(
                            color:
                                _selectedServerConfig == null
                                    ? CupertinoColors.placeholderText
                                        .resolveFrom(context)
                                    : CupertinoTheme.of(
                                      context,
                                    ).textTheme.textStyle.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.chevron_up_chevron_down,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CONTENT',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: () {
                      setState(() {
                        _showMarkdownHelp = !_showMarkdownHelp;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showMarkdownHelp
                              ? CupertinoIcons.question_circle_fill
                              : CupertinoIcons.question_circle,
                          size: 18,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showMarkdownHelp ? 'Hide Help' : 'Markdown Help',
                          style: TextStyle(
                            color: CupertinoTheme.of(context).primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              children: [
                if (_showMarkdownHelp)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemGroupedBackground
                          .resolveFrom(context),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.5,
                      ),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        const Text(
                          'Markdown Syntax Guide',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildMarkdownHelpItem('# Heading 1', 'Heading 1'),
                        _buildMarkdownHelpItem('## Heading 2', 'Heading 2'),
                        _buildMarkdownHelpItem('**Bold text**', 'Bold text'),
                        _buildMarkdownHelpItem('*Italic text*', 'Italic text'),
                        _buildMarkdownHelpItem(
                          '[Link](https://example.com)',
                          'Link',
                        ),
                        _buildMarkdownHelpItem(
                          '- Bullet point',
                          'Bullet point',
                        ),
                        _buildMarkdownHelpItem(
                          '1. Numbered item',
                          'Numbered item',
                        ),
                        _buildMarkdownHelpItem('`Code`', 'Code'),
                        _buildMarkdownHelpItem('> Blockquote', 'Blockquote'),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      onPressed: () {
                        setState(() {
                          _previewMode = !_previewMode;
                          if (kDebugMode) {
                            print(
                              '[NewNoteForm] Switched to ${_previewMode ? "preview" : "edit"} mode', // Updated log identifier
                            );
                            if (_previewMode) {
                              final content = _contentController.text;
                              print(
                                '[NewNoteForm] Previewing content with ${content.length} chars', // Updated log identifier
                              );
                              final urlRegex = RegExp(
                                r'(https?://[^\s]+)|([\w-]+://[^\s]+)',
                              );
                              final matches = urlRegex.allMatches(content);
                              if (matches.isNotEmpty) {
                                print('[NewNoteForm] URLs in preview content:'); // Updated log identifier
                                for (final match in matches) {
                                  print('[NewNoteForm]   - ${match.group(0)}'); // Updated log identifier
                                }
                              }
                            }
                          }
                          if (!_previewMode) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _contentFocusNode.requestFocus();
                            });
                          } else {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _formFocusNode.requestFocus();
                            });
                          }
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _previewMode
                                ? CupertinoIcons.pencil
                                : CupertinoIcons.eye,
                            size: 18,
                            color: CupertinoTheme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _previewMode ? 'Edit' : 'Preview',
                            style: TextStyle(
                              color: CupertinoTheme.of(context).primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _previewMode
                    ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CupertinoColors.separator.resolveFrom(context),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 200),
                      child: SingleChildScrollView(
                        child: MarkdownBody(
                          data: _contentController.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromCupertinoTheme(
                            CupertinoTheme.of(context),
                          ).copyWith(
                            p: CupertinoTheme.of(
                              context,
                            ).textTheme.textStyle.copyWith(
                              fontSize: 17,
                              height: 1.4,
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                            a: CupertinoTheme.of(
                              context,
                            ).textTheme.textStyle.copyWith(
                              color: CupertinoTheme.of(context).primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          onTapLink: (text, href, title) async {
                            if (kDebugMode) {
                              print(
                                '[NewNoteForm] Link tapped in preview: text="$text", href="$href"', // Updated log identifier
                              );
                            }
                            if (href != null) {
                              final success = await UrlHelper.launchUrl(
                                href,
                                context: context,
                                ref: ref,
                              );
                              if (kDebugMode) {
                                print(
                                  '[NewNoteForm] URL launch result: $success', // Updated log identifier
                                );
                              }
                            }
                          },
                        ),
                      ),
                    )
                    : CupertinoTextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      placeholder: 'Enter your note content...', // Updated placeholder
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemFill.resolveFrom(context),
                        border: Border.all(
                          color: CupertinoColors.separator.resolveFrom(context),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      maxLines: 10,
                      minLines: 5,
                      keyboardType: TextInputType.multiline,
                    ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: CupertinoColors.systemRed.resolveFrom(context),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed:
                    _loading || _selectedServerConfig == null
                        ? null
                        : _handleCreateNote, // Use renamed method
                child:
                    _loading
                        ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                          radius: 10,
                        )
                        : const Text('Create Note'), // Updated text
              ),
            ),
          ],
        ),
      ),
    );
  }
}
