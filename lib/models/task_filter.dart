/// Enum defining different ways to filter tasks.
enum TaskFilter {
  all,
  recurring,
  notRecurring,
  dueToday,
}

/// Extension to get a user-friendly title for each filter.
extension TaskFilterTitle on TaskFilter {
  String get title {
    switch (this) {
      case TaskFilter.all:
        return 'All Tasks';
      case TaskFilter.recurring:
        return 'Recurring Tasks';
      case TaskFilter.notRecurring:
        return 'Non-Recurring Tasks';
      case TaskFilter.dueToday:
        return 'Tasks Due Today';
    }
  }

  String get emptyStateMessage {
     switch (this) {
      case TaskFilter.all:
        return 'No tasks found.\nPull down to refresh or add a new task.';
      case TaskFilter.recurring:
        return 'No recurring tasks found.';
      case TaskFilter.notRecurring:
        return 'No non-recurring tasks found.';
      case TaskFilter.dueToday:
        return 'No tasks due today.';
    }
  }
}
