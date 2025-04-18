import 'package:flutter/cupertino.dart';

/// Enum representing the main tabs in the HomeScreen's CupertinoTabScaffold.
enum HomeTab {
  workbench(label: 'Workbench', icon: CupertinoIcons.briefcase_fill),
  chat(
    label: 'Chat',
    icon: CupertinoIcons.chat_bubble_2_fill,
  ),
  notes(label: 'Notes', icon: CupertinoIcons.news_solid),
  more(label: 'More', icon: CupertinoIcons.ellipsis_circle_fill);

  const HomeTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
