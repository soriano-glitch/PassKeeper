import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:passkeeper/shared/widgets/page_header.dart';

void main() {
  testWidgets('back button pops when there is history', (tester) async {
    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/child'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/child',
          builder: (_, __) => const Scaffold(
            appBar: PkAppBar(title: 'Child'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Child'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('back button uses fallback when opened directly', (tester) async {
    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/child',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/child',
          builder: (_, __) => const Scaffold(
            appBar: PkAppBar(title: 'Child', fallback: '/home'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Child'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
