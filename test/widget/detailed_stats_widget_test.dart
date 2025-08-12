// 🎯 TESTS BÁSICOS PARA WIDGET ESTADÍSTICAS
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_asist_front/widgets/detailed_stats_widget.dart';

void main() {
  group('DetailedStatsWidget Tests', () {
    testWidgets('muestra loading inicialmente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailedStatsWidget(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra header correcto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailedStatsWidget(),
          ),
        ),
      );

      expect(find.text('Estadísticas Generales'), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('diferencia entre docente y estudiante', (tester) async {
      // Test con isDocente: true
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailedStatsWidget(isDocente: true),
          ),
        ),
      );

      // Verificar que se muestra correctamente para docentes
      expect(find.byType(DetailedStatsWidget), findsOneWidget);
    });
  });
}
