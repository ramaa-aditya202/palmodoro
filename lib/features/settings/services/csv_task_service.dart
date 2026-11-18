import 'dart:convert';

import 'package:pomodoro_app/features/projects/models/project_models.dart';
import 'package:pomodoro_app/features/projects/store/project_store.dart';
import 'package:pomodoro_app/features/tasks/models/task_models.dart';
import 'package:pomodoro_app/features/tasks/store/task_store.dart';

class CsvImportFormatException implements Exception {
  const CsvImportFormatException(this.message);
  final String message;

  @override
  String toString() => 'CsvImportFormatException: $message';
}

class _ParsedCsvTaskRow {
  const _ParsedCsvTaskRow({
    required this.rowNumber,
    required this.key,
    required this.content,
    required this.description,
    required this.projectName,
    required this.labelNames,
    required this.priority,
    required this.dueAt,
    required this.scheduleKind,
    required this.durationMinutes,
    required this.recurrence,
    required this.estimatedPomodoros,
    required this.kanbanStatus,
    required this.parentKey,
  });

  final int rowNumber;
  final String? key;
  final String content;
  final String description;
  final String? projectName;
  final List<String> labelNames;
  final int priority;
  final DateTime? dueAt;
  final TaskScheduleKind scheduleKind;
  final int? durationMinutes;
  final TaskRecurrence? recurrence;
  final int estimatedPomodoros;
  final String kanbanStatus;
  final String? parentKey;
}

class CsvTaskService {
  const CsvTaskService._();

  static const int maxBytes = 16 * 1024 * 1024;
  static const int maxTasks = 1000;

  static const List<String> headers = <String>[
    'key',
    'content',
    'description',
    'project',
    'labels',
    'priority',
    'due_date',
    'start_at',
    'end_at',
    'time_zone',
    'recurrence',
    'recurrence_interval',
    'deadline',
    'estimate',
    'kanban_status',
    'parent_key',
  ];

  static String exportTasks({
    required List<TaskItem> tasks,
    required ProjectStore projectStore,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));

    // Emit root tasks before subtasks for readability.
    final sorted = <TaskItem>[
      ...tasks.where((t) => t.parentId == null),
      ...tasks.where((t) => t.parentId != null),
    ];

    final tzName = DateTime.now().timeZoneName;

    for (final task in sorted) {
      final projectName = projectStore.projectById(task.projectId)?.name ?? '';
      final labelsJoined = task.labelIds
          .map((id) => projectStore.labelById(id)?.name)
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty)
          .join('|');

      String dueDateStr = '';
      String startAtStr = '';
      String endAtStr = '';

      if (task.dueAt != null) {
        if (task.scheduleKind == TaskScheduleKind.timed) {
          startAtStr = task.dueAt!.toIso8601String();
          final dur = task.durationMinutes;
          if (dur != null && dur > 0) {
            endAtStr = task.dueAt!
                .add(Duration(minutes: dur))
                .toIso8601String();
          }
        } else {
          dueDateStr = _formatDateYmd(task.dueAt!);
        }
      }

