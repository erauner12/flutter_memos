import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem model
import 'package:flutter_memos/models/server_config.dart';
// Import note_providers and use non-family providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
// Import single server config provider
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewNoteForm extends ConsumerStatefulWidget {
  const NewNoteForm({super.key});

  @override
  ConsumerState<NewNoteForm> createState() => _NewNoteFormState();
}

class _NewNoteFormState extends ConsumerState<NewNoteForm>
    with KeyboardNavigationMixin<NewNoteForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _formFocusNode = FocusNode(debugLabel: 'NewNoteFormFocus');

  bool _loading = false;
  String? _error;
  bool _showMarkdownHelp = false;
  bool _previewMode = false;
  ServerConfig? _selectedServerConfig; // Holds the single configured server

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Read the single note server config
      final singleServer = ref.read(noteServerConfigProvider);

      if (mounted) {
        setState(() {
          _selectedServerConfig = singleServer;
        });
        // Focus the content field if a server is configured
        if (singleServer != null) {
          FocusScope.of(context).requestFocus(_contentFocusNode);
        } else {
          // Optionally show a dialog if no server is configured
          _showNoServerDialog();
        }
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

  void _showNoServerDialog() {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('No Server Configured'),
            content: const Text(
              'Please configure a Note server in Settings before creating a note.',
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

  // Removed _showServerSelection method as we now use a single server config

  Future<void> _handleCreateNote() async {
    final content = _contentController.text.trim();

    // Check if a server is configured
    if (_selectedServerConfig == null) {
      if (mounted) {
        _showNoServerDialog(); // Show the no server dialog again
      }
      return;
    }
    // No need for targetServerId, we use the single _selectedServerConfig

    if (content.isEmpty) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Empty Note'),
                content: const Text('Please enter some content for your note.'),
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
      print('[NewNoteForm] Creating new note via _handleCreateNote');
      print(
        '[NewNoteForm] Target Server: ${_selectedServerConfig?.name ?? _selectedServerConfig?.id}',
      );
      print('[NewNoteForm] Content length: ${content.length} characters');
      if (content.length < 200) {
        print('[NewNoteForm] Content: "$content"');
      } else {
        print(
          '[NewNoteForm] Content preview: "${content.substring(0, 197)}..."',
        );
      }
      final urlRegex = RegExp(r'(https?://[^\s]+)|([\w-]+://[^\s]+)');
      final matches = urlRegex.allMatches(content);
      if (matches.isNotEmpty) {
        print('[NewNoteForm] URLs in content:');
        for (final match in matches) {
          print('[NewNoteForm]   - ${match.group(0)}');
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
        id: 'temp', // Server will assign the real ID
        content: content,
        visibility: NoteVisibility.public, // Default visibility
        pinned: false,
        state: NoteState.normal,
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
        displayTime: DateTime.now(),
        tags: [], // Initialize empty lists
        resources: [],
        relations: [],
        creatorId: null, // Let server assign creator
        parentId: null,
        startDate: null,
        endDate: null,
      );

      // Use the non-family createNoteProvider
      await ref.read(note_providers.createNoteProvider)(newNote);

      if (kDebugMode) {
        print(
          '[NewNoteForm] Note created successfully on server ${_selectedServerConfig!.id}',
        );
      }

      // Invalidate the non-family notes list provider
      ref.invalidate(note_providers.notesNotifierProvider);

      if (mounted) {
        // Pop back instead of replacing
        Navigator.of(context).pop();
        // Optionally show a success message (e.g., using a SnackBar or Toast)
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NewNoteForm] Error creating note: $e');
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
    // Display message if no server is configured
    if (_selectedServerConfig == null && !_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_shield, size: 50),
              const SizedBox(height: 16),
              const Text(
                'No Note Server Configured',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please go to Settings and configure a Memos or Blinko server to create notes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 20),
              CupertinoButton(
                child: const Text('Go Back'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    return Focus(
      focusNode: _formFocusNode,
      onKeyEvent: (node, event) {
        if (kDebugMode) {
          // print('[NewNoteForm] Received key event: ${event.logicalKey.keyLabel}');
        }

        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            (HardwareKeyboard.instance.isMetaPressed ||
                HardwareKeyboard.instance.isControlPressed)) {
          if (!_loading) {
            if (kDebugMode) {
              print(
                '[NewNoteForm] Command/Ctrl+Enter detected, calling _handleCreateNote',
              );
            }
            _handleCreateNote();
          } else {
            if (kDebugMode) {
              print(
                '[NewNoteForm] Command/Ctrl+Enter detected, but already loading',
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
            // Removed Server Selection Section
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
                              '[NewNoteForm] Switched to ${_previewMode ? "preview" : "edit"} mode',
                            );
                            if (_previewMode) {
                              final content = _contentController.text;
                              print(
                                '[NewNoteForm] Previewing content with ${content.length} chars',
                              );
                              final urlRegex = RegExp(
                                r'(https?://[^\s]+)|([\w-]+://[^\s]+)',
                              );
                              final matches = urlRegex.allMatches(content);
                              if (matches.isNotEmpty) {
                                print('[NewNoteForm] URLs in preview content:');
                                for (final match in matches) {
                                  print('[NewNoteForm]   - ${match.group(0)}');
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
                                '[NewNoteForm] Link tapped in preview: text="$text", href="$href"',
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
                                  '[NewNoteForm] URL launch result: $success',
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
                      placeholder: 'Enter your note content...',
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
                // Disable button if loading or no server is selected
                onPressed:
                    _loading || _selectedServerConfig == null
                        ? null
                        : _handleCreateNote,
                child:
                    _loading
                        ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                          radius: 10,
                        )
                        : const Text('Create Note'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
