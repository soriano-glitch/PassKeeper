import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../shared/widgets/back_button.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasVault = ref.watch(vaultControllerProvider).hasVault;
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = (width * 44 / 390).clamp(32.0, 44.0);
    const teal = Color(0xFF10302E);
    const mint = Color(0xFFF3F6F5);
    const muted = Color(0xFFBFD3D0);
    const footer = Color(0xFF9DB8B4);
    const gold = Color(0xFFE8B04A);
    const border = Color(0xFF5E8B86);

    return Scaffold(
      backgroundColor: teal,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Leave enough room for the copy and buttons; only the illustration
                // shrinks on short screens, and the whole page stays scrollable.
                final illustrationHeight =
                    (constraints.maxHeight - 420).clamp(140.0, 400.0);
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 480,
                                  maxHeight: illustrationHeight,
                                ),
                                child: const AspectRatio(
                                  aspectRatio: 390 / 400,
                                  child: ClipRect(
                                    child: CustomPaint(
                                      painter: _KeyIllustrationPainter(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Every password.\nOne master key.',
                                      style: TextStyle(
                                        fontFamily: 'Bricolage Grotesque',
                                        fontWeight: FontWeight.w700,
                                        fontSize: titleSize,
                                        height: 1.04,
                                        color: mint,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'PassKeeper keeps your logins encrypted on this phone. '
                                    'Nothing is sent anywhere.',
                                    style: TextStyle(
                                      fontSize: 17,
                                      height: 1.5,
                                      color: muted,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  SizedBox(
                                    height: 56,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: gold,
                                        foregroundColor: teal,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        textStyle: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      onPressed: hasVault
                                          ? () => context.push('/unlock')
                                          : () =>
                                              context.push('/create-master'),
                                      child: Text(hasVault
                                          ? 'Unlock your vault'
                                          : 'Create master password'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 56,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: mint,
                                        side: const BorderSide(
                                            color: border, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        textStyle: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onPressed: hasVault
                                          ? () => _confirmNewVault(context)
                                          : () => context.push('/unlock'),
                                      child: Text(hasVault
                                          ? 'Create new vault (erases current)'
                                          : 'I already have a vault'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Center(
                                    child: Text(
                                      'Works offline. No account needed.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 14, color: footer),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 28,
              left: 20,
              child: PkBackButton(
                tooltip: 'Back to dashboard',
                onPressed: () => context.go('/vault'),
                backgroundColor: Colors.transparent,
                borderColor: border,
                iconColor: mint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Creating a vault over an existing one erases every entry — confirm first.
Future<void> _confirmNewVault(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Create a new vault?'),
      content:
          const Text('This erases your current vault and every entry in it.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase and create')),
      ],
    ),
  );
  if (ok == true && context.mounted) context.push('/create-master');
}

class _KeyIllustrationPainter extends CustomPainter {
  const _KeyIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // scale from 390x400 design space
    final sx = size.width / 390;
    final sy = size.height / 400;
    canvas.scale(sx, sy);

    final thin = Paint()
      ..color = const Color(0xFF1D4A46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(const Offset(270, 190), 190, thin);
    canvas.drawCircle(const Offset(270, 190), 150, thin);

    final mid = Paint()
      ..color = const Color(0xFF2F6F68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(const Offset(270, 190), 110, mid);

    canvas.save();
    canvas.translate(270, 190);
    canvas.rotate(32 * 3.14159265 / 180);
    canvas.translate(-270, -190);

    final goldStroke = Paint()
      ..color = const Color(0xFFE8B04A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30;
    canvas.drawCircle(const Offset(270, 190), 62, goldStroke);

    final goldFill = Paint()..color = const Color(0xFFE8B04A);
    canvas.drawRect(const Rect.fromLTWH(257, 250, 26, 250), goldFill);
    canvas.drawRect(const Rect.fromLTWH(283, 400, 44, 22), goldFill);
    canvas.drawRect(const Rect.fromLTWH(283, 440, 32, 22), goldFill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
