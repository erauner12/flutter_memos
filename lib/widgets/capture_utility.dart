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
  final double _collapsedHeight = 70.0;
  final double _expandedHeight = 200.0;
  double _currentHeight = 70.0;

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

    debugPrint(
      '[CaptureUtility] AnimateTo: target=$targetValue, startValue=${_animationController.value.toStringAsFixed(3)}, velocity=${simulationVelocity.toStringAsFixed(3)}',
    );

    final simulation = SpringSimulation(
      _springDescription,
      _animationController.value,
      targetValue,
      simulationVelocity,
    );

    _animationController.animateWith(simulation).whenCompleteOrCancel(() {
      debugPrint(
        '[CaptureUtility] AnimateTo Complete/Cancel: target=$targetValue, finalValue=${_animationController.value.toStringAsFixed(3)}, _isDragging=$_isDragging',
      );
      // Ensure final state consistency only if not dragging and component is still mounted
      if (!_isDragging && mounted) {
        setState(() {
          _currentHeight =
              targetValue == 1.0 ? _expandedHeight : _collapsedHeight;
          // Ensure controller value matches target precisely at the end
          if ((_animationController.value - targetValue).abs() > 0.01) {
            debugPrint(
              '[CaptureUtility] AnimateTo Complete: Correcting final controller value to $targetValue',
            );
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
      // Add logging
      debugPrint(
        '[CaptureUtility] Drag Update: _currentHeight=$_currentHeight, _animationController.value=${_animationController.value.toStringAsFixed(3)}',
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return; // Should not happen, but safety first

    final dragVelocity = details.primaryVelocity ?? 0.0;
    final simulationVelocity =
        -dragVelocity / (_expandedHeight - _collapsedHeight);
    final currentFraction = _animationController.value;

    debugPrint(
      '[CaptureUtility] Drag End: dragVelocity=$dragVelocity, simulationVelocity=${simulationVelocity.toStringAsFixed(3)}, currentFraction=${currentFraction.toStringAsFixed(3)}',
    );

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
      debugPrint(
        '[CaptureUtility] Drag End: Target decided by velocity -> $targetValue',
      );
    } else {
      targetValue = currentFraction > positionThreshold ? 1.0 : 0.0;
      debugPrint(
        '[CaptureUtility] Drag End: Target decided by position -> $targetValue',
      );
    }

    // Check if close to target and velocity is low to snap directly
    if ((targetValue - currentFraction).abs() < 0.05 &&
        simulationVelocity.abs() < velocityThreshold / 2) {
      debugPrint('[CaptureUtility] Drag End: Snapping to target $targetValue');
      // Ensure state is updated correctly when snapping
      setState(() {
        _currentHeight =
            targetValue == 1.0 ? _expandedHeight : _collapsedHeight;
        // Manually set controller value to ensure consistency
        _animationController.value = targetValue;
      });
    } else {
      debugPrint(
        '[CaptureUtility] Drag End: Animating to target $targetValue with velocity ${simulationVelocity.toStringAsFixed(3)}',
      );
      _animateTo(targetValue, velocity: simulationVelocity);
    }
  }

  void _handleDragStart(DragStartDetails details) {
    // Ensure controller stops *before* setting dragging state
    _animationController.stop();
    setState(() {
      _isDragging = true;
    });
    debugPrint(
      '[CaptureUtility] Drag Start: _isDragging=true, Stopping animation.',
    );
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
            ? 'Capture something ...'
            : 'Add a comment...';

    double containerWidth;
    if (size.width > 800) {
      containerWidth = 400;
    } else {
      final availableWidth =
          size.width -
          edgeInsets.left -
          edgeInsets.right -
          32;
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
              // Add a subtle background color based on theme
              color:
                  isDarkMode
                      ? Colors.grey[900]?.withOpacity(
                        0.95,
                      ) // Dark theme background
                      : Colors.white.withOpacity(
                        0.95,
                      ), // Light theme background
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                width: 0.5,
              ),
              // Add a subtle shadow for better separation
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 3,
                        margin: const EdgeInsets.only(top: 6, bottom: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).dividerColor.withAlpha((255 * 0.6).round()),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          child:
                              showExpandedContent
                                  ? Column(
                                    children: [
                                      Expanded(
                                        child: Focus(
                                          focusNode: _focusNode,
                                          onKeyEvent: (node, event) {
                                            return _handleKeyEvent(event);
                                          },
                                          child: TextField(
                                            controller: _textController,
                                            decoration: InputDecoration(
                                              hintText: hintText,
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4.0,
                                                  ),
                                            ),
                                            maxLines: null,
                                            minLines:
                                                widget.mode ==
                                                        CaptureMode.createMemo
                                                    ? 3
                                                    : 2,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            keyboardType:
                                                TextInputType.multiline,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 0,
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
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
                                  : Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      placeholderText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
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
