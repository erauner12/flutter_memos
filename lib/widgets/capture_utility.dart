import 'dart:ui' show lerpDouble; // Import lerpDouble

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart';
import 'package:flutter_memos/screens/new_memo/new_memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CaptureMode { createMemo, addComment }

class CaptureUtility extends ConsumerStatefulWidget {
  final CaptureMode mode;
  final String? memoId;
  final String? hintText;
  final String? buttonText;

  const CaptureUtility({
    super.key,
    this.mode = CaptureMode.createMemo,
    this.memoId,
    this.hintText,
    this.buttonText,
  });

  @override
  ConsumerState<CaptureUtility> createState() => _CaptureUtilityState();
}

class _CaptureUtilityState extends ConsumerState<CaptureUtility>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  // Animation controller for smooth transitions
  late AnimationController _animationController;

  // Track if user is currently dragging
  bool _isDragging = false;

  // Define min/max heights for the utility
  final double _collapsedHeight = 60.0; // Slightly smaller for a cleaner look
  final double _expandedHeight = 240.0; // Increased for more text space
  double _currentHeight = 60.0;

  // Define spring properties (adjust values for desired feel)
  static const SpringDescription _springDescription = SpringDescription(
    mass: 1.0,
    stiffness: 100.0,
    damping: 15.0,
  );

  @override
  void initState() {
    super.initState();
    _currentHeight = _collapsedHeight;

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
    // Slightly lower velocity threshold for manual interaction sensitivity
    const velocityThreshold = 0.4; // Lowered from 0.5
    const positionThreshold = 0.5;

    if (simulationVelocity.abs() > velocityThreshold) {
      // Corrected logic:
      // Positive simulationVelocity (upward swipe) -> target 1.0 (expand)
      // Negative simulationVelocity (downward swipe) -> target 0.0 (collapse)
      targetValue = simulationVelocity > 0 ? 1.0 : 0.0;
    } else {
      targetValue = currentFraction > positionThreshold ? 1.0 : 0.0;
    }

    // Check if close to target and velocity is low to snap directly
    if ((targetValue - currentFraction).abs() < 0.05 &&
        simulationVelocity.abs() < velocityThreshold / 2) {
      // Ensure state is updated correctly when snapping
      setState(() {
        _currentHeight =
            targetValue == 1.0 ? _expandedHeight : _collapsedHeight;
        // Manually set controller value to ensure consistency
        _animationController.value = targetValue;
      });
    } else {
      _animateTo(targetValue, velocity: simulationVelocity);
    }
  }

  void _handleDragStart(DragStartDetails details) {
    // Ensure controller stops *before* setting dragging state
    _animationController.stop();
    setState(() {
      _isDragging = true;
    });
  }

  Future<void> _handlePaste() async {
    ClipboardData? clipboardData = await Clipboard.getData(
      Clipboard.kTextPlain,
    );
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _textController.text = clipboardData.text!;
      });
      if (!_isExpanded) {
        _expand();
      }
    }
  }

  Future<void> _handleCopyAll() async {
    final content = _textController.text;
    if (content.isEmpty) {
      // Show a snackbar indicating there's nothing to copy
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

  void _handleOverwriteAll([String newContent = '']) {
    setState(() {
      _textController.text = newContent;
    });
    if (newContent.isNotEmpty && !_isExpanded) {
      _expand();
    }
  }

  void _handleRemoveAll() {
    setState(() {
      _textController.clear();
    });
  }

  Future<void> _handleSubmit() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.mode == CaptureMode.createMemo) {
        await _createMemo(content);
      } else if (widget.mode == CaptureMode.addComment &&
          widget.memoId != null) {
        await _addComment(content, widget.memoId!);
      }

      setState(() {
        _textController.clear();
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
    await ref.read(createMemoProvider)(newMemo);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo created successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addComment(String content, String memoId) async {
    final newComment = Comment(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      creatorId: '1',
      createTime: DateTime.now().millisecondsSinceEpoch,
    );

    await ref.read(addCommentProvider(memoId))(newComment);

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
    // Use KeyEvent
    if (event is KeyDownEvent) {
      // Use KeyDownEvent
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_isExpanded) {
          _collapse();
          return KeyEventResult.handled; // Handled Escape
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter &&
          (HardwareKeyboard.instance.isMetaPressed ||
              HardwareKeyboard.instance.isControlPressed)) {
        // Check for Cmd or Ctrl
        // Use HardwareKeyboard.instance.isMetaPressed or isControlPressed for cross-platform compatibility
        if (_isExpanded && !_isSubmitting) {
          _handleSubmit();
          return KeyEventResult.handled; // Handled Cmd/Ctrl+Enter
        }
      }
    }
    return KeyEventResult.ignored; // Ignore other keys
  }

  Widget _buildOverflowMenuButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<int>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
      ),
      tooltip: 'More options',
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            // Show dialog to confirm overwrite
            _showOverwriteDialog();
            break;
          case 3:
            // Show dialog to confirm remove all
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
    );
  }

  void _showOverwriteDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Overwrite Content'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('This will replace all current content. Continue?'),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter new content here',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    _handleOverwriteAll(value);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Simple implementation to clear first, then close dialog
                  // (User needs to add new content after)
                  _handleRemoveAll();
                  Navigator.pop(context);
                },
                child: const Text('Clear & Continue'),
              ),
            ],
          ),
    );
  }

  void _showRemoveAllDialog() {
    if (_textController.text.isEmpty) {
      // If already empty, just show a message
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final edgeInsets = MediaQuery.of(context).padding;

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
    if (size.width > 800) {
      containerWidth = 450; // Slightly wider for better aesthetics
    } else {
      final availableWidth =
          size.width - edgeInsets.left - edgeInsets.right - 32;
      containerWidth = availableWidth > 0 ? availableWidth : size.width * 0.85;
    }

    final frameHeight = _currentHeight.clamp(_collapsedHeight, _expandedHeight);
    final bool showExpandedContent =
        _isExpanded || _animationController.value > 0.1;

    return SafeArea(
      bottom: true,
      minimum: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 0 : 8),
        child: GestureDetector(
          // Keep swipe gestures as an alternative interaction method
          onVerticalDragStart: _handleDragStart,
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          // Changed to focus on the text field instead of expanding directly
          onTap: () {
            _focusNode.requestFocus();
          },
          child: Container(
            width: containerWidth,
            height: frameHeight,
            decoration: BoxDecoration(
              // Modern styling with cleaner look
              color:
                  isDarkMode
                      ? Colors.grey[850]?.withValues(
                        alpha: 242,
                      ) // 0.95 * 255 = 242
                      : Colors.white.withValues(alpha: 250), // 0.98 * 255 = 250
              // Increased corner radius for modern look
              borderRadius: BorderRadius.circular(20),
              // Removed border for cleaner appearance
              // Subtle shadow for depth
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 38 : 20,
                  ), // 0.15 * 255 = 38, 0.08 * 255 = 20
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                child: Focus(
                  focusNode: _focusNode,
                  onFocusChange: (hasFocus) {
                    // Auto-expand when focused
                    if (hasFocus && !_isExpanded) {
                      _expand();
                    }
                  },
                  onKeyEvent: (node, event) {
                    return _handleKeyEvent(event);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Drag indicator
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(top: 6, bottom: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha((255 * 0.5).round()),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Main content area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
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
      ),
    );
  }

  // New method for building the expanded content
  Widget _buildExpandedContent(String hintText, String buttonText) {
    return Column(
      children: [
        // Text field that grows until maxLines, then scrolls
        Expanded(
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            ),
            maxLines: 6, // Cap at 6 lines, then scroll
            minLines: 1, // Start with 1 line
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
          ),
        ),

        // Actions row
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Now the overflow menu comes first (left)
              _buildOverflowMenuButton(),
              const SizedBox(width: 8),
              // Submit button on the right
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(buttonText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // New method for building collapsed content
  Widget _buildCollapsedContent(String placeholderText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Text/placeholder area
        Expanded(
          child: GestureDetector(
            onTap: () {
              _focusNode.requestFocus();
            },
            child: Text(
              placeholderText,
              style: TextStyle(
                fontSize: 16,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Expand indicator button
        IconButton(
          icon: const Icon(Icons.expand_less, size: 20),
          tooltip: 'Expand',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          splashRadius: 20,
          onPressed: () {
            _expand();
          },
        ),
      ],
    );
  }
}
