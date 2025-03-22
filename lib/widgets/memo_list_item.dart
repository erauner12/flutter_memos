import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MemoListItem extends StatelessWidget {
  final Memo memo;
  final VoidCallback onTap;
  final ValueChanged<String> onArchive;
  final ValueChanged<String> onDelete;

  const MemoListItem({
    Key? key,
    required this.memo,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(memo.id),
      background: Container(
        color: Colors.amber,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Archive
          onArchive(memo.id);
          return false; // Return false to not remove from list immediately
        } else {
          // Delete
          onDelete(memo.id);
          return false;
        }
      },
      child: ListTile(
        title: Text(
          memo.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (memo.pinned)
              const Text("Pinned ", style: TextStyle(color: Colors.green)),
            if (memo.state == V1State.archived)
              const Text("Archived ", style: TextStyle(color: Colors.grey)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}