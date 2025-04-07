// Import necessary packages and models
import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
// TextDecoration is in dart:ui, usually implicitly imported
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_memos/models/memo.dart'; // Import Memo model
import 'package:flutter_memos/models/server_config.dart'; // Import ServerConfig
import 'package:flutter_memos/providers/server_config_provider.dart'; // Import server config provider
import 'package:flutter_memos/utils/keyboard_navigation.dart'; // Import the mixin
import 'package:flutter_memos/utils/url_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'new_memo_providers.dart';

class NewMemoForm extends ConsumerStatefulWidget {
  const NewMemoForm({super.key});

  @override
  ConsumerState<NewMemoForm> createState() => _NewMemoFormState();
}

class _NewMemoFormState extends ConsumerState<NewMemoForm>
    with KeyboardNavigationMixin<NewMemoForm> {
  // Global key for the Form widget
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _formFocusNode = FocusNode(debugLabel: 'NewMemoFormFocus');

  bool _loading = false;
  String? _error;
  bool _showMarkdownHelp = false;
  bool _previewMode = false;

  // State variable to hold the selected target server
  ServerConfig? _selectedServerConfig;

  @override
  void initState() {
    super.initState();
    // Initialize selected server with the active one
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

  // Add method to show server selection action sheet
  void _showServerSelection() {
    final multiServerState = ref.read(multiServerConfigProvider);
    final servers = multiServerState.servers;

    if (servers.isEmpty) {
      // Should not happen if navigated from main screen, but handle defensively
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

  Future<void> _handleCreateMemo() async {
    final content = _contentController.text.trim();

    if (_selectedServerConfig == null) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('No Server Selected'),
                content: const Text(
                  'Please select a target server for this memo.',
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
                title: const Text('Empty Memo'),
                content: const Text('Please enter some content for your memo.'),
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
      print('[NewMemoForm] Creating new memo via _handleCreateMemo');
      print(
        '[NewMemoForm] Target Server: ${_selectedServerConfig?.name ?? _selectedServerConfig?.id}',
      );
      print('[NewMemoForm] Content length: ${content.length} characters');
      if (content.length < 200) {
        print('[NewMemoForm] Content: "$content"');
      } else {
        print(
          '[NewMemoForm] Content preview: "${content.substring(0, 197)}..."',
        );
      }
      final urlRegex = RegExp(r'(https?://[^\s]+)|([\w-]+://[^\s]+)');
      final matches = urlRegex.allMatches(content);
      if (matches.isNotEmpty) {
        print('[NewMemoForm] URLs in content:');
        for (final match in matches) {
          print('[NewMemoForm]   - ${match.group(0)}');
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
      final newMemo = Memo(
        id: 'temp', // ID is assigned by server
        content: content,
        visibility: 'PUBLIC',
      );

      // Call the provider, passing the selected server config
      final createdMemo = await ref.read(createMemoProvider)(
        newMemo,
        targetServerOverride: _selectedServerConfig,
      );

      if (kDebugMode) {
        print(
          '[NewMemoForm] Memo created successfully on server ${_selectedServerConfig?.id} with ID: ${createdMemo.id}',
        );
      }

      // Invalidate memos if the created memo's server matches the active one
      final activeServerId = ref.read(activeServerConfigProvider)?.id;
      if (_selectedServerConfig?.id == activeServerId) {
        ref.invalidate(memo_providers.memosNotifierProvider);
      }

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/memo-detail',
          arguments: {'memoId': createdMemo.id},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NewMemoForm] Error creating memo: $e');
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
                content: Text('Failed to create memo: ${e.toString()}'),
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
            '[NewMemoForm] Received key event: ${event.logicalKey.keyLabel}',
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
              '[NewMemoForm] Enter key pressed. Meta key pressed: $metaPressed',
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
                '[NewMemoForm] Command+Enter detected, calling _handleCreateMemo',
              );
            }
            _handleCreateMemo();
          } else {
            if (kDebugMode) {
              print(
                '[NewMemoForm] Command+Enter detected, but already loading',
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
            // Server Selection Section
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
            // Content Section with Markdown help and preview toggle
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                // Preview Toggle Button
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
                              '[NewMemoForm] Switched to ${_previewMode ? "preview" : "edit"} mode',
                            );
                            if (_previewMode) {
                              final content = _contentController.text;
                              print(
                                '[NewMemoForm] Previewing content with ${content.length} chars',
                              );
                              final urlRegex = RegExp(
                                r'(https?://[^\s]+)|([\w-]+://[^\s]+)',
                              );
                              final matches = urlRegex.allMatches(content);
                              if (matches.isNotEmpty) {
                                print('[NewMemoForm] URLs in preview content:');
                                for (final match in matches) {
                                  print('[NewMemoForm]   - ${match.group(0)}');
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
                // Content Input/Preview Area
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
                                '[NewMemoForm] Link tapped in preview: text="$text", href="$href"',
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
                                  '[NewMemoForm] URL launch result: $success',
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
                      placeholder: 'Enter your memo content...',
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
                      autofocus: true,
                      keyboardType: TextInputType.multiline,
                    ),
              ],
            ),
            // Error message display
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
            // Create Button
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed:
                    _loading || _selectedServerConfig == null
                        ? null
                        : _handleCreateMemo,
                child:
                    _loading
                        ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                          radius: 10,
                        )
                        : const Text('Create Memo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
