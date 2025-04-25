import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart'; // Import Comment model
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem model
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_entity_providers.dart'; // Updated import

class EditEntityForm extends ConsumerStatefulWidget {
  final dynamic entity; // Can be NoteItem or Comment
  final String entityId;
  final String entityType; // 'note' or 'comment'
  final String serverId; // Add serverId

  const EditEntityForm({ // Renamed constructor
    super.key,
    required this.entity,
    required this.entityId,
    required this.entityType,
    required this.serverId, // Make serverId required
  });

  @override
  ConsumerState<EditEntityForm> createState() => _EditEntityFormState();
}

class _EditEntityFormState extends ConsumerState<EditEntityForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _contentController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    String initialContent = '';
    if (widget.entityType == 'comment' && widget.entity is Comment) {
      initialContent = (widget.entity as Comment).content ?? '';
    } else if (widget.entityType == 'note' && widget.entity is NoteItem) {
      initialContent = (widget.entity as NoteItem).content;
    }
    _contentController = TextEditingController(text: initialContent);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        dynamic updatedEntity;
        final newContent = _contentController.text;

        if (widget.entityType == 'comment' && widget.entity is Comment) {
          // Use ValueGetter for nullable content
          updatedEntity = (widget.entity as Comment).copyWith(
            content: () => newContent,
          );
        } else if (widget.entityType == 'note' && widget.entity is NoteItem) {
          updatedEntity = (widget.entity as NoteItem).copyWith(
            content: newContent,
          );
        } else {
          throw Exception('Invalid entity type or data for saving.');
        }

        // Call the save provider with the correct parameters (serverId removed from params)
        await ref.read(
          saveEntityProvider(
            EntityProviderParams(
              id: widget.entityId,
              type: widget.entityType,
            ),
          ),
        )(updatedEntity);

        if (mounted) {
          Navigator.of(context).pop(); // Pop back after successful save
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '[EditEntityForm] Error saving ${widget.entityType}: $e');
        }
        if (mounted) {
          setState(() {
            _error = 'Failed to save: ${e.toString()}';
            _isLoading = false;
          });
        }
      } finally {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          CupertinoFormSection.insetGrouped(
            header: Text(
              'CONTENT (${widget.entityType == 'comment' ? 'Comment' : 'Note'})',
            ),
            children: [
              CupertinoTextFormFieldRow(
                controller: _contentController,
                placeholder: 'Enter content...',
                maxLines: 10,
                minLines: 5,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Content cannot be empty';
                  }
                  return null;
                },
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16),
              child: Text(
                _error!,
                style: TextStyle(
                  color: CupertinoColors.systemRed.resolveFrom(context),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CupertinoButton.filled(
              onPressed: _isLoading ? null : _handleSave,
              child:
                  _isLoading
                      ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                      : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
