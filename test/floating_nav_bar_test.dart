import 'package:dipi/core/theme/app_theme.dart';
import 'package:dipi/core/widgets/floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _items = [
  FloatingNavItem(
    label: 'تقویم',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  FloatingNavItem(
    label: 'کارفرماها',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  FloatingNavItem(
    label: 'پرداخت‌ها',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  FloatingNavItem(
    label: 'آمار',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<int> onSelected,
  bool reduceMotion = false,
}) async {
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FloatingNavBar(
              selectedIndex: 0,
              items: _items,
              onSelected: (index) {
                onSelected(index);
                setState(() {});
              },
              primaryAction: FloatingNavPrimaryAction(
                icon: Icons.add_rounded,
                label: 'روزکار',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a label for every item, including the primary action', (
    tester,
  ) async {
    await _pump(tester, onSelected: (_) {});
    expect(find.text('تقویم'), findsOneWidget);
    expect(find.text('کارفرماها'), findsOneWidget);
    expect(find.text('پرداخت‌ها'), findsOneWidget);
    expect(find.text('آمار'), findsOneWidget);
    expect(find.text('روزکار'), findsOneWidget);
    // Every tab carries a semantic label for screen readers.
    expect(find.bySemanticsLabel('آمار'), findsOneWidget);
  });

  testWidgets('reports the tapped tab', (tester) async {
    int? tapped;
    await _pump(tester, onSelected: (index) => tapped = index);
    await tester.tap(find.text('آمار'));
    await tester.pumpAndSettle();
    expect(tapped, 3);
  });

  testWidgets('works with reduce motion on', (tester) async {
    int? tapped;
    await _pump(
      tester,
      onSelected: (index) => tapped = index,
      reduceMotion: true,
    );
    await tester.tap(find.text('پرداخت‌ها'));
    await tester.pumpAndSettle();
    expect(tapped, 2);
  });
}
