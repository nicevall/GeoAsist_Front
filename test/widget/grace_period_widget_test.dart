// test/widget/grace_period_widget_test.dart
// 🧪 TEST COMPLETO PARA GracePeriodWidget
// Tests específicos para el widget de período de gracia completamente implementado

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geo_asist_front/screens/map_view/widgets/grace_period_widget.dart';
import 'package:geo_asist_front/utils/colors.dart';

// ✅ Helper class for animation testing
class TestVSync extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  group('GracePeriodWidget Complete Tests', () {
    late AnimationController graceController;
    late Animation<Color?> graceColorAnimation;

    setUp(() {
      graceController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: TestVSync(),
      );
      graceColorAnimation = ColorTween(
        begin: Colors.orange,
        end: Colors.red,
      ).animate(graceController);
    });

    tearDown(() {
      graceController.dispose();
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.orange,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryOrange,
          ),
        ),
        home: Scaffold(body: child),
      );
    }

    group('Basic Functionality Tests', () {
      testWidgets('renders without crashing', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 45,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        expect(find.byType(GracePeriodWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('displays grace period header correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 45,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Verificar header según implementación real
        expect(find.text('⏰ Período de Gracia'), findsOneWidget);
        expect(find.text('Regresa al área permitida'), findsOneWidget);
        expect(find.byIcon(Icons.access_time), findsOneWidget);
      });

      testWidgets('shows countdown for seconds only (< 60)', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 45,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Para 45 segundos, debe mostrar solo "45" (sin minutos)
        expect(find.text('45'), findsOneWidget);
        expect(find.text('segundos restantes'), findsOneWidget);
      });

      testWidgets('shows countdown in MM:SS format (≥ 60)', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 90, // 1:30
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Para 90 segundos, debe mostrar "1:30"
        expect(find.text('1:30'), findsOneWidget);
        expect(find.text('minutos restantes'), findsOneWidget);
      });
    });

    group('State-based Visual Changes', () {
      testWidgets('shows normal state (> 20 seconds)', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 30,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Estado normal - no urgente
        expect(find.text('⏰ Período de Gracia'), findsOneWidget);
        expect(find.byIcon(Icons.access_time), findsOneWidget);
        expect(find.text('🗺️ Tienes tiempo para regresar al área permitida'),
            findsOneWidget);
      });

      testWidgets('shows urgent state (≤ 20 seconds)', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 15,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Estado urgente
        expect(find.text('⏰ Período de Gracia'), findsOneWidget);
        expect(find.text('📍 Dirígete rápidamente al área del evento'),
            findsOneWidget);
        expect(find.byIcon(Icons.directions_walk), findsOneWidget);
      });

      testWidgets('shows critical state (≤ 10 seconds)', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 5,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Estado crítico
        expect(find.text('⚠️ URGENTE'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
        expect(find.text('🏃‍♂️ ¡Regresa AHORA o perderás la asistencia!'),
            findsOneWidget);
        expect(find.byIcon(Icons.directions_run), findsOneWidget);
      });
    });

    group('Progress Bar Tests', () {
      testWidgets('displays progress bar', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 30,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Verificar que existe la barra de progreso
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.textContaining('% transcurrido'), findsOneWidget);
      });

      testWidgets('shows correct progress percentage', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 30, // 30 de 60 = 50% transcurrido
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Con 30 segundos restantes de 60 total = 50% transcurrido
        expect(find.text('50% transcurrido'), findsOneWidget);
      });

      testWidgets('shows 0% at start (60 seconds)', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 60,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        expect(find.text('0% transcurrido'), findsOneWidget);
      });

      testWidgets('shows 100% at end (0 seconds)', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 0,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        expect(find.text('100% transcurrido'), findsOneWidget);
      });
    });

    group('Time Format Tests', () {
      testWidgets('formats different time values correctly', (tester) async {
        final testCases = [
          (0, '0'),
          (5, '5'),
          (15, '15'),
          (30, '30'),
          (59, '59'),
          (60, '1:00'),
          (75, '1:15'),
          (90, '1:30'),
          (120, '2:00'),
          (125, '2:05'),
        ];

        for (final (seconds, expectedDisplay) in testCases) {
          await tester.pumpWidget(
            createTestWidget(
              GracePeriodWidget(
                gracePeriodSeconds: seconds,
                graceColorAnimation: graceColorAnimation,
              ),
            ),
          );

          expect(find.text(expectedDisplay), findsOneWidget);

          // Limpiar para siguiente test
          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets('shows correct time labels', (tester) async {
        // Test segundos
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 45,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );
        expect(find.text('segundos restantes'), findsOneWidget);

        // Test minutos
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 90,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );
        expect(find.text('minutos restantes'), findsOneWidget);
      });
    });

    group('Animation Tests', () {
      testWidgets('has pulse animation controllers', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 30,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Verificar que las animaciones están configuradas
        // El widget tiene múltiples AnimatedBuilder (tema, app, widget)
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
        expect(find.byType(Transform),
            findsAtLeastNWidgets(2)); // Scale + Translate
      });

      testWidgets('applies shake animation for urgent state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 10, // Debería activar shake
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Pump algunas frames para activar animación
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Verificar que no hay errores de animación
        expect(tester.takeException(), isNull);
      });
    });

    group('Visual Elements Tests', () {
      testWidgets('displays all required visual elements', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 45,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Header elements
        expect(find.byIcon(Icons.access_time), findsOneWidget);
        expect(find.text('⏰ Período de Gracia'), findsOneWidget);
        expect(find.text('Regresa al área permitida'), findsOneWidget);

        // Countdown section
        expect(find.text('45'), findsOneWidget);
        expect(find.text('segundos restantes'), findsOneWidget);

        // Progress bar
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.textContaining('% transcurrido'), findsOneWidget);

        // Action message
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(
            find.textContaining('Tienes tiempo para regresar'), findsOneWidget);
      });

      testWidgets('has correct container structure', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 30,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Verificar estructura de containers
        expect(find.byType(Container), findsAtLeastNWidgets(4));
        expect(find.byType(Column), findsAtLeastNWidgets(3));
        expect(find.byType(Row), findsAtLeastNWidgets(2));
      });
    });

    group('Edge Cases Tests', () {
      testWidgets('handles zero seconds gracefully', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 0,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        expect(find.text('⚠️ URGENTE'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('segundos restantes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles large time values', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 300, // 5 minutos
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        expect(find.text('5:00'), findsOneWidget);
        expect(find.text('minutos restantes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('handles animation disposal correctly', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 30,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Widget exists
        expect(find.byType(GracePeriodWidget), findsOneWidget);

        // Dispose widget
        await tester.pumpWidget(const SizedBox());
        expect(find.byType(GracePeriodWidget), findsNothing);

        // Should not have animation errors
        expect(tester.takeException(), isNull);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('has proper semantic structure', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 30,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Verificar que los elementos de texto son accesibles
        expect(find.text('⏰ Período de Gracia'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
        expect(find.text('segundos restantes'), findsOneWidget);
      });

      testWidgets('supports high contrast themes', (tester) async {
        final highContrastTheme = ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.white,
          scaffoldBackgroundColor: Colors.black,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: highContrastTheme,
            home: Scaffold(
              body: GracePeriodWidget(
                gracePeriodSeconds: 30,
                graceColorAnimation: graceColorAnimation,
              ),
            ),
          ),
        );

        expect(find.byType(GracePeriodWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Performance Tests', () {
      testWidgets('renders quickly', (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 45,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        stopwatch.stop();

        // Should render in under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(find.byType(GracePeriodWidget), findsOneWidget);
      });

      testWidgets('handles rapid updates', (tester) async {
        // Simular cambios rápidos de tiempo
        for (int seconds = 60; seconds >= 0; seconds -= 10) {
          await tester.pumpWidget(
            createTestWidget(
              GracePeriodWidget(
                gracePeriodSeconds: seconds,
                graceColorAnimation: graceColorAnimation,
              ),
            ),
          );

          // Debe renderizar sin errores
          expect(find.byType(GracePeriodWidget), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });
    });

    group('Integration Tests', () {
      testWidgets('works with different color animations', (tester) async {
        // Test con animación diferente
        final redAnimation = ColorTween(
          begin: Colors.red,
          end: Colors.deepOrange,
        ).animate(graceController);

        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 15,
              graceColorAnimation: redAnimation,
            ),
          ),
        );

        expect(find.byType(GracePeriodWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('updates correctly when props change', (tester) async {
        // Estado inicial
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 60,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        expect(find.text('1:00'), findsOneWidget);

        // Cambiar a estado crítico
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 5,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        expect(find.text('⚠️ URGENTE'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });
    });
  });
}
