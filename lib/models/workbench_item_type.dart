

/// Represents the type of item referenced by a WorkbenchItemReference.
enum WorkbenchItemType {
  /// A standard note or memo.
  note,

  /// A comment on a note or potentially other items in the future.
  comment,

  /// A task item (e.g., from Todoist).
  task,

  /// A project item (currently unused, placeholder).
  project,
}
