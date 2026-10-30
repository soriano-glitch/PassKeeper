import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../shared/widgets/back_button.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Ticks only while a lockout is active: keeps the countdown fresh and the
    // Unlock button re-enabling on its own, without per-second rebuilds otherwise.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final s = ref.read(vaultControllerProvider);
      final active =
          s.lockoutUntil != null && DateTime.now().isBefore(s.lockoutUntil!);
      if (active) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await ref
          .read(vaultControllerProvider.notifier)
          .unlock(_password.text);
      if (!mounted) return;
      if (ok) {
        context.go('/vault');
      } else {
        final state = ref.read(vaultControllerProvider);
        setState(() => _error = state.error ?? 'Wrong password.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _biometric() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ctrl = ref.read(vaultControllerProvider.notifier);
      final ok = await ctrl.unlockWithBiometrics();
      if (!mounted) return;
      if (ok) {
        context.go('/vault');
      } else {
        // unlockWithBiometrics explains itself: unavailable device / not armed.
        final err = ref.read(vaultControllerProvider).error ??
            'Biometric unlock failed.';
        setState(() => _error = err);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _lockoutMessage(DateTime until) {
    final remaining = until.difference(DateTime.now());
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    if (m > 0) return 'Too many attempts. Locked for ${m}m ${s}s.';
    return 'Too many attempts. Locked for ${s}s.';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultControllerProvider);
    final lockedOut = state.lockoutUntil != null &&
        DateTime.now().isBefore(state.lockoutUntil!);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  PkBackButton(fallback: '/welcome'),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 56,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Unlock PassKeeper',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your master password to continue.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Master password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        ],
                        if (lockedOut) ...[
                          const SizedBox(height: 8),
                          Text(
                            _lockoutMessage(state.lockoutUntil!),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: (lockedOut || _busy) ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4),
                                  )
                                : const Text('Unlock'),
                          ),
                        ),
                        if (state.biometricsEnabled &&
                            !lockedOut &&
                            !_busy) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: _biometric,
                              child: const Text('Use biometrics'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
