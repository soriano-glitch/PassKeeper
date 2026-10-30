import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/models/entry.dart';
import '../../shared/widgets/page_header.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  const AddEntryScreen({super.key});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _title = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _website = TextEditingController();
  final _notes = TextEditingController();
  EntryCategory _category = EntryCategory.other;
  bool _favorite = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _password.dispose();
    _website.dispose();
    _notes.dispose();
    super.dispose();
  }

  int _strength(String p) {
    var score = 0;
    if (p.length >= 12) score++;
    if (p.length >= 16) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score;
  }

  Color _strengthColor(int s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final danger = isDark ? AppColors.dangerDark : AppColors.danger;
    final warning = isDark ? AppColors.warningDark : AppColors.warning;
    final success = isDark ? AppColors.successDark : AppColors.success;
    if (s <= 2) return danger;
    if (s <= 4) return warning;
    return success;
  }

  String _strengthLabel(int s) {
    if (s <= 2) return 'Weak';
    if (s <= 4) return 'Fair';
    if (s <= 5) return 'Good';
    return 'Strong';
  }

  void _generate() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final rng = Random.secure();
    final sb = StringBuffer();
    for (var i = 0; i < 16; i++) {
      sb.write(chars[rng.nextInt(chars.length)]);
    }
    _password.text = sb.toString();
    setState(() {});
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    final entry = VaultEntry(
      id: const Uuid().v4(),
      title: title,
      username: _username.text.trim().isEmpty ? null : _username.text.trim(),
      password: _password.text.isEmpty ? null : _password.text,
      website: _website.text.trim().isEmpty ? null : _website.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      category: _category,
      favorite: _favorite,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ref.read(vaultControllerProvider.notifier).addEntry(entry);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength(_password.text);
    // watch generated password from generator
    ref.listen<String?>(generatedPasswordProvider, (_, next) {
      if (next != null) {
        _password.text = next;
        ref.read(generatedPasswordProvider.notifier).state = null;
        setState(() {});
      }
    });
    return Scaffold(
      appBar: const PkAppBar(title: 'New password'),
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
          LinearProgressIndicator(
              value: (s / 6).clamp(0.0, 1.0),
              color: _strengthColor(s),
              backgroundColor: AppColors.border),
          const SizedBox(height: 4),
          Text(_strengthLabel(s),
              style: TextStyle(color: _strengthColor(s), fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton(onPressed: _generate, child: const Text('Generate')),
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
                onPressed: _save, child: const Text('Save password')),
          ),
        ],
      ),
    );
  }
}
