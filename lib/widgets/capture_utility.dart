import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_providers.dart';
import 'package:flutter_memos/screens/new_memo/new_memo_providers.dart';

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

class _CaptureUtilityState extends ConsumerState<CaptureUtility> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handlePaste() async {
    ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      setState(() {
        _textController.text = clipboardData.text!;
        _isExpanded = true;
      });
      _focusNode.requestFocus();
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
        _isExpanded = false;
        _isSubmitting = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
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

    final icon =
        widget.mode == CaptureMode.createMemo ? Icons.add : Icons.comment;

    final tooltip =
        widget.mode == CaptureMode.createMemo ? 'Add memo' : 'Add comment';
    
    // Responsive width based on screen size
    double containerWidth;
    if (size.width > 800) {
      containerWidth = 400; // Desktop-style narrower box
    } else {
      containerWidth = size.width * 0.95; // Mobile-friendly
    }

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 0 : 16),
      child: Container(
        width: containerWidth,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text field area
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expand/collapse icon
                  if (_isExpanded)
                    IconButton(
                      icon: const Icon(Icons.unfold_less),
                      onPressed: () {
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                      tooltip: 'Collapse',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  if (!_isExpanded)
                    IconButton(
                      icon: Icon(icon),
                      onPressed: () {
                        setState(() {
                          _isExpanded = true;
                        });
                        _focusNode.requestFocus();
                      },
                      tooltip: tooltip,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                    
                  const SizedBox(width: 8),
                  
                  // Text field - expanded or single line
                  Expanded(
                    child: _isExpanded
                      ? TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: hintText,
                            border: InputBorder.none,
                          ),
                          maxLines: 5,
                              minLines:
                                  widget.mode == CaptureMode.createMemo ? 3 : 2,
                          textCapitalization: TextCapitalization.sentences,
                        )
                      : InkWell(
                          onTap: () {
                            setState(() {
                              _isExpanded = true;
                            });
                            _focusNode.requestFocus();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                                  placeholderText,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
            
            // Buttons row - only visible when expanded
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Paste button
                    TextButton.icon(
                      onPressed: _handlePaste,
                      icon: const Icon(Icons.content_paste, size: 16),
                      label: const Text('Paste'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    
                    // Submit button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: _isSubmitting
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
        ),
      ),
    );
  }
}
