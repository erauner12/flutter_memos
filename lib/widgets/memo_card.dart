import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MemoCard extends StatelessWidget {
  final Memo memo;
  final VoidCallback onTap;

  const MemoCard({
    Key? key,
    required this.memo,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(memo.content),
        subtitle: memo.pinned ? const Text("Pinned") : null,
        onTap: onTap,
      ),
    );
  }
}