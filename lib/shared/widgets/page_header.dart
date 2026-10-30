import 'package:flutter/material.dart';

import 'back_button.dart';

/// Section header used by the root tabs (Vault, Generator, Settings).
class PkPageHeader extends StatelessWidget {
  const PkPageHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Bricolage Grotesque',
                fontWeight: FontWeight.w700,
                fontSize: 32,
                color: cs.onSurface,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// App bar with the shared circular back button and a title that truncates
/// instead of overflowing on narrow screens.
class PkAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PkAppBar({
    super.key,
    required this.title,
    this.actions,
    this.fallback = '/vault',
  });

  final String title;
  final List<Widget>? actions;
  final String fallback;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      titleSpacing: 20,
      leading: PkBackButton(fallback: fallback),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      actions: actions,
    );
  }
}

/// 44x44 circular icon button matching [PkBackButton].
class PkCircleIconButton extends StatelessWidget {
  const PkCircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: CircleBorder(side: BorderSide(color: cs.outline)),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, size: 22, color: cs.onSurface),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
