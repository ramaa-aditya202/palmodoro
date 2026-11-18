import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import 'package:pomodoro_app/core/theme/app_theme.dart';

class LabelNameTakenException implements Exception {
  const LabelNameTakenException(this.name);
  final String name;

  @override
  String toString() => 'A label named "$name" already exists.';
}

abstract final class ProjectColors {
  static const List<String> palette = [
    '#D83B2E',
    '#E07A1F',
    '#B76A00',
    '#2E7D32',
    '#0E7490',
    '#2563EB',
    '#3B6EA8',
    '#6D28D9',
    '#9333EA',
    '#C026D3',
    '#BE123C',
    '#52525B',
  ];

  static Color parse(String hex) =>
      parseThemeColor(hex) ?? const Color(0xFFD83B2E);
}

enum ProjectIcon {
  folder('folder', LucideIcons.folder),
  briefcase('briefcase', LucideIcons.briefcase),
  home('home', LucideIcons.house),
  book('book', LucideIcons.bookOpen),
  code('code', LucideIcons.code),
  heart('heart', LucideIcons.heart),
  star('star', LucideIcons.star),
  flag('flag', LucideIcons.flag),
  sparkles('sparkles', LucideIcons.sparkles),
  graduationCap('graduationCap', LucideIcons.graduationCap);

  const ProjectIcon(this.storageValue, this.iconData);
  final String storageValue;
  final IconData iconData;

  static ProjectIcon fromStorage(String? value) {
    return ProjectIcon.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => ProjectIcon.folder,
    );
  }
}

enum LabelIcon {
  tag('tag', LucideIcons.tag),
  bookmark('bookmark', LucideIcons.bookmark),
  flag('flag', LucideIcons.flag),
  bolt('bolt', LucideIcons.zap),
  clock('clock', LucideIcons.clock),
  star('star', LucideIcons.star);

  const LabelIcon(this.storageValue, this.iconData);
  final String storageValue;
  final IconData iconData;

  static LabelIcon fromStorage(String? value) {
    return LabelIcon.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => LabelIcon.tag,
    );
  }
}

class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.name,
    required this.colorHex,
    this.icon = ProjectIcon.folder,
    this.parentId,
    this.isArchived = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String colorHex;
  final ProjectIcon icon;
  final String? parentId;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color get color => ProjectColors.parse(colorHex);

  ProjectItem copyWith({
    String? name,
    String? colorHex,
    ProjectIcon? icon,
    String? parentId,
    bool clearParent = false,
    bool? isArchived,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return ProjectItem(
      id: id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'color_hex': colorHex,
    'icon': icon.storageValue,
    'parent_id': parentId,
    'is_archived': isArchived ? 1 : 0,
    'sort_order': sortOrder,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory ProjectItem.fromMap(Map<String, Object?> map) {
    return ProjectItem(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String,
      icon: ProjectIcon.fromStorage(map['icon'] as String?),
      parentId: map['parent_id'] as String?,
      isArchived: (map['is_archived'] as int? ?? 0) != 0,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}

class LabelItem {
  const LabelItem({
    required this.id,
    required this.name,
    required this.colorHex,
    this.icon = LabelIcon.tag,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String colorHex;
  final LabelIcon icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color get color => ProjectColors.parse(colorHex);

  LabelItem copyWith({
    String? name,
    String? colorHex,
    LabelIcon? icon,
    DateTime? updatedAt,
  }) {
    return LabelItem(
      id: id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'color_hex': colorHex,
    'icon': icon.storageValue,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory LabelItem.fromMap(Map<String, Object?> map) {
    return LabelItem(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String,
      icon: LabelIcon.fromStorage(map['icon'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
