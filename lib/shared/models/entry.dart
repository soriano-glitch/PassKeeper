import 'package:flutter/material.dart';

enum EntryCategory { social, banking, work, other }

extension EntryCategoryX on EntryCategory {
  String get label {
    switch (this) {
      case EntryCategory.social:
        return 'Social';
      case EntryCategory.banking:
        return 'Banking';
      case EntryCategory.work:
        return 'Work';
      case EntryCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case EntryCategory.social:
        return const Color(0xFF8B5CF6);
      case EntryCategory.banking:
        return const Color(0xFF10B981);
      case EntryCategory.work:
        return const Color(0xFF3B82F6);
      case EntryCategory.other:
        return const Color(0xFF6B7280);
    }
  }

  IconData get icon {
    switch (this) {
      case EntryCategory.social:
        return Icons.people_alt_rounded;
      case EntryCategory.banking:
        return Icons.account_balance_rounded;
      case EntryCategory.work:
        return Icons.work_rounded;
      case EntryCategory.other:
        return Icons.folder_rounded;
    }
  }
}

class VaultEntry {
  final String id;
  final String title;
  final String? username;
  final String? password;
  final String? website;
  final String? notes;
  final EntryCategory category;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VaultEntry({
    required this.id,
    required this.title,
    this.username,
    this.password,
    this.website,
    this.notes,
    this.category = EntryCategory.other,
    this.favorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  VaultEntry copyWith({
    String? title,
    String? username,
    String? password,
    String? website,
    String? notes,
    EntryCategory? category,
    bool? favorite,
    DateTime? updatedAt,
  }) {
    return VaultEntry(
      id: id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
