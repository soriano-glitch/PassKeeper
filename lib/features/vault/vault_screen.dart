import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/utils/clipboard_service.dart';
import '../../shared/models/entry.dart';
import '../../shared/widgets/back_button.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/page_header.dart';
import '../../widgets/pk_card.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  EntryCategory? _filter;
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _weakOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _strengthOf(VaultEntry e) {
    final p = e.password ?? '';
    if (p.length < 12) return 'Weak';
    var types = 0;
    if (RegExp(r'[a-z]').hasMatch(p)) types++;
    if (RegExp(r'[A-Z]').hasMatch(p)) types++;
    if (RegExp(r'[0-9]').hasMatch(p)) types++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) types++;
    if (types < 2) return 'Weak';
    if (p.length < 16 || types < 3) return 'Fair';
    return 'Strong';
  }

  Color _strengthColor(String s, Brightness brightness) {
    switch (s) {
      case 'Strong':
        return brightness == Brightness.dark
            ? AppColors.successDark
            : AppColors.success;
      case 'Fair':
        return brightness == Brightness.dark
            ? AppColors.warningDark
            : AppColors.warning;
      case 'Weak':
        return brightness == Brightness.dark
            ? AppColors.dangerDark
            : AppColors.danger;
      default:
        return brightness == Brightness.dark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary;
    }
  }

  List<VaultEntry> _filtered(List<VaultEntry> entries) {
    var list = entries;
    if (_filter != null) {
      list = list.where((e) => e.category == _filter).toList();
    }
    if (_weakOnly) {
      list = list.where((e) => _strengthOf(e) == 'Weak').toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where(
            (e) =>
                e.title.toLowerCase().contains(q) ||
                (e.username?.toLowerCase().contains(q) ?? false) ||
                (e.website?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    list.sort((a, b) {
      if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
      return a.title.compareTo(b.title);
    });
    return list;
  }

  Future<void> _copy(VaultEntry e) async {
    final secs = ref.read(clipboardClearSecondsProvider);
    await ClipboardService.copy(e.password ?? '', seconds: secs);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied. Clears in $secs seconds.')),
    );
  }

  void _lock() {
    ref.read(vaultControllerProvider.notifier).lock();
    if (mounted) context.go('/unlock');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final teal = cs.onSurface;
    final border = cs.outline;
    final muted = cs.onSurfaceVariant;
    const gold = AppColors.gold;

    final state = ref.watch(vaultControllerProvider);
    final entries = state.entries;
    final total = entries.length;
    final strong = entries.where((e) => _strengthOf(e) == 'Strong').length;
    final fair = entries.where((e) => _strengthOf(e) == 'Fair').length;
    final weak = entries.where((e) => _strengthOf(e) == 'Weak').length;
    final filtered = _filtered(entries);

    const tints = [
      Color(0xFFCFE3F5),
      Color(0xFFD6EEDC),
      Color(0xFFF7E6BE),
      Color(0xFFF9D5CC),
      Color(0xFFE3DCF3),
    ];

    // Summary card: branded dark teal in light mode, dark card tone in dark mode.
    final summaryColor =
        brightness == Brightness.dark ? cs.surface : AppColors.primary;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: gold,
        foregroundColor: AppColors.primary,
        elevation: 2,
        onPressed: () => context.push('/add-entry'),
        tooltip: 'Add password',
        child: const Icon(Icons.add_rounded, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            PkPageHeader(
              title: 'Vault',
              leading: PkBackButton(
                tooltip: 'Back to welcome',
                onPressed: () => context.go('/welcome'),
              ),
              trailing: PkCircleIconButton(
                icon: Icons.lock_rounded,
                tooltip: 'Lock vault',
                onPressed: _lock,
              ),
            ),
            Expanded(
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SummaryCard(
                            total: total,
                            strong: strong,
                            fair: fair,
                            weak: weak,
                            color: summaryColor,
                            isDark: brightness == Brightness.dark,
                            borderColor: cs.outline,
                            onFixWeak: () => setState(() {
                              _weakOnly = true;
                              _filter = null;
                              _query = '';
                              _search.clear();
                            }),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              border: Border.all(color: border),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search_rounded,
                                    size: 20, color: muted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _search,
                                    textInputAction: TextInputAction.search,
                                    onChanged: (v) =>
                                        setState(() => _query = v),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Search $total passwords',
                                    ),
                                    style: TextStyle(fontSize: 16, color: teal),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 44,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _Chip(
                                  label: 'All',
                                  selected: _filter == null && !_weakOnly,
                                  onTap: () => setState(() {
                                    _filter = null;
                                    _weakOnly = false;
                                  }),
                                ),
                                ...['Social', 'Banking', 'Work'].map((name) {
                                  final cat = _categoryFromLabel(name);
                                  return _Chip(
                                    label: name,
                                    selected: _filter == cat && !_weakOnly,
                                    onTap: () => setState(() {
                                      _filter = cat;
                                      _weakOnly = false;
                                    }),
                                  );
                                }),
                              ],
                            ),
                          ),
                          if (_weakOnly) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Showing weak passwords only',
                                    style: TextStyle(fontSize: 15, color: teal),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _weakOnly = false),
                                  child: Text(
                                    'Show all',
                                    style: TextStyle(
                                      color: teal,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: filtered.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 48, 8, 32),
                              child: Text(
                                total == 0
                                    ? 'No passwords yet. Tap + to add your first one.'
                                    : 'No passwords match. Try a different word or choose All.',
                                style: TextStyle(fontSize: 16, color: muted),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : SliverList.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final e = filtered[i];
                              return _EntryRow(
                                entry: e,
                                tint: tints[i % tints.length],
                                strength: _strengthOf(e),
                                strengthColor: _strengthColor(
                                  _strengthOf(e),
                                  brightness,
                                ),
                                onTap: () => context.push('/entry/${e.id}'),
                                onCopy: () => _copy(e),
                              );
                            },
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  EntryCategory? _categoryFromLabel(String label) {
    switch (label) {
      case 'Social':
        return EntryCategory.social;
      case 'Banking':
        return EntryCategory.banking;
      case 'Work':
        return EntryCategory.work;
      default:
        return null;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.strong,
    required this.fair,
    required this.weak,
    required this.color,
    required this.isDark,
    required this.borderColor,
    required this.onFixWeak,
  });

  final int total;
  final int strong;
  final int fair;
  final int weak;
  final Color color;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onFixWeak;

  @override
  Widget build(BuildContext context) {
    const gold = AppColors.gold;
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: isDark ? borderColor : Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$total passwords saved',
              style: const TextStyle(
                fontFamily: 'Bricolage Grotesque',
                fontWeight: FontWeight.w600,
                fontSize: 24,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 14),
            _StrengthBar(
              strong: strong,
              fair: fair,
              weak: weak,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _Legend('$strong strong'),
                _Legend('$fair fair'),
                _Legend('$weak weak'),
              ],
            ),
            if (weak > 0) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onFixWeak,
                  child: Text('Fix $weak weak passwords'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: Color(0xFFBFD3D0)),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({
    required this.strong,
    required this.fair,
    required this.weak,
    required this.isDark,
  });

  final int strong;
  final int fair;
  final int weak;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    void add(int count, Color color) {
      if (count <= 0) return;
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: 3));
      }
      children.add(Expanded(flex: count, child: Container(color: color)));
    }

    add(strong, AppColors.switchOnTrack);
    add(fair, AppColors.gold);
    add(weak, AppColors.dangerDark);

    if (children.isEmpty) {
      children.add(
        Expanded(
          child: Container(
            color: isDark ? AppColors.borderDark : const Color(0xFF2F5A56),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(children: children),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.tint,
    required this.strength,
    required this.strengthColor,
    required this.onTap,
    required this.onCopy,
  });

  final VaultEntry entry;
  final Color tint;
  final String strength;
  final Color strengthColor;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant;
    return PkCard(
      showBorder: false,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.title.isNotEmpty ? entry.title[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontFamily: 'Bricolage Grotesque',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.username ?? entry.website ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strength,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: strengthColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy_rounded, size: 20, color: cs.onSurface),
                onPressed: onCopy,
                tooltip: 'Copy password',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 44, height: 44),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            border: Border.all(color: selected ? cs.primary : cs.outline),
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: selected
                  ? (isDark ? AppColors.onAccent : AppColors.surface)
                  : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
