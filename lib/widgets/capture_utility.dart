import 'dart:math' as math;
import 'dart:ui' show lerpDouble; // Import lerpDouble

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart'; // Import for SpringSimulation
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
  late final double
  _collapsedHeight; // Will be set in initState based on screen size
  late final double
  _expandedHeight; // Will be set in initState based on screen size
  late double _currentHeight; // Will be set in initState

  // Helper to calculate dynamic heights based on screen size
  void _updateHeights(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // More proportional heights for different screen sizes
    if (size.width > 1400) {
      _collapsedHeight = 70.0; // Slightly taller for very large screens
      _expandedHeight = 280.0; // Taller expanded view for large screens
    } else {
      _collapsedHeight = 60.0; // Standard height for normal screens
      _expandedHeight = 240.0; // Standard expanded height
    }

    _currentHeight = _collapsedHeight;
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

    // Set default values - will be properly updated in didChangeDependencies
    _collapsedHeight = 60.0;
    _expandedHeight = 240.0;
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

  Future<void> _handleOverwriteAll() async {
    // Get content from clipboard directly
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content replaced with clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Notify if clipboard is empty
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

    return SizedBox(
      width: 40, // Fixed width for consistent sizing
      height: 40, // Fixed height for consistent sizing
      child: PopupMenuButton<int>(
        icon: Icon(
          Icons.more_vert,
          size: 20,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
        padding: EdgeInsets.zero, // Remove padding to prevent overflow
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
              // Directly overwrite with clipboard
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
      ),
    );
  }

  void _showOverwriteDialog() {
    // Show confirmation dialog
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

  // New method for building the expanded content
  Widget _buildExpandedContent(String hintText, String buttonText) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min, // Prevent overflow issues
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text field that grows until maxLines, then scrolls
        Expanded(
          child: KeyboardListener(
            focusNode:
                FocusNode(), // Using a separate focus node for the listener
            onKeyEvent: _handleKeyEvent,
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: TextStyle(
                fontSize: 16,
                height: 1.4, // Slightly more line height
                color:
                    isDarkMode
                        ? Colors.grey[200] // Brighter text in dark mode
                        : Colors.grey[800], // Darker text in light mode
                fontFamily:
                    'Menlo, Monaco, Consolas, "Courier New", monospace', // Terminal-like font
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color:
                      isDarkMode
                          ? Colors.grey[400]?.withAlpha(204) // 0.8 * 255 = 204
                          : Colors.grey[500]?.withAlpha(
                            217,
                          ), // 0.85 * 255 = 217
                  fontSize: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                ), // Add vertical padding
                isDense: true,
              ),
              cursorColor: Theme.of(context).colorScheme.primary,
              cursorWidth: 2,
              maxLines: 6, // Cap at 6 lines, then scroll
              minLines: 1, // Start with 1 line
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

        // Actions row - simplified for better layout
        SizedBox(
          height: 44, // Fixed height to prevent layout shifts
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Overflow menu on the left
              _buildOverflowMenuButton(),

              // Submit button as an icon on the right
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSubmitting ? null : _handleSubmit,
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    decoration: BoxDecoration(
                      color:
                          _isSubmitting
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(
                                179,
                              ) // 0.7 * 255 = 179
                              : Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(
                        10.0,
                      ), // Slightly smaller to prevent overflow
                      width: 40, // Fixed width
                      height: 40, // Fixed height
                      alignment: Alignment.center,
                      child:
                          _isSubmitting
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

  // New method for building collapsed content with centered elements
  Widget _buildCollapsedContent(String placeholderText) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Center text and add + button
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min, // This makes the row wrap its content
        mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
        children: [
          // Text/placeholder area
          Text(
            placeholderText,
            style: TextStyle(
              fontSize: 16,
              color:
                  isDarkMode
                      ? Colors.grey[400]?.withAlpha(204) // 0.8 * 255 = 204
                      : Colors.grey[500]?.withAlpha(217), // 0.85 * 255 = 217
            ),
            overflow: TextOverflow.ellipsis,
          ),

          // Small space between text and icon
          const SizedBox(width: 8),

          // Add icon
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

    // More responsive width calculation based on screen size
    double containerWidth;

    // For very large screens (full-screen mode)
    if (size.width > 1400) {
      // Use 60% of screen width but cap at 1000px
      containerWidth = math.min(size.width * 0.6, 1000);
    }
    // For medium-large screens
    else if (size.width > 800) {
      // Use 70% of screen width but minimum 500px
      containerWidth = math.max(size.width * 0.7, 500);
    }
    // For smaller screens
    else {
      // Use available width with small margins
      final availableWidth =
          size.width - edgeInsets.left - edgeInsets.right - 32;
      containerWidth = availableWidth > 0 ? availableWidth : size.width * 0.85;
    }

    // Ensure width is never less than 320px
    containerWidth = math.max(containerWidth, 320);

    final frameHeight = _currentHeight.clamp(_collapsedHeight, _expandedHeight);
    final bool showExpandedContent =
        _isExpanded || _animationController.value > 0.1;

    // Background color based on theme with slight translucency
    final backgroundColor =
        isDarkMode 
            ? const Color(0xFF232323) // Darker for better contrast in dark mode
            : const Color(0xFFF0F0F0); // Slightly off-white in light mode

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
          // Changed to expand directly on tap
          onTap: () {
            if (!_isExpanded) {
              _expand();
            }
          },
          child: Container(
            width: containerWidth,
            height: frameHeight,
            decoration: BoxDecoration(
              // More terminal-like styling
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                36,
              ), // Even more rounded corners
              // Terminal-like border and shadow
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 0.5, // Very thin border
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(
                    isDarkMode ? 77 : 26,
                  ), // 0.3*255=77, 0.1*255=26
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
                // Inner shadow effect for terminal feel
                BoxShadow(
                  color:
                      isDarkMode
                          ? Colors.white.withAlpha(5) // 0.02 * 255 = 5.1
                          : Colors.black.withAlpha(5), // 0.02 * 255 = 5.1
                  blurRadius: 1,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36), // Match container radius
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Drag indicator - more subtle
                    Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).dividerColor.withAlpha(102), // 0.4 * 255 = 102
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Main content area with more space
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              MediaQuery.of(context).size.width > 1200
                                  ? 36
                                  : 24, // More padding on large screens
                          vertical:
                              MediaQuery.of(context).size.width > 1200
                                  ? 12
                                  : 8, // More padding on large screens
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
