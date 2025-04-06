import 'dart:math' as math;
import 'dart:ui' show lerpDouble; // Import lerpDouble

import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart'; // Import for SpringSimulation
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/comment_providers.dart'
    as comment_providers; // Add import for comment_providers
import 'package:flutter_memos/providers/memo_providers.dart' as memo_providers;
import 'package:flutter_memos/providers/ui_providers.dart'
    as ui_providers; // Ensure this import exists
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
enum CaptureMode { createMemo, addComment }

// Add this typedef to expose the private state class type
typedef CaptureUtilityState = _CaptureUtilityState;

class CaptureUtility extends ConsumerStatefulWidget {
  // Add a static key for finding this widget in tests
  static final captureUtilityKey = GlobalKey<_CaptureUtilityState>();
  
  final CaptureMode mode;
  final String? memoId;
  final String? hintText;
  final String? buttonText;
  final bool isTestMode;

  const CaptureUtility({
    super.key,
    this.mode = CaptureMode.createMemo,
    this.memoId,
    this.hintText,
    this.buttonText,
    this.isTestMode = false,
  });
  
  /// Test helper method to programmatically set file data
  static void setTestFileData(
    Uint8List fileData,
    String filename,
    String contentType,
  ) {
    final state = captureUtilityKey.currentState;
    if (state != null) {
      state.setFileDataForTest(fileData, filename, contentType);
    } else {
      debugPrint(
        '[CaptureUtility] Error: Cannot set test data - widget not found',
      );
    }
  }

  @override
  ConsumerState<CaptureUtility> createState() => _CaptureUtilityState();
}

