import 'package:flutter/material.dart';

class FilterMenu extends StatelessWidget {
  final String currentFilterKey;
  final Function(String) onSelectFilter;

  const FilterMenu({
    Key? key,
    required this.currentFilterKey,
    required this.onSelectFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filterItems = <String>["inbox", "archive", "all", "prompts", "ideas", "work", "side"];
    return PopupMenuButton<String>(
      onSelected: (value) => onSelectFilter(value),
      icon: Row(
        children: [
          const Icon(Icons.filter_list),
          const SizedBox(width: 4),
          Text(
            currentFilterKey.toUpperCase(),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
      itemBuilder: (context) => filterItems
          .map(
            (f) => PopupMenuItem<String>(
              value: f,
              child: Text(
                f.toUpperCase(),
                style: TextStyle(
                  fontWeight: f == currentFilterKey ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}