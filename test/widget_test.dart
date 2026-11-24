import 'package:caiheurang/core/utils/achievement_share_service.dart';
import 'package:caiheurang/features/home/widgets/plant_widget.dart';
import 'package:caiheurang/features/home/widgets/progress_ring.dart';
import 'package:caiheurang/shared/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
  });

  testWidgets('AchievementShareService renders all 3 card styles cleanly', (
    WidgetTester tester,
  ) async {
    for (final type in AchievementCardType.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: AchievementShareService.buildCard(
                  type: type,
                  name: 'Nadia',
                  totalMl: 2000,
                  targetMl: 2000,
                  currentLevel: 4,
                  totalXp: 1650,
                  streakDays: 7,
                  longestStreak: 14,
                  weeklyScore: 6,
                  date: DateTime(2026, 5, 15),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Nadia'), findsOneWidget);
      expect(find.text('💧 CaiHeurang'), findsOneWidget);
    }
  });

  testWidgets('PlantWidget & ProgressRing render all 7 levels and 5 moods cleanly', (
    WidgetTester tester,
  ) async {
    for (int level = 1; level <= 7; level++) {
      for (final mood in PlantMood.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ProgressRing(progress: level / 7, size: 220),
                    PlantWidget(
                      level: level,
                      mood: mood,
                      size: 130,
                      animate: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(find.byType(PlantWidget), findsOneWidget);
        expect(find.byType(ProgressRing), findsOneWidget);
      }
    }
  });
}
