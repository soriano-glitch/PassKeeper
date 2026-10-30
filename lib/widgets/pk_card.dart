import 'package:flutter/material.dart';

class PkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool showBorder;

  const PkCard({
    super.key,
    required this.child,
    this.margin,
    this.radius = 16,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: showBorder ? BorderSide(color: border) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: child,
      ),
    );
  }
}
