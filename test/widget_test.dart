import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_maintenance/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the maintenance dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1200, 1000));

    await tester.pumpWidget(const HomeMaintenanceApp());
    await tester.pumpAndSettle();

    expect(find.text('Home Maintenance'), findsWidgets);
    expect(find.text('Monthly expenses'), findsOneWidget);
    expect(find.text('House-wise dues'), findsOneWidget);
  });
}
