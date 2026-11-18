import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:pomodoro_app/features/projects/models/project_models.dart';

class ProjectStore extends ChangeNotifier {
  ProjectStore(this._db, {this.onChanged});

  final Database _db;
  final Future<void> Function()? onChanged;
  final Uuid _uuid = const Uuid();

  List<ProjectItem> _projects = const [];
  List<LabelItem> _labels = const [];

  List<ProjectItem> get projects => _projects;
  List<ProjectItem> get activeProjects =>
      _projects.where((p) => !p.isArchived).toList(growable: false);
  List<LabelItem> get labels => _labels;

  ProjectItem? projectById(String? id) {
    if (id == null) return null;
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  LabelItem? labelById(String id) {
    for (final label in _labels) {
      if (label.id == id) return label;
    }
    return null;
  }

  List<ProjectItem> childrenOf(String? parentId) {
    return _projects
        .where((p) => !p.isArchived && p.parentId == parentId)
        .toList(growable: false);
  }

  Future<void> load() async {
    final projectRows = await _db.query(
      'projects',
      orderBy: 'sort_order ASC, created_at ASC',
    );
    final labelRows = await _db.query(
      'labels',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    _projects = List.unmodifiable(projectRows.map(ProjectItem.fromMap));
    _labels = List.unmodifiable(labelRows.map(LabelItem.fromMap));
    notifyListeners();
  }

  Future<ProjectItem> createProject({
    required String name,
    String colorHex = '#D83B2E',
    ProjectIcon icon = ProjectIcon.folder,
    String? parentId,
  }) async {
    final now = DateTime.now();
    final item = ProjectItem(
      id: _uuid.v4(),
      name: name.trim(),
      colorHex: colorHex,
      icon: icon,
      parentId: parentId,
      sortOrder: _projects.length,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert('projects', item.toMap());
    await load();
    return item;
  }

  Future<void> updateProject(ProjectItem updated) async {
    final item = updated.copyWith(updatedAt: DateTime.now());
    await _db.update(
      'projects',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    await load();
  }

  Future<void> deleteProject(String id) async {
    await _db.transaction((txn) async {
      await txn.update(
        'tasks',
        {'project_id': null},
        where: 'project_id = ?',
        whereArgs: [id],
      );
      await txn.update(
        'projects',
        {'parent_id': null},
        where: 'parent_id = ?',
        whereArgs: [id],
      );
      await txn.delete('projects', where: 'id = ?', whereArgs: [id]);
    });
    await load();
    if (onChanged != null) {
      await onChanged!();
    }
  }

  Future<LabelItem> createLabel({
    required String name,
    String colorHex = '#D83B2E',
    LabelIcon icon = LabelIcon.tag,
  }) async {
    final trimmed = name.trim();
    final duplicate = _labels.any(
      (existing) => existing.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      throw LabelNameTakenException(trimmed);
    }
    final now = DateTime.now();
    final item = LabelItem(
      id: _uuid.v4(),
      name: trimmed,
      colorHex: colorHex,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert('labels', item.toMap());
    await load();
    return item;
  }

  Future<void> updateLabel(LabelItem updated) async {
    final trimmed = updated.name.trim();
    final duplicate = _labels.any(
      (existing) =>
          existing.id != updated.id &&
          existing.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      throw LabelNameTakenException(trimmed);
    }
    final item = updated.copyWith(name: trimmed, updatedAt: DateTime.now());
    await _db.update(
      'labels',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    await load();
  }

  Future<void> deleteLabel(String id) async {
    await _db.delete('labels', where: 'id = ?', whereArgs: [id]);
    await load();
    if (onChanged != null) {
      await onChanged!();
    }
  }
}
