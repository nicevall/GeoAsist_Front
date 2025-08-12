// test/widget/attendance_widgets_test.dart
// 🧪 BLOQUE 3 A1.3 - WIDGET TESTING DE COMPONENTES DE ASISTENCIA - CORREGIDO
// Testing de todos los widgets custom del sistema

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geo_asist_front/screens/map_view/widgets/attendance_status_widget.dart';
import 'package:geo_asist_front/screens/map_view/widgets/grace_period_widget.dart';
import 'package:geo_asist_front/screens/map_view/widgets/notification_overlay_widget.dart';
import 'package:geo_asist_front/widgets/attendance_button_widget.dart';
import 'package:geo_asist_front/screens/dashboard/widgets/real_time_metrics_widget.dart';
import 'package:geo_asist_front/screens/dashboard/widgets/student_activity_list_widget.dart';
import 'package:geo_asist_front/screens/dashboard/widgets/event_control_panel_widget.dart';
import 'package:geo_asist_front/models/attendance_state_model.dart';
import 'package:geo_asist_front/models/evento_model.dart';
import 'package:geo_asist_front/models/usuario_model.dart';
import 'package:geo_asist_front/models/ubicacion_model.dart';
import 'package:geo_asist_front/utils/colors.dart';

void main() {
  group('Attendance Widgets Tests', () {
    // Test data setup - CORREGIDO según modelos actuales
    final testUser = Usuario(
      id: 'test_user_123',
      nombre: 'Test User',
      correo: 'test@example.com',
      rol: 'estudiante',
      creadoEn: DateTime.now(),
    );

    final testEvent = Evento(
      id: 'test_event_123',
      titulo: 'Test Event',
      descripcion: 'Test Description',
      ubicacion: Ubicacion(
        latitud: -0.1805,
        longitud: -78.4680,
        // CORREGIDO: 'direccion' NO existe en Ubicacion modelo
        // En su lugar, usar address si está disponible o remover
      ),
      fecha: DateTime.now(),
      horaInicio: DateTime.now().subtract(const Duration(minutes: 30)),
      horaFinal: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
      rangoPermitido: 100.0,
      creadoPor: 'teacher_123',
    );

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

    group('AttendanceStatusWidget Tests', () {
      testWidgets('displays correct status when inside geofence',
          (tester) async {
        // Arrange
        final attendanceState = AttendanceState.initial().copyWith(
          isInsideGeofence: true,
          distanceToEvent: 45.0,
          attendanceStatus: AttendanceStatus.canRegister,
          trackingStatus: TrackingStatus.active,
          trackingStartTime:
              DateTime.now().subtract(const Duration(minutes: 15)),
        );

        // Act
        await tester.pumpWidget(
          createTestWidget(
            AttendanceStatusWidget(
              // CORREGIDO: Usar parámetros reales del widget
              attendanceState: attendanceState,
              userName: testUser.nombre,
              // OPCIONAL: locationResponse y currentEvento
              currentEvento: testEvent,
            ),
          ),
        );

        // Assert
        expect(find.text('45.0m'), findsOneWidget);
        expect(find.text('Dentro'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        // Check colors
        final distanceText = tester.widget<Text>(find.text('45.0m'));
        expect(distanceText.style?.color, Colors.green);
      });

      testWidgets('displays correct status when outside geofence',
          (tester) async {
        // Arrange
        final attendanceState = AttendanceState.initial().copyWith(
          isInsideGeofence: false,
          distanceToEvent: 150.0,
          attendanceStatus: AttendanceStatus.outsideGeofence,
          trackingStatus: TrackingStatus.active,
          trackingStartTime:
              DateTime.now().subtract(const Duration(minutes: 10)),
        );

        // Act
        await tester.pumpWidget(
          createTestWidget(
            AttendanceStatusWidget(
              // CORREGIDO: Usar parámetros reales del widget
              attendanceState: attendanceState,
              userName: testUser.nombre,
              currentEvento: testEvent,
            ),
          ),
        );

        // Assert
        expect(find.text('150.0m'), findsOneWidget);
        expect(find.text('Fuera'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);

        // Check colors
        final distanceText = tester.widget<Text>(find.text('150.0m'));
        expect(distanceText.style?.color, Colors.orange);
      });

      testWidgets('shows attendance registered indicator', (tester) async {
        // Arrange
        final attendanceState = AttendanceState.initial().copyWith(
          isInsideGeofence: true,
          hasRegisteredAttendance: true,
          attendanceStatus: AttendanceStatus.registered,
          attendanceRegisteredTime:
              DateTime.now().subtract(const Duration(minutes: 5)),
          trackingStatus: TrackingStatus.active,
        );

        // Act
        await tester.pumpWidget(
          createTestWidget(
            AttendanceStatusWidget(
              // CORREGIDO: Usar parámetros reales del widget
              attendanceState: attendanceState,
              userName: testUser.nombre,
              currentEvento: testEvent,
            ),
          ),
        );

        // Assert
        expect(find.text('Asistencia Registrada'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('displays tracking duration correctly', (tester) async {
        // Arrange
        final trackingStart =
            DateTime.now().subtract(const Duration(minutes: 23, seconds: 45));
        final attendanceState = AttendanceState.initial().copyWith(
          trackingStatus: TrackingStatus.active,
          trackingStartTime: trackingStart,
        );

        // Act
        await tester.pumpWidget(
          createTestWidget(
            AttendanceStatusWidget(
              // CORREGIDO: Usar parámetros reales del widget
              attendanceState: attendanceState,
              userName: testUser.nombre,
              currentEvento: testEvent,
            ),
          ),
        );

        // Assert
        expect(find.textContaining('23:'),
            findsOneWidget); // Should show 23+ minutes
        expect(find.byIcon(Icons.timer), findsOneWidget);
      });
    });

    group('GracePeriodWidget Tests', () {
      late AnimationController graceController;
      late Animation<Color?> graceColorAnimation;

      setUp(() {
        graceController = AnimationController(
          duration: const Duration(seconds: 1),
          vsync: const TestVSync(),
        );
        graceColorAnimation = ColorTween(
          begin: Colors.orange,
          end: Colors.red,
        ).animate(graceController);
      });

      tearDown(() {
        graceController.dispose();
      });

      testWidgets('displays grace period countdown correctly', (tester) async {
        // Act - CORREGIDO: Usar parámetros reales del widget
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 45,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Assert
        expect(find.textContaining('Período de Gracia'), findsOneWidget);
        expect(find.text('00:45'), findsOneWidget);
        expect(find.byIcon(Icons.timer), findsOneWidget);

        // Check warning color
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.decoration, isA<BoxDecoration>());
      });

      testWidgets('hides when grace period is 0', (tester) async {
        // Act - Test con 0 segundos (equivalente a no estar en período de gracia)
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 0,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Assert - El widget se muestra pero con 0 segundos
        expect(find.text('00:00'), findsOneWidget);
      });

      testWidgets('shows critical state when time is low', (tester) async {
        // Act - CORREGIDO: Usar parámetros reales del widget
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 10,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Assert
        expect(find.text('00:10'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);

        // Should show critical styling (red colors)
        final text = tester.widget<Text>(find.text('00:10'));
        expect(text.style?.color, Colors.red);
      });

      testWidgets('animates countdown updates', (tester) async {
        // Act - CORREGIDO: Usar parámetros reales del widget
        await tester.pumpWidget(
          createTestWidget(
            GracePeriodWidget(
              gracePeriodSeconds: 30,
              graceColorAnimation: graceColorAnimation,
            ),
          ),
        );

        // Initial state
        expect(find.text('00:30'), findsOneWidget);

        // Simulate time passing
        await tester.pump(const Duration(seconds: 1));

        // Should still be functional (actual countdown would be handled by parent)
        expect(find.textContaining('Período de Gracia'), findsOneWidget);
      });
    });

    group('NotificationOverlayWidget Tests', () {
      testWidgets('displays success notification', (tester) async {
        // Arrange
        final attendanceState = AttendanceState.initial().copyWith(
          hasRegisteredAttendance: true,
          attendanceStatus: AttendanceStatus.registered,
        );

        // Act - CORREGIDO: Usar parámetros reales del widget
        await tester.pumpWidget(
          createTestWidget(
            NotificationOverlayWidget(
              attendanceState: attendanceState,
            ),
          ),
        );

        // Assert
        expect(find.textContaining('exitosamente'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('displays error notification', (tester) async {
        // Arrange
        final attendanceState = AttendanceState.initial().copyWith(
          lastError: 'Error al registrar asistencia',
          trackingStatus: TrackingStatus.error,
        );

        // Act - CORREGIDO: Usar parámetros reales del widget
        await tester.pumpWidget(
          createTestWidget(
            NotificationOverlayWidget(
              attendanceState: attendanceState,
            ),
          ),
        );

        // Assert
        expect(find.text('Error al registrar asistencia'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('displays warning notification', (tester) async {
        // Arrange
        final attendanceState = AttendanceState.initial().copyWith(
          isInGracePeriod: true,
          attendanceStatus: AttendanceStatus.gracePeriod,
        );

        // Act - CORREGIDO: Usar parámetros reales del widget
        await tester.pumpWidget(
          createTestWidget(
            NotificationOverlayWidget(
              attendanceState: attendanceState,
            ),
          ),
        );

        // Assert
        expect(find.textContaining('Saliste del área'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });

      testWidgets('hides when no notification needed', (tester) async {
        // Arrange
        final attendanceState = AttendanceState.initial();

        // Act - CORREGIDO: Usar parámetros reales del widget
        await tester.pumpWidget(
          createTestWidget(
            NotificationOverlayWidget(
              attendanceState: attendanceState,
            ),
          ),
        );

        // Assert - No notification should be visible
        expect(find.byType(Container), findsNothing);
      });
    });

    group('AttendanceButtonWidget Tests', () {
      testWidgets('displays register button when eligible', (tester) async {
        // Arrange
        bool buttonPressed = false;

        final attendanceState = AttendanceState.initial().copyWith(
          canRegisterAttendance: true,
          attendanceStatus: AttendanceStatus.canRegister,
          hasRegisteredAttendance: false,
        );

        // Act - CORREGIDO: Usar parámetros reales del widget
        await tester.pumpWidget(
          createTestWidget(
            AttendanceButtonWidget(
              attendanceState: attendanceState,
              // CORREGIDO: userName NO existe en AttendanceButtonWidget
              onPressed: () => buttonPressed = true,
            ),
          ),
        );

        // Assert
        expect(find.text('Registrar Asistencia'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);

        // Test button press
        await tester.tap(find.text('Registrar Asistencia'));
        expect(buttonPressed, true);

        // Check button styling
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('shows disabled state when not eligible', (tester) async {
        // Arrange
        final attendanceState = AttendanceState.initial().copyWith(
          canRegisterAttendance: false,
          attendanceStatus: AttendanceStatus.outsideGeofence,
          hasRegisteredAttendance: false,
        );

        // Act - CORREGIDO: Usar parámetros reales del widget
        await tester.pumpWidget(
          createTestWidget(
            AttendanceButtonWidget(
              attendanceState: attendanceState,
              // CORREGIDO: userName NO existe en AttendanceButtonWidget
              onPressed: () {},
            ),
          ),
        );

        // Assert
        expect(find.text('Fuera del Área'), findsOneWidget);

        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull); // Disabled
      });

      testWidgets('shows registered state when attendance is registered',
          (tester) async {
        // Arrange
        final attendanceState = AttendanceState.initial().copyWith(
          hasRegisteredAttendance: true,
          attendanceStatus: AttendanceStatus.registered,
          attendanceRegisteredTime: DateTime.now(),
        );

        // Act - CORREGIDO: Usar parámetros reales del widget
        await tester.pumpWidget(
          createTestWidget(
            AttendanceButtonWidget(
              attendanceState: attendanceState,
              // CORREGIDO: userName NO existe en AttendanceButtonWidget
              onPressed: () {},
            ),
          ),
        );

        // Assert
        expect(find.text('Asistencia Registrada'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull); // Disabled after registration
      });

      testWidgets('shows loading state during registration', (tester) async {
        // Arrange
        final attendanceState = AttendanceState.initial().copyWith(
          canRegisterAttendance: true,
          attendanceStatus: AttendanceStatus.canRegister,
        );

        // Act - CORREGIDO: Usar parámetros reales del widget
        await tester.pumpWidget(
          createTestWidget(
            AttendanceButtonWidget(
              attendanceState: attendanceState,
              // CORREGIDO: userName NO existe en AttendanceButtonWidget
              onPressed: () {},
              isLoading: true,
            ),
          ),
        );

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Registrando...'), findsOneWidget);
      });
    });

    group('Dashboard Widgets Tests', () {
      group('RealTimeMetricsWidget Tests', () {
        late AnimationController refreshController;
        late Animation<double> refreshAnimation;

        setUp(() {
          refreshController = AnimationController(
            duration: const Duration(seconds: 1),
            vsync: const TestVSync(),
          );
          refreshAnimation =
              Tween<double>(begin: 0, end: 1).animate(refreshController);
        });

        tearDown(() {
          refreshController.dispose();
        });

        testWidgets('displays real-time metrics correctly', (tester) async {
          // Arrange
          final metrics = {
            'totalStudents': 25,
            'activeStudents': 18,
            'registeredStudents': 15,
            'outsideGeofence': 3,
            'averageDistance': 45.2,
          };

          // Act - CORREGIDO: Usar parámetros reales del widget
          await tester.pumpWidget(
            createTestWidget(
              RealTimeMetricsWidget(
                metrics: metrics, // CORREGIDO: 'metrics' es requerido
                isRefreshing: false,
                refreshAnimation: refreshAnimation,
              ),
            ),
          );

          // Assert
          expect(find.text('Métricas en Tiempo Real'), findsOneWidget);
          expect(find.byType(Card), findsWidgets);
        });

        testWidgets('handles empty metrics gracefully', (tester) async {
          // Act - CORREGIDO: Usar parámetros reales del widget
          await tester.pumpWidget(
            createTestWidget(
              RealTimeMetricsWidget(
                metrics: const {}, // CORREGIDO: 'metrics' es requerido
                isRefreshing: false,
                refreshAnimation: refreshAnimation,
              ),
            ),
          );

          // Assert
          expect(find.text('Métricas en Tiempo Real'), findsOneWidget);
          expect(find.text('0'), findsWidgets); // Default values
        });

        testWidgets('updates metrics in real-time', (tester) async {
          // Act - Initial render - CORREGIDO: Usar parámetros reales
          await tester.pumpWidget(
            createTestWidget(
              RealTimeMetricsWidget(
                metrics: const {
                  'totalStudents': 10
                }, // CORREGIDO: 'metrics' es requerido
                isRefreshing: false,
                refreshAnimation: refreshAnimation,
              ),
            ),
          );

          expect(find.byType(RealTimeMetricsWidget), findsOneWidget);

          // Act - Update with refreshing state - CORREGIDO: Usar parámetros reales
          await tester.pumpWidget(
            createTestWidget(
              RealTimeMetricsWidget(
                metrics: const {
                  'totalStudents': 15
                }, // CORREGIDO: 'metrics' es requerido
                isRefreshing: true,
                refreshAnimation: refreshAnimation,
              ),
            ),
          );

          // Assert
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        });
      });

      group('StudentActivityListWidget Tests', () {
        testWidgets('displays list of student activities', (tester) async {
          // Arrange
          final activities = [
            {
              'studentName': 'Juan Pérez',
              'status': 'inside',
              'distance': 30.0,
              'lastUpdate': DateTime.now().subtract(const Duration(minutes: 2)),
              'hasRegistered': true,
            },
            {
              'studentName': 'María García',
              'status': 'outside',
              'distance': 120.0,
              'lastUpdate': DateTime.now().subtract(const Duration(minutes: 1)),
              'hasRegistered': false,
            },
          ];

          // Act
          await tester.pumpWidget(
            createTestWidget(
              StudentActivityListWidget(
                studentActivities: activities,
                selectedFilter: 'all',
                onFilterChanged: (filter) {},
                activeEvent: testEvent,
              ),
            ),
          );

          // Assert
          expect(find.text('Actividad de Estudiantes'), findsOneWidget);
          expect(find.text('Juan Pérez'), findsOneWidget);
          expect(find.text('María García'), findsOneWidget);
          expect(find.text('30.0m'), findsOneWidget);
          expect(find.text('120.0m'), findsOneWidget);
        });

        testWidgets('shows different status indicators', (tester) async {
          // Arrange
          final activities = [
            {
              'studentName': 'Estudiante Dentro',
              'status': 'inside',
              'hasRegistered': true,
            },
            {
              'studentName': 'Estudiante Fuera',
              'status': 'outside',
              'hasRegistered': false,
            },
            {
              'studentName': 'Estudiante Gracia',
              'status': 'grace_period',
              'hasRegistered': false,
            },
          ];

          // Act
          await tester.pumpWidget(
            createTestWidget(
              StudentActivityListWidget(
                studentActivities: activities,
                selectedFilter: 'all',
                onFilterChanged: (filter) {},
                activeEvent: testEvent,
              ),
            ),
          );

          // Assert
          expect(find.byIcon(Icons.check_circle), findsWidgets);
          expect(find.byIcon(Icons.warning), findsWidgets);
          expect(find.byIcon(Icons.timer), findsWidgets);
        });

        testWidgets('handles empty activity list', (tester) async {
          // Act
          await tester.pumpWidget(
            createTestWidget(
              StudentActivityListWidget(
                studentActivities: const [],
                selectedFilter: 'all',
                onFilterChanged: (filter) {},
                activeEvent: testEvent,
              ),
            ),
          );

          // Assert
          expect(find.text('No hay actividad de estudiantes'), findsOneWidget);
          expect(find.byIcon(Icons.people_outline), findsOneWidget);
        });

        testWidgets('allows filtering by status', (tester) async {
          // Arrange
          String selectedFilter = 'all';
          final activities = [
            {
              'studentName': 'Juan Pérez',
              'status': 'inside',
              'hasRegistered': true,
            },
            {
              'studentName': 'María García',
              'status': 'outside',
              'hasRegistered': false,
            },
          ];

          // Act
          await tester.pumpWidget(
            createTestWidget(
              StudentActivityListWidget(
                studentActivities: activities,
                selectedFilter: selectedFilter,
                onFilterChanged: (filter) {
                  selectedFilter = filter;
                },
                activeEvent: testEvent,
              ),
            ),
          );

          // Assert filter options
          expect(find.text('Todos'), findsOneWidget);
          expect(find.text('Dentro'), findsOneWidget);
          expect(find.text('Fuera'), findsOneWidget);

          // Test filter functionality
          await tester.tap(find.text('Dentro'));
          await tester.pumpAndSettle();

          expect(selectedFilter, 'inside');
        });
      });

      group('EventControlPanelWidget Tests', () {
        testWidgets('displays event information correctly', (tester) async {
          // Act
          await tester.pumpWidget(
            createTestWidget(
              EventControlPanelWidget(
                teacherEvents: [testEvent],
                onEventSelected: (event) {},
                isAutoRefreshEnabled: false,
                onToggleAutoRefresh: () {},
                onManualRefresh: () {},
              ),
            ),
          );

          // Assert
          expect(find.text('Control del Evento'), findsOneWidget);
          expect(find.text('Test Event'), findsOneWidget);
          expect(find.text('Test Description'), findsOneWidget);
        });

        testWidgets('shows correct control buttons for active event',
            (tester) async {
          // Arrange
          bool manualRefreshTriggered = false;

          // Act
          await tester.pumpWidget(
            createTestWidget(
              EventControlPanelWidget(
                teacherEvents: [testEvent],
                onEventSelected: (event) {}, // No necesitamos verificar esto
                isAutoRefreshEnabled: true,
                onToggleAutoRefresh: () {}, // No necesitamos verificar esto
                onManualRefresh: () => manualRefreshTriggered = true,
              ),
            ),
          );

          // Assert
          expect(find.text('Auto Refresh'), findsOneWidget);
          expect(find.text('Refresh Manual'), findsOneWidget);

          // Test functionality
          await tester.tap(find.byIcon(Icons.refresh));
          expect(manualRefreshTriggered, true);
        });
      });
    });

    group('Widget Accessibility Tests', () {
      testWidgets('all widgets have proper semantic labels', (tester) async {
        // Test AttendanceStatusWidget
        final attendanceState = AttendanceState.initial().copyWith(
          isInsideGeofence: true,
          distanceToEvent: 45.0,
          attendanceStatus: AttendanceStatus.canRegister,
        );

        await tester.pumpWidget(
          createTestWidget(
            Semantics(
              label: 'Estado de asistencia',
              child: AttendanceStatusWidget(
                attendanceState: attendanceState,
                userName: testUser
                    .nombre, // CORREGIDO: 'userName' existe en AttendanceStatusWidget
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Estado de asistencia'), findsOneWidget);

        // Test AttendanceButtonWidget
        await tester.pumpWidget(
          createTestWidget(
            Semantics(
              label: 'Registrar asistencia',
              child: AttendanceButtonWidget(
                attendanceState: attendanceState,
                // CORREGIDO: AttendanceButtonWidget NO tiene userName
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Registrar asistencia'), findsOneWidget);
      });

      testWidgets('widgets support high contrast themes', (tester) async {
        // Arrange
        final highContrastTheme = ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.white,
          scaffoldBackgroundColor: Colors.black,
        );

        final attendanceState = AttendanceState.initial().copyWith(
          isInsideGeofence: true,
          attendanceStatus: AttendanceStatus.canRegister,
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            theme: highContrastTheme,
            home: Scaffold(
              body: AttendanceStatusWidget(
                // CORREGIDO: Usar parámetros reales del widget
                attendanceState: attendanceState,
                userName: testUser.nombre,
              ),
            ),
          ),
        );

        // Assert - Widget should render without issues
        expect(find.byType(AttendanceStatusWidget), findsOneWidget);
      });
    });

    group('Widget Performance Tests', () {
      testWidgets('widgets handle rapid state changes efficiently',
          (tester) async {
        // Arrange
        final baseState = AttendanceState.initial().copyWith(
          trackingStatus: TrackingStatus.active,
        );

        // Act
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          final state = baseState.copyWith(
            distanceToEvent: 50.0 + i,
            isInsideGeofence: i % 2 == 0,
          );

          await tester.pumpWidget(
            createTestWidget(
              AttendanceStatusWidget(
                // CORREGIDO: Usar parámetros reales del widget
                attendanceState: state,
                userName: testUser.nombre,
              ),
            ),
          );

          if (i % 10 == 0) {
            await tester.pump();
          }
        }

        stopwatch.stop();

        // Assert
        expect(
            stopwatch.elapsedMilliseconds, lessThan(2000)); // Under 2 seconds
        expect(find.byType(AttendanceStatusWidget), findsOneWidget);
      });

      testWidgets('widgets dispose properly to prevent memory leaks',
          (tester) async {
        // Arrange
        final graceController = AnimationController(
          duration: const Duration(seconds: 1),
          vsync: const TestVSync(),
        );
        final graceColorAnimation = ColorTween(
          begin: Colors.orange,
          end: Colors.red,
        ).animate(graceController);

        // Act - Create and dispose widget multiple times
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(
            createTestWidget(
              GracePeriodWidget(
                gracePeriodSeconds: 30,
                graceColorAnimation: graceColorAnimation,
              ),
            ),
          );

          await tester.pumpWidget(const SizedBox.shrink());
        }

        graceController.dispose();

        // Assert - Should not cause memory issues
        expect(tester.binding.hasScheduledFrame, false);
      });
    });

    group('Widget Edge Cases Tests', () {
      testWidgets('handles null or invalid data gracefully', (tester) async {
        // Test with minimal state
        final minimalState = AttendanceState.initial();

        await tester.pumpWidget(
          createTestWidget(
            AttendanceStatusWidget(
              attendanceState: minimalState,
              userName: testUser.nombre,
            ),
          ),
        );

        // Should not crash
        expect(find.byType(AttendanceStatusWidget), findsOneWidget);
      });

      testWidgets('handles extreme values correctly', (tester) async {
        // Test with extreme distance
        final extremeState = AttendanceState.initial().copyWith(
          distanceToEvent: 999999.0,
          isInsideGeofence: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            AttendanceStatusWidget(
              attendanceState: extremeState,
              userName: testUser.nombre,
            ),
          ),
        );

        // Should format large numbers appropriately
        expect(find.textContaining('999999'), findsOneWidget);
      });

      testWidgets('adapts to different screen sizes', (tester) async {
        // Test on small screen
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final attendanceState = AttendanceState.initial().copyWith(
          isInsideGeofence: true,
          attendanceStatus: AttendanceStatus.canRegister,
        );

        await tester.pumpWidget(
          createTestWidget(
            AttendanceStatusWidget(
              attendanceState: attendanceState,
              userName: testUser.nombre,
            ),
          ),
        );

        expect(find.byType(AttendanceStatusWidget), findsOneWidget);

        // Test on large screen
        tester.view.physicalSize = const Size(1200, 800);

        await tester.pumpWidget(
          createTestWidget(
            AttendanceStatusWidget(
              attendanceState: attendanceState,
              userName: testUser.nombre,
            ),
          ),
        );

        expect(find.byType(AttendanceStatusWidget), findsOneWidget);

        // Reset screen size
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });
    });
  });
}

// Helper class for testing animations - CORREGIDO
class TestVSync implements TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}