class _CaptureUtilityState extends ConsumerState<CaptureUtility>
    with SingleTickerProviderStateMixin {
  
  /// Test helper method to set file data programmatically
  // Making this method public to allow direct access from tests
  void setFileDataForTest(
    Uint8List fileData,
    String filename,
    String contentType,
  ) {
    if (kDebugMode) {
      print(
        '[CaptureUtility] Setting test file data: $filename ($contentType)',
      );
    }
    setState(() {
      _selectedFileData = fileData;
      _selectedFilename = filename;
      _selectedContentType = contentType;

      if (!_isExpanded) {
        _expand();
      }
    });
  }
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  Uint8List? _selectedFileData;
  String? _selectedFilename;
  String? _selectedContentType;

  // Animation controller for smooth transitions
  late AnimationController _animationController;

  // Track if user is currently dragging
  bool _isDragging = false;

  // Define min/max heights for the utility - removed 'late' to prevent initialization errors
  double _collapsedHeight = 60.0; // Default value
  double _expandedHeight = 240.0; // Default value
  double _currentHeight = 60.0; // Default value

  // Helper to calculate dynamic heights based on screen size
  void _updateHeights(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // More proportional heights for different screen sizes
    double newCollapsedHeight;
    double newExpandedHeight;

    if (size.width > 1400) {
      newCollapsedHeight = 70.0; // Slightly taller for very large screens
      newExpandedHeight = 280.0; // Taller expanded view for large screens
    } else {
      newCollapsedHeight = 60.0; // Standard height for normal screens
      newExpandedHeight = 240.0; // Standard expanded height
    }

    // Only update state if values have changed
    if (newCollapsedHeight != _collapsedHeight ||
        newExpandedHeight != _expandedHeight) {
      setState(() {
        _collapsedHeight = newCollapsedHeight;
        _expandedHeight = newExpandedHeight;

        // If we're collapsed, update current height
        if (!_isExpanded) {
          _currentHeight = _collapsedHeight;
        }
      });
    }
  }

  // Define spring properties (adjust values for desired feel)
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
    );

    _animationController.addListener(() {
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update heights based on screen size
    _updateHeights(context);
  }

  // Helper method to start physics-based animation
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
      // Ensure final state consistency only if not dragging and component is still mounted
      if (!_isDragging && mounted) {
        setState(() {
          _currentHeight =
              targetValue == 1.0 ? _expandedHeight : _collapsedHeight;
          // Ensure controller value matches target precisely at the end
          if ((_animationController.value - targetValue).abs() > 0.01) {
            _animationController.value = targetValue;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
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

  // Helper method to toggle expansion state
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
      // Update controller value proportionally during drag
      _animationController.value =
          (_currentHeight - _collapsedHeight) /
          (_expandedHeight - _collapsedHeight);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return; // Should not happen, but safety first

    final dragVelocity = details.primaryVelocity ?? 0.0;
    final simulationVelocity =
        -dragVelocity / (_expandedHeight - _collapsedHeight);
    final currentFraction = _animationController.value;

    _isDragging = false; // Set dragging to false *after* calculations

    double targetValue;
    const velocityThreshold = 0.4; // Lowered from 0.5
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
    // Check for text first (append to existing text)
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
              : currentText + clipboardTextData.text!; // Append if no selection
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset:
              (cursorPosition >= 0 ? cursorPosition : currentText.length) +
              clipboardTextData.text!.length,
        ),
      );
      if (!_isExpanded) {
        _expand();
      }
    }
    
    // Note: For image pasting, Flutter's standard Clipboard API doesn't
    // support binary data. To add image clipboard support, you would need
    // to implement a platform-specific solution using plugins or channels.
    
    // If we already have a file selected, notify the user
    if (_selectedFileData != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Remove existing attachment before pasting new content',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleCopyAll() async {
    final content = _textController.text;
    if (content.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nothing to copy'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleOverwriteAll() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _textController.text = clipboardData.text!;
      });

      if (!_isExpanded) {
        _expand();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content replaced with clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleRemoveAll() {
    setState(() {
      _textController.clear();
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Or FileType.image, etc.
        withData: true, // Explicitly request bytes
      );
      // Add detailed logging here
      if (kDebugMode) {
        print(
          '[CaptureUtility._pickFile] FilePicker result: ${result?.files.firstOrNull}',
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        // Add detailed logging for the picked file
        if (kDebugMode) {
          print(
            '[CaptureUtility._pickFile] Picked file: name=${file.name}, size=${file.size}, ext=${file.extension}, path=${file.path}, bytes_length=${file.bytes?.length}',
          );
        }

        const maxSizeInBytes = 10 * 1024 * 1024;
        if (file.size > maxSizeInBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File is too large (max 10MB)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Log guessed content type
        final guessedContentType =
            file.extension != null
                ? _guessContentTypeFromExtension(file.extension!)
                : 'application/octet-stream';
        if (kDebugMode) {
          print(
            '[CaptureUtility._pickFile] Guessed content type: $guessedContentType',
          );
          print('[CaptureUtility._pickFile] Attempting to set state...');
        }

        setState(() {
          _selectedFileData = file.bytes;
          _selectedFilename = file.name;
          _selectedContentType = guessedContentType;
          // Log state values after setting them
          if (kDebugMode) {
            print(
              '[CaptureUtility._pickFile] State set: filename=$_selectedFilename, contentType=$_selectedContentType, data_length=${_selectedFileData?.length}',
            );
          }
        });
        if (!_isExpanded) {
          _expand();
        }
      }
    } catch (e, stackTrace) {
      // Enhance logging in catch block
      if (kDebugMode) {
        print('[CaptureUtility._pickFile] Error picking file: $e\n$stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    final content = _textController.text.trim();
    // Add logging here
    if (kDebugMode) {
      print(
        '[CaptureUtility._handleSubmit] Submitting: content_empty=${content.isEmpty}, filename=$_selectedFilename, contentType=$_selectedContentType, data_length=${_selectedFileData?.length}',
      );
    }
    if (content.isEmpty && _selectedFileData == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.mode == CaptureMode.createMemo) {
        // TODO: Add file attachment support for creating memos if needed
        await _createMemo(content);
      } else if (widget.mode == CaptureMode.addComment &&
          widget.memoId != null) {
        // Pass the selected file data to _addComment
        await _addComment(
          content,
          widget.memoId!,
          fileBytes: _selectedFileData, // Pass file bytes
          filename: _selectedFilename, // Pass filename
          contentType: _selectedContentType, // Pass content type
        );
      }

      setState(() {
        _textController.clear();
        _removeAttachment();
        _isSubmitting = false;
      });

      _collapse();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createMemo(String content) async {
    final newMemo = Memo(id: 'temp', content: content, visibility: 'PUBLIC');
    // Add the prefix here
    await ref.read(memo_providers.createMemoProvider)(newMemo);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo created successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addComment(
    String content,
    String memoId, {
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
  }) async {
    // Add logging here
    if (kDebugMode) {
      print(
        '[CaptureUtility._addComment] Adding comment: memoId=$memoId, content_empty=${content.isEmpty}, filename=$filename, contentType=$contentType, data_length=${fileBytes?.length}',
      );
    }

    final newComment = Comment(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      creatorId: '1',
      createTime: DateTime.now().millisecondsSinceEpoch,
    );

    await ref.read(comment_providers.createCommentProvider(memoId))(
      newComment,
      fileBytes: fileBytes,
      filename: filename,
      contentType: contentType,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
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

  Widget _buildOverflowMenuButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 40,
      height: 40,
      child: PopupMenuButton<int>(
        icon: Icon(
          Icons.more_vert,
          size: 20,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
        padding: EdgeInsets.zero,
        tooltip: 'More options',
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        position: PopupMenuPosition.under,
        onSelected: (item) {
          switch (item) {
            case 0:
              _handlePaste();
              break;
            case 1:
              _handleCopyAll();
              break;
            case 2:
              _showOverwriteDialog();
              break;
            case 3:
              _showRemoveAllDialog();
              break;
          }
        },
        itemBuilder:
            (context) => [
              const PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    Icon(Icons.content_paste, size: 18),
                    SizedBox(width: 10),
                    Text('Paste'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.content_copy, size: 18),
                    SizedBox(width: 10),
                    Text('Copy All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 10),
                    Text('Overwrite All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 3,
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18),
                    SizedBox(width: 10),
                    Text('Remove All'),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  void _showOverwriteDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Overwrite Content'),
            content: const Text(
              'Replace all current content with clipboard content?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
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
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text field is already empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove All Content'),
            content: const Text('Are you sure you want to clear all content?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
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

  Widget _buildExpandedContent(String hintText, String buttonText) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: _handleKeyEvent,
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                fontFamily: 'Menlo, Monaco, Consolas, "Courier New", monospace',
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.grey[400]?.withAlpha(204)
                      : Colors.grey[500]?.withAlpha(217),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                isDense: true,
              ),
              cursorColor: Theme.of(context).colorScheme.primary,
              cursorWidth: 2,
              maxLines: 6,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              onTap: () {
                if (!_isExpanded) {
                  _expand();
                }
              },
            ),
          ),
        ),
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
                color: isDarkMode ? Colors.grey[700]?.withAlpha(100) : Colors.grey[200],
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 30),
                      ),
                    )
                  else
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 24,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFilename ?? 'Attached File',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Remove attachment',
                    onPressed: _removeAttachment,
                  ),
                ],
              ),
            ),
          ),
        ],
        SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOverflowMenuButton(),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        size: 20,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      tooltip: 'Attach file',
                      padding: EdgeInsets.zero,
                      onPressed: _pickFile,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSubmitting ? null : _handleSubmit,
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: _isSubmitting
                          ? Theme.of(context).colorScheme.primary.withAlpha(179)
                          : Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedContent(String placeholderText) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            placeholderText,
            style: TextStyle(
              fontSize: 16,
              color:
                  isDarkMode
                      ? Colors.grey[400]?.withAlpha(204)
                      : Colors.grey[500]?.withAlpha(217),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.add_circle_outline,
            size: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final edgeInsets = MediaQuery.of(context).padding;

    // Ensure the prefix and provider name are correct
    ref.listen<bool>(ui_providers.captureUtilityToggleProvider, (
      previous,
      current,
    ) {
      if (previous != current && mounted) {
        if (kDebugMode) {
          print(
            '[CaptureUtility] Received toggle signal. Current state expanded: $_isExpanded',
          );
        }
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

    double containerWidth;

    if (size.width > 1400) {
      containerWidth = math.min(size.width * 0.6, 1000);
    } else if (size.width > 800) {
      containerWidth = math.max(size.width * 0.7, 500);
    } else {
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
            if (!_isExpanded) {
              _expand();
            }
          },
          child: Container(
            width: containerWidth,
            height: frameHeight,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(
                    isDarkMode ? 77 : 26,
                  ),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color:
                      isDarkMode
                          ? Colors.white.withAlpha(5)
                          : Colors.black.withAlpha(5),
                  blurRadius: 1,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withAlpha(102),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              MediaQuery.of(context).size.width > 1200
                                  ? 36
                                  : 24,
                          vertical:
                              MediaQuery.of(context).size.width > 1200 ? 12 : 8,
                        ),
                        child:
                            showExpandedContent
                                ? _buildExpandedContent(hintText, buttonText)
                                : _buildCollapsedContent(placeholderText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
