// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// 패키지명 몰라도 작동하게 상대 경로로 임포트
import '../lib/main.dart';

void main() {
  testWidgets('앱이 정상 빌드되고 MaterialApp을 포함한다', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
