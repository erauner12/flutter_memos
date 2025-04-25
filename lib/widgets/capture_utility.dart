import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart';
import 'package:flutter_memos/providers/comment_providers.dart'
    as comment_providers;
// Import note_providers and use non-family providers
import 'package:flutter_memos/providers/note_providers.dart' as note_providers;
// Import new single config providers
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SubmitAction {
  newComment,
  appendToLastComment,
  prependToLastComment,
  appendToMemo,
  prependToMemo,
}

enum CaptureMode { createMemo, addComment }

typedef CaptureUtilityState = _CaptureUtilityState;

class CaptureUtility extends ConsumerStatefulWidget {
  static final captureUtilityKey = GlobalKey<_CaptureUtilityState>();

  final CaptureMode mode;
  final String? memoId; // Renamed to noteId internally where appropriate
  final String? hintText;
  final String? buttonText;
  final bool isTestMode;
  // serverId is now determined internally from noteServerConfigProvider
  // final String? serverId;

  const CaptureUtility({
    super.key,
    this.mode = CaptureMode.createMemo,
    this.memoId,
    this.hintText,
    this.buttonText,
    this.isTestMode = false,
    // this.serverId, // Removed serverId parameter
  });

  static void setTestFileData(
    Uint8List fileData,
    String filename,
    String contentType,
  ) {
    final state = captureUtilityKey.currentState;
    if (state != null) {
      // Call the instance method on the state
      state.setFileDataForTest(fileData, filename, contentType);
    } else {
      debugPrint(
        '[CaptureUtility] Error: Cannot set test data - widget state not found',
      );
    }
  }

  @override
  ConsumerState<CaptureUtility> createState() => _CaptureUtilityState();
}

