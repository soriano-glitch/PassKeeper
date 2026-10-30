import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/utils/clipboard_service.dart';
import '../../shared/models/entry.dart';
import '../../shared/widgets/page_header.dart';
import '../../widgets/pk_card.dart';

class EntryDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const EntryDetailScreen({super.key, required this.id});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  bool _showPassword = false;

  VaultEntry? _entry(WidgetRef ref) {
    final entries = ref.watch(vaultControllerProvider).entries;
    try {
      return entries.firstWhere((e) => e.id == widget.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _copy(String text, String label) async {
    final secs = ref.read(clipboardClearSecondsProvider);
    await ClipboardService.copy(text, seconds: secs);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied. Clears in $secs seconds.')),
    );
  }

  Future<void> _toggleFavorite() async {
    final e = _entry(ref);
    if (e == null) return;
    await ref.read(vaultControllerProvider.notifier).updateEntry(
          e.copyWith(favorite: !e.favorite, updatedAt: DateTime.now()),
        );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(vaultControllerProvider.notifier).deleteEntry(widget.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry(ref);
    if (entry == null) {
      return const Scaffold(
        appBar: PkAppBar(title: 'Detail'),
        body: Center(child: Text('Not found')),
      );
    }
    return Scaffold(
      appBar: PkAppBar(
        title: entry.title,
        actions: [
          IconButton(
            icon: Icon(entry.favorite
                ? Icons.star_rounded
                : Icons.star_border_rounded),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/edit-entry/${entry.id}'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _row('Username', entry.username,
              onCopy: entry.username == null
                  ? null
                  : () => _copy(entry.username!, 'Username')),
          _row('Password', _showPassword ? (entry.password ?? '') : '••••••••',
              actions: [
                IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ],
              onCopy: entry.password == null
                  ? null
                  : () => _copy(entry.password!, 'Password')),
          _row('Website', entry.website),
          _row('Notes', entry.notes),
          _row('Category', entry.category.label),
        ],
      ),
    );
  }

  Widget _row(String label, String? value,
      {VoidCallback? onCopy, List<Widget>? actions}) {
    final cs = Theme.of(context).colorScheme;
    final teal = cs.onSurface;
    final muted = cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PkCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: muted)),
                    const SizedBox(height: 4),
                    Text(value ?? '—',
                        style: TextStyle(fontSize: 16, color: teal)),
                  ],
                ),
              ),
              ...?actions,
              if (onCopy != null)
                IconButton(
                  icon: Icon(Icons.copy_rounded, size: 20, color: teal),
                  tooltip: 'Copy $label',
                  onPressed: onCopy,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
