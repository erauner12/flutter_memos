import 'package:flutter/material.dart';
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
  late Animation<double> _heightAnimation;

  // Track if user is currently dragging
  bool _isDragging = false;

  // Define min/max heights for the utility
  final double _collapsedHeight = 70.0; // Increased to accommodate minimum content
  final double _expandedHeight = 200.0; // Maximum expanded height
  double _currentHeight = 70.0; // Current height (starts collapsed)

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Set up height animation
    _heightAnimation = Tween<double>(
      begin: _collapsedHeight,
      end: _expandedHeight,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Listen to animation changes
    _animationController.addListener(() {
      setState(() {
        _currentHeight = _heightAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Property to check if expanded (for state management)
  bool get _isExpanded => _animationController.value > 0.5;

  // Expand the capture utility
  void _expand() {
    _animationController.forward();
    _focusNode.requestFocus();
  }

  // Collapse the capture utility
  void _collapse() {
    _animationController.reverse();
    _focusNode.unfocus();
    // Immediately set the height to collapsed state to avoid overflow during transition
    setState(() {
      _currentHeight = _collapsedHeight;
    });
  }

  // Handle vertical drag to expand/collapse
  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;

      // Calculate new height based on drag (negative dy means up, positive means down)
      final newHeight = _currentHeight - details.delta.dy;

      // Constrain height within min/max bounds
      _currentHeight = newHeight.clamp(_collapsedHeight, _expandedHeight);

      // Update animation controller value based on current height
      _animationController.value =
          (_currentHeight - _collapsedHeight) /
          (_expandedHeight - _collapsedHeight);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;

      // Calculate velocity direction - positive velocity means downward swipe
      final isDownwardSwipe =
          details.primaryVelocity != null && details.primaryVelocity! > 0;
      final isUpwardSwipe =
          details.primaryVelocity != null && details.primaryVelocity! < 0;

      // Use stronger velocity thresholds to ensure drags are detected properly
      if (isDownwardSwipe && details.primaryVelocity!.abs() > 100) {
        // Force collapse on downward swipe with velocity
        _animationController.animateTo(0.0);
        // Reset height immediately to avoid transition overflow
        _currentHeight = _collapsedHeight;
        _collapse();
      } else if (isUpwardSwipe && details.primaryVelocity!.abs() > 100) {
        // Force expand on upward swipe with velocity
        _animationController.animateTo(1.0);
        _expand();
      }
      // Otherwise use position threshold to determine state
      else if (_animationController.value > 0.3) {
        _expand();
      } else {
        // Reset height immediately to avoid transition overflow
        _currentHeight = _collapsedHeight;
        _collapse();
      }
    });
  }

  void _handleDragStart(DragStartDetails details) {
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
      // Ensure we're expanded when pasting content
      if (!_isExpanded) {
        _expand();
      }
    }
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

      // Collapse after successful submission
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

    // Use the existing createMemo provider
    await ref.read(createMemoProvider)(newMemo);

    // Show success message
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
      creatorId: '1', // Default user ID
      createTime: DateTime.now().millisecondsSinceEpoch,
    );

    // Use the addComment provider from memo detail
    await ref.read(addCommentProvider(memoId))(newComment);

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        // If expanded, collapse on escape
        if (_isExpanded) {
          _collapse();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter &&
          event.isMetaPressed) {
        // Submit on Command+Enter
        if (_isExpanded && !_isSubmitting) {
          _handleSubmit();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final edgeInsets = MediaQuery.of(context).padding;

    // Determine text based on mode
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
            ? 'Capture something ...'
            : 'Add a comment...';

    // Responsive width based on screen size, accounting for safe areas
    double containerWidth;
    if (size.width > 800) {
      containerWidth = 400; // Desktop-style narrower box
    } else {
      // Calculate available width accounting for horizontal safe areas
      final availableWidth =
          size.width -
          edgeInsets.left -
          edgeInsets.right -
          32; // 16px padding on each side
      containerWidth = availableWidth > 0 ? availableWidth : size.width * 0.85;
    }

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
          child: AnimatedContainer(
            duration:
                _isDragging
                    ? Duration
                        .zero // No animation during active drag
                    : const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: containerWidth,
            height: _currentHeight,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: ClipRRect(
              // Ensures content stays within rounded corners
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                // Use Stack for potential layering if needed later
                clipBehavior: Clip.hardEdge, // Clip overflow from children
                children: [
                  // Main content column
                  Column(
                    // Use max size to fill the AnimatedContainer height
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Drag indicator pill - minimal height, always visible
                      Container(
                        width: 40,
                        height: 3, // Reduced height
                        margin: const EdgeInsets.only(top: 6, bottom: 4), // Reduced margins
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Content Area: Use Expanded to fill remaining vertical space
                      Expanded(
                        child: Padding(
                          // Apply consistent padding within the main content area
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          child:
                              _isExpanded
                                  // Expanded State: TextField + Buttons Column
                                  ? Column(
                                    children: [
                                      Expanded(
                                        // TextField takes available space in the nested Column
                                        child: RawKeyboardListener(
                                          focusNode:
                                              FocusNode(), // Use a local focus node for listener
                                          onKey: _handleKeyEvent,
                                          child: TextField(
                                            controller: _textController,
                                            focusNode:
                                                _focusNode, // Use the state's focus node for input
                                            decoration: InputDecoration(
                                              hintText: hintText,
                                              border: InputBorder.none,
                                              isDense:
                                                  true, // More compact layout
                                              contentPadding:
                                                  EdgeInsets
                                                      .zero, // Remove extra padding
                                            ),
                                            maxLines:
                                                null, // Allow multiple lines
                                            minLines:
                                                widget.mode ==
                                                        CaptureMode.createMemo
                                                    ? 3
                                                    : 2,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            onSubmitted: (_) {
                                              if (!_isSubmitting)
                                                _handleSubmit();
                                            },
                                          ),
                                        ),
                                      ),
                                      // Buttons row at the bottom when expanded
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          bottom: 4,
                                        ), // Space buttons from text field
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Paste button
                                            TextButton.icon(
                                              onPressed: _handlePaste,
                                              icon: const Icon(
                                                Icons.content_paste,
                                                size: 16,
                                              ),
                                              label: const Text('Paste'),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            ),
                                            // Submit button
                                            ElevatedButton(
                                              onPressed:
                                                  _isSubmitting
                                                      ? null
                                                      : _handleSubmit,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 6,
                                                    ),
                                                minimumSize: Size.zero,
                                              ),
                                              child:
                                                  _isSubmitting
                                                      ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                      : Text(buttonText),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                  // Collapsed State: Simple Placeholder Text
                                  : Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      placeholderText,
                                      style: TextStyle(
                                        fontSize: 14, // Smaller text
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                      overflow:
                                          TextOverflow
                                              .ellipsis, // Prevent text overflow
                                      maxLines: 1, // Ensure single line
                                    ),
                                  ),
                        ),
                      ),
                    ],
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
