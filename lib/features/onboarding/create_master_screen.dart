import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/widgets/page_header.dart';

class CreateMasterScreen extends ConsumerStatefulWidget {
  const CreateMasterScreen({super.key});

  @override
  ConsumerState<CreateMasterScreen> createState() => _CreateMasterScreenState();
}

class _CreateMasterScreenState extends ConsumerState<CreateMasterScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _hasUpper(String p) => RegExp(r'[A-Z]').hasMatch(p);
  bool _hasLower(String p) => RegExp(r'[a-z]').hasMatch(p);
  bool _hasDigit(String p) => RegExp(r'[0-9]').hasMatch(p);
  bool _hasSymbol(String p) => RegExp(r'[^A-Za-z0-9]').hasMatch(p);

  int _strength(String p) {
    var score = 0;
    if (p.length >= 12) score++;
    if (p.length >= 16) score++;
    if (_hasUpper(p)) score++;
    if (_hasLower(p)) score++;
    if (_hasDigit(p)) score++;
    if (_hasSymbol(p)) score++;
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

  Future<void> _submit() async {
    final p = _password.text;
    final c = _confirm.text;
    if (p.length < 12) {
      setState(
          () => _error = 'Master password must be at least 12 characters.');
      return;
    }
    if (!(_hasUpper(p) && _hasLower(p) && _hasDigit(p) && _hasSymbol(p))) {
      setState(() => _error = 'Use upper, lower, number and symbol.');
      return;
    }
    if (p != c) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(vaultControllerProvider.notifier)
          .createVault(p)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      context.go('/vault');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not create the vault. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength(_password.text);
    return Scaffold(
      appBar: const PkAppBar(
        title: 'Create master password',
        fallback: '/welcome',
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'This password protects your vault. '
            'It never leaves your device. If you forget it, your data cannot be recovered.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _password,
            obscureText: _obscure,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Master password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (s / 6).clamp(0.0, 1.0),
            color: _strengthColor(s),
            backgroundColor: AppColors.border,
          ),
          const SizedBox(height: 4),
          Text(
            _strengthLabel(s),
            style: TextStyle(color: _strengthColor(s), fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm password'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('Creating your vault...'),
                      ],
                    )
                  : const Text('Create vault'),
            ),
          ),
        ],
      ),
    );
  }
}