class _CaptureUtilityState extends ConsumerState<CaptureUtility>
    with SingleTickerProviderStateMixin {

  String? _effectiveServerId; // Store the serverId to use

  // --- Helper Methods ---
  Future<void> createNote(NoteItem note) async {
    // Use non-family provider
    await ref.read(note_providers.createNoteProvider)(note);
  }

  Future<void> addComment(
    String content,
    String noteId, {
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
  }) async {
    if (kDebugMode) {
      print(
        '[CaptureUtility._addComment] Adding comment: noteId=$noteId, serverId=$_effectiveServerId, content_empty=${content.isEmpty}, filename=$filename, contentType=$contentType, data_length=${_selectedFileData?.length}',
      );
    }
    if (_effectiveServerId == null) {
      throw Exception("Cannot add comment: Note server not configured.");
    }
    final newComment = Comment(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      creatorId: '1', // Assuming '1' is a placeholder or default
      createdTs: DateTime.now(), // Use DateTime directly
      parentId: noteId, // Pass parent ID
      serverId: _effectiveServerId!, // Pass server ID
    );
    // Use non-family provider with memoId parameter passed as a record
    await ref.read(
      comment_providers.createCommentProvider(
        (memoId: noteId), // Pass as record {memoId: noteId}
      ),
    )(
      newComment,
      fileBytes: fileBytes,
      filename: filename,
      contentType: contentType,
    );
  }

  // Method definition added inside the state class
  void setFileDataForTest(
    Uint8List fileData,
    String filename,
    String contentType,
  ) {
    if (kDebugMode) {
      print(
        '[CaptureUtilityState] Setting test file data: $filename ($contentType)',
      );
    }
    setState(() {
      _selectedFileData = fileData;
      _selectedFilename = filename;
      _selectedContentType = contentType;

      // Reset submit action if an attachment is added
      if (_submitAction != SubmitAction.newComment) {
        _submitAction = SubmitAction.newComment;
        // Optionally show a notification here
      }

      if (!_isExpanded) {
        _expand();
      }
    });
  }
  // --- End Helper Methods ---

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  Uint8List? _selectedFileData;
  String? _selectedFilename;
  String? _selectedContentType;

  // Update state variable type and default value
  SubmitAction _submitAction = SubmitAction.newComment;

  late AnimationController _animationController;
  bool _isDragging = false;
  double _collapsedHeight = 60.0;
  double _expandedHeight = 240.0;
  double _currentHeight = 60.0;

  static const SpringDescription _springDescription = SpringDescription(
    mass: 1.0,
    stiffness: 100.0,
    damping: 15.0,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..addListener(() {
      if (!_isDragging && _animationController.isAnimating) {
        setState(() {
          _currentHeight =
              lerpDouble(
                _collapsedHeight,
                _expandedHeight,
                _animationController.value,
              )!;
        });
      }
    });
    _currentHeight = _collapsedHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateEffectiveServerId(); // Determine serverId initially
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateHeights(context);
    _updateEffectiveServerId(); // Update if dependencies change (like activeServer)
  }

  void _updateEffectiveServerId() {
    // Get serverId from the single note provider
    final newServerId = ref.read(noteServerConfigProvider)?.id;
    if (_effectiveServerId != newServerId) {
      setState(() {
        _effectiveServerId = newServerId;
      });
      if (kDebugMode) {
        print(
          '[CaptureUtility] Effective Server ID set to: $_effectiveServerId',
        );
      }
    }
  }


  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateHeights(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double newCollapsedHeight = 60.0;
    double newExpandedHeight = 240.0;

    if (size.width > 1400) {
      newCollapsedHeight = 70.0;
      newExpandedHeight = 280.0;
    }

    if (newCollapsedHeight != _collapsedHeight ||
        newExpandedHeight != _expandedHeight) {
      setState(() {
        _collapsedHeight = newCollapsedHeight;
        _expandedHeight = newExpandedHeight;
        if (!_isExpanded) {
          _currentHeight = _collapsedHeight;
        } else {
          _currentHeight =
              lerpDouble(
                _collapsedHeight,
                _expandedHeight,
                _animationController.value,
              )!;
        }
      });
    }
  }

  void _animateTo(double targetValue, {double? velocity}) {
    _animationController.stop();
    final simulationVelocity = velocity ?? _animationController.velocity;
    final simulation = SpringSimulation(
      _springDescription,
      _animationController.value,
      targetValue,
      simulationVelocity,
    );
    _animationController.animateWith(simulation).whenCompleteOrCancel(() {
      if (!_isDragging && mounted) {
        setState(() {
          _currentHeight =
              targetValue == 1.0 ? _expandedHeight : _collapsedHeight;
          if ((targetValue - _animationController.value).abs() > 0.01) {
            _animationController.value = targetValue;
          }
        });
      }
    });
  }

  bool get _isExpanded => _animationController.value > 0.5;

  void _expand() {
    _animateTo(1.0);
    _focusNode.requestFocus();
  }

  void _collapse() {
    _animateTo(0.0);
    _focusNode.unfocus();
  }

  void _toggleExpansionState() {
    if (_isExpanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      final newHeight = _currentHeight - details.delta.dy;
      _currentHeight = newHeight.clamp(_collapsedHeight, _expandedHeight);
      _animationController.value =
          (_currentHeight - _collapsedHeight) /
          (_expandedHeight - _collapsedHeight);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    final dragVelocity = details.primaryVelocity ?? 0.0;
    final simulationVelocity =
        -dragVelocity / (_expandedHeight - _collapsedHeight);
    final currentFraction = _animationController.value;
    _isDragging = false;

    double targetValue;
    const velocityThreshold = 0.4;
    const positionThreshold = 0.5;

    if (simulationVelocity.abs() > velocityThreshold) {
      targetValue = simulationVelocity > 0 ? 1.0 : 0.0;
    } else {
      targetValue = currentFraction > positionThreshold ? 1.0 : 0.0;
    }

    if ((targetValue - currentFraction).abs() < 0.05 &&
        simulationVelocity.abs() < velocityThreshold / 2) {
      setState(() {
        _currentHeight =
            targetValue == 1.0 ? _expandedHeight : _collapsedHeight;
        _animationController.value = targetValue;
      });
    } else {
      _animateTo(targetValue, velocity: simulationVelocity);
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _animationController.stop();
    setState(() {
      _isDragging = true;
    });
  }

  Future<void> _handlePaste() async {
    final clipboardTextData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardTextData?.text != null &&
        clipboardTextData!.text!.isNotEmpty) {
      final currentText = _textController.text;
      final cursorPosition = _textController.selection.baseOffset;
      final newText =
          cursorPosition >= 0
              ? currentText.replaceRange(
                cursorPosition,
                _textController.selection.extentOffset,
                clipboardTextData.text!,
              )
              : currentText + clipboardTextData.text!;
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset:
              (cursorPosition >= 0 ? cursorPosition : currentText.length) +
              clipboardTextData.text!.length,
        ),
      );
      if (!_isExpanded) _expand();
    }

    if (_selectedFileData != null && mounted) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Attachment Exists'),
              content: const Text(
                'Please remove the current attachment before pasting new content.',
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
  }

  Future<void> _handleCopyAll() async {
    final content = _textController.text;
    if (content.isEmpty && mounted) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Nothing to Copy'),
              content: const Text('The text field is empty.'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Copied'),
              content: const Text('Content copied to clipboard.'),
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
  }

  Future<void> _handleOverwriteAll() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    // Use local variable to satisfy analyzer after null check
    final clipboardText = clipboardData?.text;
    if (clipboardText != null) {
      setState(() {
        _textController.text = clipboardText;
      });
      if (!_isExpanded) _expand();
    } else if (mounted) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Clipboard Empty'),
              content: const Text(
                'Cannot replace content, clipboard is empty.',
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
  }

  void _handleRemoveAll() {
    setState(() {
      _textController.clear();
    });
  }

  void _showOverwriteDialog() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Overwrite Content'),
            content: const Text(
              'Replace all current content with clipboard content?',
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _handleOverwriteAll();
                },
                child: const Text('Replace'),
              ),
            ],
          ),
    );
  }

  void _showRemoveAllDialog() {
    if (_textController.text.isEmpty && mounted) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Already Empty'),
              content: const Text('The text field is already empty.'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
      );
      return;
    }

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Remove All Content'),
            content: const Text('Are you sure you want to clear all content?'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  _handleRemoveAll();
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (kDebugMode) {
        print(
          '[CaptureUtility._pickFile] FilePicker result: ${result?.files.firstOrNull}',
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (kDebugMode) {
          print(
            '[CaptureUtility._pickFile] Picked file: name=${file.name}, size=${file.size}, ext=${file.extension}, path=${file.path}, bytes_length=${file.bytes?.length}',
          );
        }

        const maxSizeInBytes = 10 * 1024 * 1024;
        if (file.size > maxSizeInBytes) {
          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder:
                  (context) => CupertinoAlertDialog(
                    title: const Text('File Too Large'),
                    content: const Text('Maximum file size is 10MB.'),
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

        final guessedContentType =
            file.extension != null
                ? _guessContentTypeFromExtension(file.extension!)
                : 'application/octet-stream';
        if (kDebugMode) {
          print(
            '[CaptureUtility._pickFile] Guessed content type: $guessedContentType',
          );
        }

        setState(() {
          _selectedFileData = file.bytes;
          _selectedFilename = file.name;
          _selectedContentType = guessedContentType;
          // Reset submit action if an attachment is added
          if (_submitAction != SubmitAction.newComment) {
            _submitAction = SubmitAction.newComment;
            // Optionally show a notification here
          }
        });
        if (!_isExpanded) _expand();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[CaptureUtility._pickFile] Error picking file: $e\n$stackTrace');
      }
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error Picking File'),
                content: Text(e.toString()),
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
    }
  }

  String _guessContentTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'txt':
        return 'text/plain';
      case 'pdf':
        return 'application/pdf';
      case 'md':
        return 'text/markdown';
      default:
        return 'application/octet-stream';
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedFileData = null;
      _selectedFilename = null;
      _selectedContentType = null;
    });
  }

  Future<void> _handleSubmit() async {
    // Ensure we have a serverId before proceeding
    if (_effectiveServerId == null) {
      if (kDebugMode)
        print(
          '[CaptureUtility._handleSubmit] Aborting: No effective server ID.',
        );
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: const Text(
                  'Cannot submit: No server context found. Please configure a Note server in Settings.',
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
    // final targetServerId = _effectiveServerId!; // Use non-null serverId (already checked)

    final content = _textController.text.trim();
    final hasAttachment = _selectedFileData != null;

    if (kDebugMode)
      print(
        '[CaptureUtility._handleSubmit] Submitting: mode=${widget.mode}, serverId=$_effectiveServerId, action=$_submitAction, content_empty=${content.isEmpty}, filename=$_selectedFilename, contentType=$_selectedContentType, data_length=${_selectedFileData?.length}',
      );

    if (content.isEmpty &&
        _selectedFileData == null &&
        _submitAction == SubmitAction.newComment) {
      if (kDebugMode)
        print(
          '[CaptureUtility._handleSubmit] Aborting: No content or attachment for new comment/memo.',
        );
      return;
    }
    if (content.isEmpty &&
        (_submitAction == SubmitAction.appendToLastComment ||
            _submitAction == SubmitAction.prependToLastComment ||
            _submitAction == SubmitAction.appendToMemo ||
            _submitAction == SubmitAction.prependToMemo)) {
      if (kDebugMode)
        print(
          '[CaptureUtility._handleSubmit] Aborting: No content provided for append/prepend action.',
        );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    NoteItem? updatedMemoResult;
    try {
      if (widget.mode == CaptureMode.createMemo) {
        final newNote = NoteItem(
          id: 'temp',
          content: content,
          visibility: NoteVisibility.public,
          pinned: false,
          state: NoteState.normal,
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
          displayTime: DateTime.now(),
          tags: [],
          resources: [],
          relations: [],
          creatorId: '1',
          parentId: null,
        );
        await createNote(newNote); // Pass targetServerId removed
      } else if (widget.mode == CaptureMode.addComment &&
          widget.memoId != null) {
        final noteId = widget.memoId!;
        final currentContent = _textController.text.trim();
        // Use non-family provider
        final commentsAsync = ref.read(
          note_providers.noteCommentsProvider(noteId),
        );
        final comments = commentsAsync.valueOrNull ?? [];
        comments.sort((a, b) => a.createdTs.compareTo(b.createdTs));
        final lastComment = comments.isNotEmpty ? comments.last : null;
        // Use non-family provider
        final memoAsync = ref.read(
          note_providers.noteDetailProvider(noteId),
        );
        final parentNote = memoAsync.valueOrNull;
        final currentAction =
            hasAttachment ? SubmitAction.newComment : _submitAction;

        switch (currentAction) {
          case SubmitAction.newComment:
            await addComment(
              currentContent,
              noteId,
              // targetServerId removed
              fileBytes: _selectedFileData,
              filename: _selectedFilename,
              contentType: _selectedContentType,
            );
            // Use non-family provider
            ref.invalidate(
              note_providers.noteDetailProvider(noteId),
            );
            break;
          case SubmitAction.appendToLastComment:
            if (lastComment != null) {
              final lastContent = lastComment.content ?? '';
              final updatedContent = "$lastContent\n\n$currentContent";
              // Use non-family provider
              await ref.read(
                comment_providers.updateCommentProvider((
                  memoId: noteId,
                  commentId: lastComment.id,
                )),
              )(updatedContent);
              // Use non-family provider
              ref.invalidate(
                note_providers.noteDetailProvider(noteId),
              );
            } else
              throw Exception("Cannot append: No last comment found.");
            break;
          case SubmitAction.prependToLastComment:
            if (lastComment != null) {
              final lastContent = lastComment.content ?? '';
              final updatedContent = "$currentContent\n\n$lastContent";
              // Use non-family provider
              await ref.read(
                comment_providers.updateCommentProvider((
                  memoId: noteId,
                  commentId: lastComment.id,
                )),
              )(updatedContent);
              // Use non-family provider
              ref.invalidate(
                note_providers.noteDetailProvider(noteId),
              );
            } else
              throw Exception("Cannot prepend: No last comment found.");
            break;
          case SubmitAction.appendToMemo:
          case SubmitAction.prependToMemo:
            if (parentNote != null) {
              final updatedContent =
                  (currentAction == SubmitAction.appendToMemo)
                      ? "${parentNote.content}\n\n$currentContent"
                      : "$currentContent\n\n${parentNote.content}";
              final updatedNoteData = parentNote.copyWith(
                content: updatedContent,
                updateTime: DateTime.now(),
              );
              // Use non-family provider
              updatedMemoResult = await ref.read(
                note_providers.updateNoteProvider(noteId),
              )(updatedNoteData);
              if (ref.exists(note_providers.noteDetailCacheProvider)) {
                ref
                    .read(note_providers.noteDetailCacheProvider.notifier)
                    .update((state) => {...state, noteId: updatedMemoResult!});
                if (kDebugMode)
                  print(
                    '[CaptureUtility] Manually updated noteDetailCacheProvider for $noteId',
                  );
              }
              // Use non-family provider
              // ignore: unused_result
              ref.refresh(
                note_providers.noteDetailProvider(noteId).future,
              );
              // ignore: unused_result
              ref.refresh(
                note_providers.notesNotifierProvider,
              ); // Refresh the main list
              if (kDebugMode)
                print(
                  '[CaptureUtility] Explicitly refreshed providers for $noteId on server $_effectiveServerId',
                );
            } else
              throw Exception(
                "Cannot ${currentAction == SubmitAction.appendToMemo ? 'append' : 'prepend'}: Parent note not loaded or available.",
              );
            break;
        }
      }

      if (mounted) {
        setState(() {
          _textController.clear();
          _removeAttachment();
          _submitAction = SubmitAction.newComment;
          _isSubmitting = false;
        });
        _collapse();
      }
    } catch (e, stackTrace) {
      if (kDebugMode)
        print('[CaptureUtility._handleSubmit] Error: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Submission Error'),
                content: Text('Failed to submit: ${e.toString()}'),
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
    }
  }

  KeyEventResult handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_isExpanded) {
          _collapse();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter &&
          (HardwareKeyboard.instance.isMetaPressed ||
              HardwareKeyboard.instance.isControlPressed)) {
        if (_isExpanded && !_isSubmitting) {
          _handleSubmit();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void showOverflowActionSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('More Options'),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                child: const Text('Paste'),
                onPressed: () {
                  Navigator.pop(context);
                  _handlePaste();
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Copy All'),
                onPressed: () {
                  Navigator.pop(context);
                  _handleCopyAll();
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Overwrite All'),
                onPressed: () {
                  Navigator.pop(context);
                  _showOverwriteDialog();
                },
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('Remove All'),
                onPressed: () {
                  Navigator.pop(context);
                  _showRemoveAllDialog();
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  Widget buildExpandedContent(String hintText, String buttonText) {
    // This Column contains the text field, attachment preview, and buttons.
    // It should fit within the parent Expanded widget.
    return Column(
      // Use max to allow the Expanded child to fill space
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TextField should expand to fill available space
        Expanded(
          child: KeyboardListener(
            focusNode:
                FocusNode(), // Use a dedicated node if needed for specific key handling here
            onKeyEvent: handleKeyEvent,
            child: CupertinoTextField(
              controller: _textController,
              focusNode: _focusNode,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: CupertinoColors.label.resolveFrom(context),
                fontFamily: 'Menlo, Monaco, Consolas, "Courier New", monospace',
              ),
              placeholder: hintText,
              placeholderStyle: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 16,
              ),
              decoration: const BoxDecoration(
                color: CupertinoColors.transparent,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              cursorColor: CupertinoTheme.of(context).primaryColor,
              cursorWidth: 2,
              maxLines: null, // Allows internal scrolling
              minLines: null, // Allows internal scrolling
              expands: true, // Make TextField fill the Expanded space
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              onTap: () {
                if (!_isExpanded) _expand();
              },
            ),
          ),
        ),
        // Attachment preview (conditionally shown)
        if (_selectedFileData != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: 8.0,
              bottom: 4.0,
              left: 4.0,
              right: 4.0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  if (_selectedContentType?.startsWith('image/') == true)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.memory(
                        _selectedFileData!,
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              CupertinoIcons.exclamationmark_circle,
                              size: 30,
                            ),
                      ),
                    )
                  else
                    Icon(
                      CupertinoIcons.doc_fill,
                      size: 24,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFilename ?? 'Attached File',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: _removeAttachment,
                    child: Icon(
                      CupertinoIcons.clear_circled_solid,
                      size: 18,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        // Bottom row with buttons (fixed height)
        SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 40,
                    onPressed: showOverflowActionSheet,
                    child: Icon(
                      CupertinoIcons.ellipsis_circle,
                      size: 20,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 40,
                    onPressed: _pickFile,
                    child: Icon(
                      CupertinoIcons.paperclip,
                      size: 20,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(10.0),
                borderRadius: BorderRadius.circular(24),
                color:
                    _isSubmitting
                        ? CupertinoTheme.of(context).primaryColor.withAlpha(179)
                        : CupertinoTheme.of(context).primaryColor,
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      _isSubmitting
                          ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                            radius: 10,
                          )
                          : const Icon(
                            CupertinoIcons.arrow_up,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCollapsedContent(String placeholderText) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            placeholderText,
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.placeholderText.resolveFrom(context),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.add_circled,
            size: 16,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final edgeInsets = MediaQuery.of(context).padding;

    ref.listen<bool>(ui_providers.captureUtilityToggleProvider, (
      previous,
      current,
    ) {
      if (previous != current && mounted) {
        if (kDebugMode)
          print(
            '[CaptureUtility] Received toggle signal. Current state expanded: $_isExpanded',
          );
        _toggleExpansionState();
      }
    });

    final hintText =
        widget.hintText ??
        (widget.mode == CaptureMode.createMemo
            ? 'Type or paste memo content...'
            : 'Add a comment...');
    final buttonText =
        widget.buttonText ??
        (widget.mode == CaptureMode.createMemo ? 'Add Memo' : 'Add Comment');
    final placeholderText =
        widget.mode == CaptureMode.createMemo
            ? 'Capture something...'
            : 'Add a comment...';

    // Use non-family provider
    final commentsAsync =
        widget.mode == CaptureMode.addComment &&
                widget.memoId != null &&
                _effectiveServerId != null
            ? ref.watch(
              note_providers.noteCommentsProvider(widget.memoId!),
            )
            : const AsyncValue.data(<Comment>[]);
    final bool hasComments = commentsAsync.maybeWhen(
      data: (comments) => comments.isNotEmpty,
      orElse: () => false,
    );
    final bool hasAttachment = _selectedFileData != null;

    // Use non-family provider
    final parentMemoAsyncValue =
        widget.mode == CaptureMode.addComment &&
                widget.memoId != null &&
                _effectiveServerId != null
            ? ref.watch(
              note_providers.noteDetailProvider(widget.memoId!),
            )
            : const AsyncValue.data(null);
    final bool isParentMemoLoaded =
        parentMemoAsyncValue.hasValue && parentMemoAsyncValue.value != null;
    final bool canAppendPrependComment = hasComments && !hasAttachment;
    final bool canAppendPrependMemo = isParentMemoLoaded && !hasAttachment;
    final Map<SubmitAction, Widget> segmentedControlChildren = {
      SubmitAction.newComment: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text('New 💬'),
      ),
      SubmitAction.appendToLastComment: Opacity(
        opacity: canAppendPrependComment ? 1.0 : 0.5,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('Append 💬'),
        ),
      ),
      SubmitAction.prependToLastComment: Opacity(
        opacity: canAppendPrependComment ? 1.0 : 0.5,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('Prepend 💬'),
        ),
      ),
      SubmitAction.appendToMemo: Opacity(
        opacity: canAppendPrependMemo ? 1.0 : 0.5,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('Append 📝'),
        ),
      ),
      SubmitAction.prependToMemo: Opacity(
        opacity: canAppendPrependMemo ? 1.0 : 0.5,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('Prepend 📝'),
        ),
      ),
    };

    _updateHeights(context);

    double containerWidth;
    if (size.width > 1400)
      containerWidth = math.min(size.width * 0.6, 1000);
    else if (size.width > 800)
      containerWidth = math.max(size.width * 0.7, 500);
    else {
      final availableWidth =
          size.width - edgeInsets.left - edgeInsets.right - 32;
      containerWidth = availableWidth > 0 ? availableWidth : size.width * 0.85;
    }
    containerWidth = math.max(containerWidth, 320);

    final frameHeight = _currentHeight.clamp(_collapsedHeight, _expandedHeight);
    final bool showExpandedContent =
        _isExpanded || _animationController.value > 0.1;

    final backgroundColor =
        isDarkMode ? const Color(0xFF232323) : const Color(0xFFF0F0F0);
    final borderColor =
        isDarkMode ? CupertinoColors.systemGrey3 : CupertinoColors.systemGrey4;

    return SafeArea(
      bottom: true,
      minimum: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 0 : 8),
        child: GestureDetector(
          onVerticalDragStart: _handleDragStart,
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          onTap: () {
            if (!_isExpanded) _expand();
          },
          child: Container(
            width: containerWidth,
            height: frameHeight,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: borderColor.resolveFrom(context),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withAlpha(isDarkMode ? 77 : 26),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: CupertinoColors.black.withAlpha(13),
                  blurRadius: 1,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Drag handle
                  Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.inactiveGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Content area with scrolling
                  Expanded(
                    child:
                        showExpandedContent
                            ? SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width > 1200
                                          ? 36
                                          : 24,
                                  vertical:
                                      MediaQuery.of(context).size.width > 1200
                                          ? 12
                                          : 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Segmented control (conditionally shown)
                                  if (widget.mode == CaptureMode.addComment)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: CupertinoSegmentedControl<
                                          SubmitAction
                                        >(
                                          children: segmentedControlChildren,
                                          groupValue: _submitAction,
                                          onValueChanged: (
                                            SubmitAction newValue,
                                          ) {
                                            bool allowed = false;
                                            switch (newValue) {
                                              case SubmitAction.newComment:
                                                allowed = true;
                                                break;
                                              case SubmitAction
                                                  .appendToLastComment:
                                              case SubmitAction
                                                  .prependToLastComment:
                                                allowed =
                                                    canAppendPrependComment;
                                                break;
                                              case SubmitAction.appendToMemo:
                                              case SubmitAction.prependToMemo:
                                                allowed = canAppendPrependMemo;
                                                break;
                                            }
                                            if (allowed)
                                              setState(() {
                                                _submitAction = newValue;
                                              });
                                            else if (kDebugMode)
                                              print(
                                                "[CaptureUtility] Action '$newValue' disallowed.",
                                              );
                                          },
                                          borderColor: CupertinoColors
                                              .systemGrey
                                              .resolveFrom(context),
                                          selectedColor:
                                              CupertinoTheme.of(
                                                context,
                                              ).primaryColor,
                                          unselectedColor:
                                              CupertinoColors.transparent,
                                          pressedColor: CupertinoTheme.of(
                                            context,
                                          ).primaryColor.withAlpha(51),
                                        ),
                                      ),
                                    ),
                                  
                                    // Text input field (NOT in an Expanded)
                                    KeyboardListener(
                                      focusNode: FocusNode(),
                                      onKeyEvent: handleKeyEvent,
                                      child: Container(
                                        constraints: BoxConstraints(
                                          minHeight: 100,
                                          maxHeight: _expandedHeight - 120,
                                        ),
                                        child: CupertinoTextField(
                                          controller: _textController,
                                          focusNode: _focusNode,
                                          style: TextStyle(
                                            fontSize: 16,
                                            height: 1.4,
                                            color: CupertinoColors.label
                                                .resolveFrom(context),
                                            fontFamily:
                                                'Menlo, Monaco, Consolas, "Courier New", monospace',
                                          ),
                                          placeholder: hintText,
                                          placeholderStyle: TextStyle(
                                            color: CupertinoColors
                                                .placeholderText
                                                .resolveFrom(context),
                                            fontSize: 16,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: CupertinoColors.transparent,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          cursorColor:
                                              CupertinoTheme.of(
                                                context,
                                              ).primaryColor,
                                          cursorWidth: 2,
                                          maxLines: null,
                                          minLines: 5,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          keyboardType: TextInputType.multiline,
                                          onTap: () {
                                            if (!_isExpanded) _expand();
                                          },
                                        ),
                                      ),
                                    ),

                                    // Attachment preview (conditionally shown)
                                    if (_selectedFileData != null)
                                      Container(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                          bottom: 4.0,
                                          left: 4.0,
                                          right: 4.0,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                            vertical: 4.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.systemGrey5
                                                .resolveFrom(context),
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              if (_selectedContentType
                                                      ?.startsWith('image/') ==
                                                  true)
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        4.0,
                                                      ),
                                                  child: Image.memory(
                                                    _selectedFileData!,
                                                    width: 30,
                                                    height: 30,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => const Icon(
                                                          CupertinoIcons
                                                              .exclamationmark_circle,
                                                          size: 30,
                                                        ),
                                                  ),
                                                )
                                              else
                                                Icon(
                                                  CupertinoIcons.doc_fill,
                                                  size: 24,
                                                  color: CupertinoColors
                                                      .secondaryLabel
                                                      .resolveFrom(context),
                                                ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _selectedFilename ??
                                                      'Attached File',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: CupertinoColors.label
                                                        .resolveFrom(context),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              CupertinoButton(
                                                padding: EdgeInsets.zero,
                                                minSize: 0,
                                                onPressed: _removeAttachment,
                                                child: Icon(
                                                  CupertinoIcons
                                                      .clear_circled_solid,
                                                  size: 18,
                                                  color: CupertinoColors
                                                      .secondaryLabel
                                                      .resolveFrom(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Bottom row with buttons
                                    Container(
                                      height: 44,
                                      margin: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CupertinoButton(
                                                padding: EdgeInsets.zero,
                                                minSize: 40,
                                                onPressed:
                                                    showOverflowActionSheet,
                                                child: Icon(
                                                  CupertinoIcons
                                                      .ellipsis_circle,
                                                  size: 20,
                                                  color: CupertinoColors
                                                      .secondaryLabel
                                                      .resolveFrom(context),
                                                ),
                                              ),
                                              CupertinoButton(
                                                padding: EdgeInsets.zero,
                                                minSize: 40,
                                                onPressed: _pickFile,
                                                child: Icon(
                                                  CupertinoIcons.paperclip,
                                                  size: 20,
                                                  color: CupertinoColors
                                                      .secondaryLabel
                                                      .resolveFrom(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                          CupertinoButton(
                                            padding: const EdgeInsets.all(10.0),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            color:
                                                _isSubmitting
                                                    ? CupertinoTheme.of(context)
                                                        .primaryColor
                                                        .withAlpha(179)
                                                    : CupertinoTheme.of(
                                                      context,
                                                    ).primaryColor,
                                            onPressed:
                                                _isSubmitting
                                                    ? null
                                                    : _handleSubmit,
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  _isSubmitting
                                                      ? const CupertinoActivityIndicator(
                                                        color:
                                                            CupertinoColors
                                                                .white,
                                                        radius: 10,
                                                      )
                                                      : const Icon(
                                                        CupertinoIcons.arrow_up,
                                                        color:
                                                            CupertinoColors
                                                                .white,
                                                        size: 20,
                                                      ),
                                            ),
                                          ),
                                        ],
                                    ),
                                  ),
                                ],
                                ),
                              ),
                            )
                            : Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width > 1200
                                        ? 36
                                        : 24,
                                vertical:
                                    MediaQuery.of(context).size.width > 1200
                                        ? 12
                                        : 8,
                              ),
                              child: buildCollapsedContent(placeholderText),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
