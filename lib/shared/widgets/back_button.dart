import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Circular back button used in every screen header.
///
/// Always renders at a fixed 44x44 size. The [Align] wrapper lets the same
/// widget sit in a regular row and inside an [AppBar.leading] slot (which
/// hands its child tight constraints) without stretching the circle.
class PkBackButton extends StatelessWidget {
  const PkBackButton({
    super.key,
    this.fallback = '/vault',
    this.onPressed,
    this.tooltip = 'Back',
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
  });

  /// Route used when there is nothing to pop (e.g. deep links, `go()`).
  final String fallback;

  /// Optional custom action (e.g. leaving the app from the root screen).
  final VoidCallback? onPressed;

  final String tooltip;

  /// Optional colors for use on dark or transparent backgrounds.
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.center,
      widthFactor: 1,
      heightFactor: 1,
      child: Material(
        color: backgroundColor ?? cs.surface,
        shape: CircleBorder(side: BorderSide(color: borderColor ?? cs.outline)),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              size: 22, color: iconColor ?? cs.onSurface),
          onPressed: onPressed ?? () => _popOrGo(context, fallback),
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const CircleBorder(),
          ),
        ),
      ),
    );
  }

  static void _popOrGo(BuildContext context, String fallback) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallback);
    }
  }
}
