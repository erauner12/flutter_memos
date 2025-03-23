// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter/material.dart';
import 'package:flutter_memos/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Build our app inside a ProviderScope
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that our app initializes correctly
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.text('Flutter Memos'), findsOneWidget);
    
    // Wait for all animations to complete
    await tester.pumpAndSettle();
    
    // Verify some basic elements of our UI exist
    expect(find.byType(AppBar), findsWidgets);
    expect(find.byType(FloatingActionButton), findsAtLeastNWidgets(1));
  });
}
