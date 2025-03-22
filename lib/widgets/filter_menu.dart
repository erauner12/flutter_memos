import 'package:flutter/material.dart';

class FilterItem {
  final String label;
  final String key;

  FilterItem({required this.label, required this.key});
}

class FilterMenu extends StatelessWidget {
  final String currentFilterKey;
  final List<FilterItem> filters;
  final Function(FilterItem) onFilterSelected;

  const FilterMenu({
    super.key,
    required this.currentFilterKey,
    required this.filters,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Find currently selected filter
    final selectedFilter = filters.firstWhere(
      (filter) => filter.key == currentFilterKey,
      orElse: () => FilterItem(label: 'Inbox', key: 'inbox'),
    );

    return PopupMenuButton<String>(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedFilter.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      onSelected: (String key) {
        final selectedFilter = filters.firstWhere(
          (filter) => filter.key == key,
          orElse: () => FilterItem(label: 'Inbox', key: 'inbox'),
        );
        onFilterSelected(selectedFilter);
      },
      itemBuilder: (BuildContext context) {
        return filters.map((FilterItem filter) {
          return PopupMenuItem<String>(
            value: filter.key,
            child: Row(
              children: [
                if (filter.key == currentFilterKey)
                  const Icon(Icons.check, size: 16)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(filter.label),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
