import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management_supabase/main.dart';
import 'package:hr_management_supabase/services/supabase_service.dart';

void main() {
  tearDown(EmployeeSession.signOut);

  testWidgets('renders the employee-aware login screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: HrApp()));
    await tester.pump();

    expect(find.text('Twenty Two'), findsOneWidget);
    expect(find.text('ยินดีต้อนรับ 👋'), findsOneWidget);
    expect(find.text('อีเมล'), findsOneWidget);
    expect(find.text('รหัสพนักงาน'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
  });

  testWidgets('wide login layout has bounded height',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: HrApp()));
    await tester.pump();

    expect(find.text('พื้นที่ทำงาน\nที่เข้าใจคุณ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
