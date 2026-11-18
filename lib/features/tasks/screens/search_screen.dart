import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';
import 'package:pomodoro_app/core/widgets/adaptive_shell.dart';
import 'package:pomodoro_app/core/widgets/compact_shell_header.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';
import 'package:pomodoro_app/features/tasks/widgets/task_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskStore = context.watch<TaskStore>();
    final colors = context.appColors;
    final query = _queryController.text;
    final results = taskStore.searchTasks(query);

    return Column(
      children: [
        CompactShellHeader(
          title: 'Search',
          onOpenDrawer: () => AdaptiveShell.openDrawerOf(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            key: const Key('task-search-input'),
            controller: _queryController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search tasks by title or description...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _queryController.clear();
                        setState(() {});
                      },
                      icon: const Icon(LucideIcons.x, size: 16),
                    ),
            ),
          ),
        ),
        Expanded(
          child: query.trim().isEmpty
              ? Center(
                  child: Text(
                    'Type to search across your workspace.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.secondaryText,
                    ),
                  ),
                )
              : results.isEmpty
                  ? Center(
                      child: Text(
                        'No matching tasks found.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.secondaryText,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
                      children: [
                        for (final task in results) TaskListItem(task: task),
                      ],
                    ),
        ),
      ],
    );
  }
}
