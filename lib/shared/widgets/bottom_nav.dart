import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = cs.onSurface;
    final muted = cs.onSurfaceVariant;
    final gold = cs.primary;

    const items = <_NavItem>[
      _NavItem(label: 'Vault', icon: Icons.shield_rounded, path: '/vault'),
      _NavItem(
          label: 'Generator',
          icon: Icons.autorenew_rounded,
          path: '/generator'),
      _NavItem(
          label: 'Settings', icon: Icons.settings_rounded, path: '/settings'),
    ];

    return Material(
      color: cs.surface,
      child: SafeArea(
        top: false,
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outline)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(items.length, (i) {
              final isSelected = i == currentIndex;
              final color = isSelected ? selected : muted;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(items[i].path),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isSelected ? gold : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(items[i].icon, size: 24, color: color),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: color,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem({required this.label, required this.icon, required this.path});
}
