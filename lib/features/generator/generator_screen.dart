import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/utils/clipboard_service.dart';
import '../../shared/widgets/back_button.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/pk_switch.dart';
import '../../widgets/pk_card.dart';

class GeneratorScreen extends ConsumerStatefulWidget {
  const GeneratorScreen({super.key});

  @override
  ConsumerState<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends ConsumerState<GeneratorScreen> {
  double _length = 16;
  bool _lower = true;
  bool _upper = true;
  bool _numbers = true;
  bool _symbols = true;
  String _password = '';

  static const _lowerChars = 'abcdefghijklmnopqrstuvwxyz';
  static const _upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _numberChars = '0123456789';
  static const _symbolChars = '!@#\$%^&*()-_=+[]{};:,.<>?';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final pool = StringBuffer();
    if (_lower) pool.write(_lowerChars);
    if (_upper) pool.write(_upperChars);
    if (_numbers) pool.write(_numberChars);
    if (_symbols) pool.write(_symbolChars);
    if (pool.isEmpty) {
      setState(() => _password = '');
      return;
    }
    final chars = pool.toString();
    final rng = Random.secure();
    final len = _length.round();
    final sb = StringBuffer();
    for (var i = 0; i < len; i++) {
      sb.write(chars[rng.nextInt(chars.length)]);
    }
    setState(() => _password = sb.toString());
  }

  String get _strengthLabel {
    final len = _length.round();
    if (len < 12) return 'Weak: use at least 12 characters';
    var types = 0;
    if (_lower) types++;
    if (_upper) types++;
    if (_numbers) types++;
    if (_symbols) types++;
    if (len >= 16 && types >= 3) return 'Strong: would take centuries to guess';
    if (len >= 12 && types >= 2) return 'Fair: add more characters';
    return 'Fair: add more characters';
  }

  Future<void> _copy() async {
    if (_password.isEmpty) return;
    final secs = ref.read(clipboardClearSecondsProvider);
    await ClipboardService.copy(_password, seconds: secs);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied. Clears in $secs seconds.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final teal = cs.onSurface;
    final muted = cs.onSurfaceVariant;
    const gold = AppColors.gold;
    final strengthText = _strengthLabel;
    final isStrong = strengthText.startsWith('Strong');
    final isFair = strengthText.startsWith('Fair');
    final strengthColor = isStrong
        ? AppColors.success
        : (isFair ? AppColors.warning : AppColors.danger);
    final strengthSegments = isStrong ? 4 : (isFair ? 3 : 1);

    final canPop = GoRouter.maybeOf(context)?.canPop() ?? false;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/vault');
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PkPageHeader(
                title: 'Generator',
                leading: const PkBackButton(fallback: '/vault'),
                trailing: PkCircleIconButton(
                  icon: Icons.lock_rounded,
                  tooltip: 'Lock vault',
                  onPressed: () {
                    ref.read(vaultControllerProvider.notifier).lock();
                    if (mounted) context.go('/unlock');
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _password,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 24,
                              height: 1.3,
                              color: teal,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Row(
                              children: [
                                for (var i = 0; i < 4; i++) ...[
                                  if (i > 0) const SizedBox(width: 3),
                                  Expanded(
                                    child: Container(
                                      height: 8,
                                      color: i < strengthSegments
                                          ? strengthColor
                                          : cs.outlineVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strengthText,
                            style: TextStyle(fontSize: 14, color: muted),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Length: ${_length.round()} characters',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: teal,
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: gold,
                              inactiveTrackColor: cs.outlineVariant,
                              thumbColor: gold,
                              overlayColor: gold.withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: _length,
                              min: 8,
                              max: 32,
                              divisions: 24,
                              label: _length.round().toString(),
                              onChanged: (v) => setState(() => _length = v),
                              onChangeEnd: (_) => _generate(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: cs.primary,
                                      side: BorderSide(
                                          color: cs.primary, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      textStyle: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: _generate,
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Generate new'),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: gold,
                                      foregroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      textStyle: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: _copy,
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Copy password'),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PkCard(
                      radius: 22,
                      showBorder: false,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Column(
                          children: [
                            _ToggleTile(
                                title: 'Lowercase letters',
                                value: _lower,
                                onChanged: (v) {
                                  setState(() => _lower = v);
                                  _generate();
                                }),
                            const Divider(height: 1),
                            _ToggleTile(
                                title: 'Uppercase letters',
                                value: _upper,
                                onChanged: (v) {
                                  setState(() => _upper = v);
                                  _generate();
                                }),
                            const Divider(height: 1),
                            _ToggleTile(
                                title: 'Numbers',
                                value: _numbers,
                                onChanged: (v) {
                                  setState(() => _numbers = v);
                                  _generate();
                                }),
                            const Divider(height: 1),
                            _ToggleTile(
                                title: 'Symbols',
                                value: _symbols,
                                onChanged: (v) {
                                  setState(() => _symbols = v);
                                  _generate();
                                }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNav(currentIndex: 1),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile(
      {required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          PkSwitch(value: value, onChanged: onChanged, label: title),
        ],
      ),
    );
  }
}