      final row = <String>[
        task.id,
        task.title,
        task.description,
        projectName,
        labelsJoined,
        task.priority.toString(),
        dueDateStr,
        startAtStr,
        endAtStr,
        tzName,
        task.recurrence?.unit.storageValue ?? '',
        task.recurrence != null ? task.recurrence!.interval.toString() : '',
        '',
        task.estimatedPomodoros > 0 ? task.estimatedPomodoros.toString() : '',
        task.kanbanStatus,
        task.parentId ?? '',
      ];
      buffer.writeln(row.map(_escapeCsvCell).join(','));
    }

    return buffer.toString();
  }

  static Future<int> importCsv({
    required String csvContent,
    required TaskStore taskStore,
    required ProjectStore projectStore,
  }) async {
    final sanitized = csvContent.startsWith('\uFEFF')
        ? csvContent.substring(1)
        : csvContent;
    final byteLength = utf8.encode(sanitized).length;
    if (byteLength > maxBytes) {
      throw const CsvImportFormatException(
        'CSV file exceeds the 16 MiB maximum limit.',
      );
    }

    if (sanitized.trim().isEmpty) {
      throw const CsvImportFormatException('CSV content is empty.');
    }

    final delimiter = _detectDelimiter(sanitized);
    final rawRows = _parseCsvRows(sanitized, delimiter: delimiter);
    final nonEmptyRows = rawRows
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .toList(growable: false);

    if (nonEmptyRows.length < 2) {
      throw const CsvImportFormatException(
        'CSV must include a header row and at least one task row.',
      );
    }

    final headerCells = nonEmptyRows.first
        .map((c) => c.trim().toLowerCase())
        .toList(growable: false);
    final allowedHeaders = headers.toSet();
    final seenHeaders = <String>{};
    for (final h in headerCells) {
      if (h.isEmpty || !allowedHeaders.contains(h)) {
        throw CsvImportFormatException('Unknown CSV column header: "$h".');
      }
      if (!seenHeaders.add(h)) {
        throw CsvImportFormatException('Duplicate CSV column header: "$h".');
      }
    }
    if (!seenHeaders.contains('content')) {
      throw const CsvImportFormatException(
        'CSV header must contain the required "content" column.',
      );
    }

    final dataRows = nonEmptyRows.sublist(1);
    if (dataRows.length > maxTasks) {
      throw CsvImportFormatException(
        'CSV contains ${dataRows.length} tasks, exceeding the $maxTasks-task limit.',
      );
    }

    final headerIndex = <String, int>{
      for (var i = 0; i < headerCells.length; i++) headerCells[i]: i,
    };

    String cellAt(List<String> row, String column) {
      final idx = headerIndex[column];
      if (idx == null || idx >= row.length) return '';
      return row[idx].trim();
    }

    final parsedRows = <_ParsedCsvTaskRow>[];
    final seenKeys = <String>{};

    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final rowNumber = i + 2;
      if (row.length > headerCells.length) {
        throw CsvImportFormatException(
          'Row $rowNumber has more columns than the header.',
        );
      }

      final content = cellAt(row, 'content');
      if (content.isEmpty) {
        throw CsvImportFormatException(
          'Row $rowNumber is missing required "content".',
        );
      }

      final rawKey = cellAt(row, 'key');
      final key = rawKey.isEmpty ? null : rawKey;
      if (key != null && !seenKeys.add(key)) {
        throw CsvImportFormatException(
          'Row $rowNumber has duplicate key "$key".',
        );
      }

      final description = cellAt(row, 'description');
      final project = cellAt(row, 'project');
      final labelsRaw = cellAt(row, 'labels');
      final labelNames = labelsRaw.isEmpty
          ? const <String>[]
          : labelsRaw
                .split('|')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(growable: false);

      final priority = _parsePriority(cellAt(row, 'priority'), rowNumber);

      final dueDateRaw = cellAt(row, 'due_date');
      final startAtRaw = cellAt(row, 'start_at');
      final endAtRaw = cellAt(row, 'end_at');

      DateTime? dueAt;
      TaskScheduleKind scheduleKind = TaskScheduleKind.allDay;
      int? durationMinutes;

      if (startAtRaw.isNotEmpty) {
        final parsedStart = DateTime.tryParse(startAtRaw);
        if (parsedStart == null) {
          throw CsvImportFormatException(
            'Row $rowNumber has invalid start_at "$startAtRaw".',
          );
        }
        dueAt = parsedStart.isUtc ? parsedStart.toLocal() : parsedStart;
        scheduleKind = TaskScheduleKind.timed;
        if (endAtRaw.isNotEmpty) {
          final parsedEnd = DateTime.tryParse(endAtRaw);
          if (parsedEnd == null) {
            throw CsvImportFormatException(
              'Row $rowNumber has invalid end_at "$endAtRaw".',
            );
          }
          final endLocal = parsedEnd.isUtc ? parsedEnd.toLocal() : parsedEnd;
          final diff = endLocal.difference(dueAt).inMinutes;
          if (diff > 0) {
            durationMinutes = diff;
          }
        }
      } else if (dueDateRaw.isNotEmpty) {
        final parsedDue = DateTime.tryParse(dueDateRaw);
        if (parsedDue == null) {
          throw CsvImportFormatException(
            'Row $rowNumber has invalid due_date "$dueDateRaw".',
          );
        }
        dueAt = DateTime(parsedDue.year, parsedDue.month, parsedDue.day);
        scheduleKind = TaskScheduleKind.allDay;
      }

      final recurrence = _parseRecurrence(
        unitRaw: cellAt(row, 'recurrence'),
        intervalRaw: cellAt(row, 'recurrence_interval'),
        rowNumber: rowNumber,
      );

      final estimateRaw = cellAt(row, 'estimate');
      var estimate = 0;
      if (estimateRaw.isNotEmpty) {
        final parsedEstimate = int.tryParse(estimateRaw);
        if (parsedEstimate == null || parsedEstimate < 0) {
          throw CsvImportFormatException(
            'Row $rowNumber has invalid estimate "$estimateRaw".',
          );
        }
        estimate = parsedEstimate;
      }

      final kanbanStatus = _parseKanbanStatus(
        cellAt(row, 'kanban_status'),
        rowNumber,
      );
      final parentKeyRaw = cellAt(row, 'parent_key');
      final parentKey = parentKeyRaw.isEmpty ? null : parentKeyRaw;

      parsedRows.add(
        _ParsedCsvTaskRow(
          rowNumber: rowNumber,
          key: key,
          content: content,
          description: description,
          projectName: project.isEmpty ? null : project,
          labelNames: labelNames,
          priority: priority,
          dueAt: dueAt,
          scheduleKind: scheduleKind,
          durationMinutes: durationMinutes,
          recurrence: recurrence,
          estimatedPomodoros: estimate,
          kanbanStatus: kanbanStatus,
          parentKey: parentKey,
        ),
      );
    }

    // Validate parent_key references and check for cycles.
    final rowByKey = <String, _ParsedCsvTaskRow>{
      for (final r in parsedRows)
        if (r.key != null) r.key!: r,
    };

    for (final row in parsedRows) {
      final pKey = row.parentKey;
      if (pKey == null) continue;
      if (!rowByKey.containsKey(pKey)) {
        throw CsvImportFormatException(
          'Row ${row.rowNumber} references unknown parent_key "$pKey".',
        );
      }
      final visited = <String>{if (row.key != null) row.key!};
      String? cursor = pKey;
      while (cursor != null) {
        if (!visited.add(cursor)) {
          throw CsvImportFormatException(
            'Row ${row.rowNumber} contains a circular parent_key cycle involving "$cursor".',
          );
        }
        cursor = rowByKey[cursor]?.parentKey;
      }
    }

    // Resolve or create projects and labels case-insensitively.
    final projectIdByLowerName = <String, String>{
      for (final p in projectStore.projects) p.name.toLowerCase(): p.id,
    };
    final labelIdByLowerName = <String, String>{
      for (final l in projectStore.labels) l.name.toLowerCase(): l.id,
    };

    for (final row in parsedRows) {
      final pName = row.projectName;
      if (pName != null) {
        final lower = pName.toLowerCase();
        if (!projectIdByLowerName.containsKey(lower)) {
          final created = await projectStore.createProject(name: pName);
          projectIdByLowerName[lower] = created.id;
        }
      }
      for (final lName in row.labelNames) {
        final lower = lName.toLowerCase();
        if (!labelIdByLowerName.containsKey(lower)) {
          final created = await projectStore.createLabel(
            name: lName,
            icon: LabelIcon.tag,
          );
          labelIdByLowerName[lower] = created.id;
        }
      }
    }

    // Topologically order rows so parent tasks are created before children.
    final orderedRows = <_ParsedCsvTaskRow>[];
    final emittedRows = <_ParsedCsvTaskRow>{};

    void emitRow(_ParsedCsvTaskRow row) {
      if (emittedRows.contains(row)) return;
      final pKey = row.parentKey;
      if (pKey != null) {
        final parentRow = rowByKey[pKey];
        if (parentRow != null && !emittedRows.contains(parentRow)) {
          emitRow(parentRow);
        }
      }
      emittedRows.add(row);
      orderedRows.add(row);
    }

    for (final row in parsedRows) {
      emitRow(row);
    }

    final createdIdByKey = <String, String>{};
    for (final row in orderedRows) {
      final projectId = row.projectName == null
          ? null
          : projectIdByLowerName[row.projectName!.toLowerCase()];
      final labelIds = row.labelNames
          .map((n) => labelIdByLowerName[n.toLowerCase()])
          .whereType<String>()
          .toList(growable: false);
      final parentId = row.parentKey == null
          ? null
          : createdIdByKey[row.parentKey!];

      final created = await taskStore.createTask(
        title: row.content,
        description: row.description,
        projectId: projectId,
        parentId: parentId,
        priority: row.priority,
        dueAt: row.dueAt,
        scheduleKind: row.scheduleKind,
        durationMinutes: row.durationMinutes,
        recurrence: row.recurrence,
        estimatedPomodoros: row.estimatedPomodoros,
        kanbanStatus: row.kanbanStatus,
        labelIds: labelIds,
      );
      if (row.key != null) {
        createdIdByKey[row.key!] = created.id;
      }
    }

    return orderedRows.length;
  }

  static int _parsePriority(String raw, int rowNumber) {
    if (raw.isEmpty) return 4;
    final normalized = raw.toLowerCase().replaceFirst('p', '');
    final value = int.tryParse(normalized);
    if (value == null || value < 1 || value > 4) {
      throw CsvImportFormatException(
        'Row $rowNumber has invalid priority "$raw" (expected 1..4).',
      );
    }
    return value;
  }

  static TaskRecurrence? _parseRecurrence({
    required String unitRaw,
    required String intervalRaw,
    required int rowNumber,
  }) {
    if (unitRaw.isEmpty) return null;
    final normalizedUnit = switch (unitRaw.toLowerCase()) {
      'day' || 'daily' => TaskRecurrenceUnit.day,
      'week' || 'weekly' => TaskRecurrenceUnit.week,
      'month' || 'monthly' => TaskRecurrenceUnit.month,
      _ => null,
    };
    if (normalizedUnit == null) {
      throw CsvImportFormatException(
        'Row $rowNumber has invalid recurrence "$unitRaw".',
      );
    }
    var interval = 1;
    if (intervalRaw.isNotEmpty) {
      final parsedInterval = int.tryParse(intervalRaw);
      if (parsedInterval == null || parsedInterval <= 0) {
        throw CsvImportFormatException(
          'Row $rowNumber has invalid recurrence_interval "$intervalRaw".',
        );
      }
      interval = parsedInterval;
    }
    return TaskRecurrence(interval: interval, unit: normalizedUnit);
  }

  static String _parseKanbanStatus(String raw, int rowNumber) {
    if (raw.isEmpty) return 'todo';
    final normalized = raw.toLowerCase().replaceAll(' ', '_');
    const allowed = {'backlog', 'todo', 'in_progress', 'done'};
    if (!allowed.contains(normalized)) {
      throw CsvImportFormatException(
        'Row $rowNumber has invalid kanban_status "$raw".',
      );
    }
    return normalized;
  }

  static String _formatDateYmd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _escapeCsvCell(String value) {
    final needsQuotes =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _detectDelimiter(String content) {
    var inQuotes = false;
    var commas = 0;
    var semicolons = 0;
    for (var i = 0; i < content.length; i++) {
      final ch = content[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (!inQuotes && (ch == '\n' || ch == '\r')) {
        break;
      } else if (!inQuotes) {
        if (ch == ',') commas++;
        if (ch == ';') semicolons++;
      }
    }
    return semicolons > commas ? ';' : ',';
  }

  static List<List<String>> _parseCsvRows(
    String content, {
    required String delimiter,
  }) {
    final rows = <List<String>>[];
    var currentRow = <String>[];
    final currentCell = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < content.length; i++) {
      final ch = content[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < content.length && content[i + 1] == '"') {
            currentCell.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          currentCell.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == delimiter) {
          currentRow.add(currentCell.toString());
          currentCell.clear();
        } else if (ch == '\r') {
          if (i + 1 < content.length && content[i + 1] == '\n') {
            i++;
          }
          currentRow.add(currentCell.toString());
          currentCell.clear();
          rows.add(currentRow);
          currentRow = <String>[];
        } else if (ch == '\n') {
          currentRow.add(currentCell.toString());
          currentCell.clear();
          rows.add(currentRow);
          currentRow = <String>[];
        } else {
          currentCell.write(ch);
        }
      }
    }

    if (inQuotes) {
      throw const CsvImportFormatException(
        'CSV contains an unclosed quoted field.',
      );
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      rows.add(currentRow);
    }

    return rows;
  }
}
