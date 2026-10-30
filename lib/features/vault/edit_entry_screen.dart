import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../shared/models/entry.dart';
import '../../shared/widgets/page_header.dart';

class EditEntryScreen extends ConsumerStatefulWidget {
  final String id;
  const EditEntryScreen({super.key, required this.id});

  @override
  ConsumerState<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends ConsumerState<EditEntryScreen> {
  final _title = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _website = TextEditingController();
  final _notes = TextEditingController();
  EntryCategory _category = EntryCategory.other;
  bool _favorite = false;
  bool _obscure = true;
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _password.dispose();
    _website.dispose();
    _notes.dispose();
    super.dispose();
  }

  VaultEntry? get _entry {
    final entries = ref.read(vaultControllerProvider).entries;
    try {
      return entries.firstWhere((e) => e.id == widget.id);
    } catch (_) {
      return null;
    }
  }

  void _load() {
    if (_loaded) return;
    final e = _entry;
    if (e == null) return;
    _title.text = e.title;
    _username.text = e.username ?? '';
    _password.text = e.password ?? '';
    _website.text = e.website ?? '';
    _notes.text = e.notes ?? '';
    _category = e.category;
    _favorite = e.favorite;
    _loaded = true;
  }

  Future<void> _save() async {
    final e = _entry;
    if (e == null) return;
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    final updated = e.copyWith(
      title: title,
      username: _username.text.trim().isEmpty ? null : _username.text.trim(),
      password: _password.text.isEmpty ? null : _password.text,
      website: _website.text.trim().isEmpty ? null : _website.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      category: _category,
      favorite: _favorite,
      updatedAt: DateTime.now(),
    );
    await ref.read(vaultControllerProvider.notifier).updateEntry(updated);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    _load();
    ref.listen<String?>(generatedPasswordProvider, (_, next) {
      if (next != null) {
        _password.text = next;
        ref.read(generatedPasswordProvider.notifier).state = null;
        setState(() {});
      }
    });
    return Scaffold(
      appBar: const PkAppBar(title: 'Edit password'),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: [
          if (_error != null) ...[
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 12),
          ],
          TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Site or app')),
          const SizedBox(height: 12),
          TextField(
              controller: _username,
              decoration:
                  const InputDecoration(labelText: 'Username or email')),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                  onPressed: () {
                    const chars =
                        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
                    final rng = Random.secure();
                    final sb = StringBuffer();
                    for (var i = 0; i < 16; i++) {
                      sb.write(chars[rng.nextInt(chars.length)]);
                    }
                    _password.text = sb.toString();
                    setState(() {});
                  },
                  child: const Text('Generate')),
              TextButton(
                  onPressed: () => context.push('/generator'),
                  child: const Text('Open generator')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _website,
              decoration: const InputDecoration(labelText: 'Website')),
          const SizedBox(height: 12),
          TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3),
          const SizedBox(height: 12),
          DropdownButtonFormField<EntryCategory>(
            initialValue: _category,
            items: EntryCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (v) =>
                setState(() => _category = v ?? EntryCategory.other),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Favorite'),
            value: _favorite,
            onChanged: (v) => setState(() => _favorite = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
                onPressed: _save, child: const Text('Save changes')),
          ),
        ],
      ),
    );
  }
}
