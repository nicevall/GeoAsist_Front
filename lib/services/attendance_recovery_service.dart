// lib/services/attendance_recovery_service.dart
import 'dart:async';
import '../models/evento_model.dart';
import '../models/justificacion_model.dart';
import '../models/api_response_model.dart';
import '../widgets/attendance/attendance_recovery_widget.dart';
import 'asistencia_service.dart';
import 'evento_service.dart';
import 'justificacion_service.dart';
import 'package:flutter/material.dart';

/// ✅ ATTENDANCE RECOVERY SERVICE: Enhanced service for attendance recovery management
/// 
/// Features:
/// - Automatic detection of missed attendances
/// - Smart analysis of recovery opportunities
/// - Integration with justification system
/// - Recovery deadline management
/// - Notification system for urgent recoveries
/// - Statistics and reporting
class AttendanceRecoveryService {
  static final AttendanceRecoveryService _instance = AttendanceRecoveryService._internal();
  factory AttendanceRecoveryService() => _instance;
  AttendanceRecoveryService._internal();

  // Services
  final AsistenciaService _asistenciaService = AsistenciaService();
  final EventoService _eventoService = EventoService();
  final JustificacionService _justificacionService = JustificacionService();

  // Cache and state
  List<MissedAttendance> _cachedMissedAttendances = [];
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Recovery settings
  static const Duration _defaultRecoveryWindow = Duration(hours: 48);
  static const Duration _urgentThreshold = Duration(hours: 6);
  static const Duration _criticalThreshold = Duration(hours: 2);

  /// 🔍 DETECT MISSED ATTENDANCES FOR A USER
  Future<ApiResponse<List<MissedAttendance>>> detectMissedAttendances(String userId) async {
    try {
      debugPrint('🔍 Detecting missed attendances for user: $userId');

      // Check cache first
      if (_isCacheValid()) {
        debugPrint('✅ Using cached missed attendances');
        return ApiResponse.success(_cachedMissedAttendances);
      }

      // Get user's attendance history
      final attendances = await _asistenciaService.obtenerHistorialUsuario(userId);
      
      // Get all events the user should have attended
      final allEvents = await _eventoService.obtenerEventos();
      
      // Filter events that occurred in the past and user was supposed to attend
      final pastEvents = allEvents.where((event) {
        final eventEnd = DateTime(
          event.fecha.year,
          event.fecha.month,
          event.fecha.day,
          event.horaFinal.hour,
          event.horaFinal.minute,
        );
        return eventEnd.isBefore(DateTime.now());
      }).toList();

      // Find missed attendances
      List<MissedAttendance> missedList = [];
      
      for (final event in pastEvents) {
        final hasAttendance = attendances.any((a) => a.eventoId == event.id);
        
        if (!hasAttendance) {
          // Check if recovery is still possible
          final recoveryDeadline = _calculateRecoveryDeadline(event);
          
          if (DateTime.now().isBefore(recoveryDeadline)) {
            // Check if there's already a justification
            final justificationsResponse = await _justificacionService.obtenerMisJustificaciones();
            Justificacion? existingJustification;
            
            if (justificationsResponse.success) {
              existingJustification = justificationsResponse.data!
                  .where((j) => j.eventoId == event.id)
                  .firstOrNull;
            }

            final missedAttendance = MissedAttendance(
              event: event,
              missedTime: _calculateMissedTime(event),
              recoveryDeadline: recoveryDeadline,
              existingJustification: existingJustification,
              urgencyLevel: _calculateUrgencyLevel(event),
            );

            missedList.add(missedAttendance);
          }
        }
      }

      // Sort by urgency (most urgent first)
      missedList.sort((a, b) => b.urgencyLevel.index.compareTo(a.urgencyLevel.index));

      // Update cache
      _cachedMissedAttendances = missedList;
      _lastCacheUpdate = DateTime.now();

      debugPrint('✅ Detected ${missedList.length} missed attendances');
      return ApiResponse.success(missedList);

    } catch (e) {
      debugPrint('❌ Error detecting missed attendances: $e');
      return ApiResponse.error('Error detectando asistencias perdidas: $e');
    }
  }

  /// 📊 GET RECOVERY STATISTICS FOR A USER
  Future<ApiResponse<RecoveryStats>> getRecoveryStats(String userId) async {
    try {
      debugPrint('📊 Getting recovery stats for user: $userId');

      final missedResponse = await detectMissedAttendances(userId);
      if (!missedResponse.success) {
        return ApiResponse.error(missedResponse.error!);
      }

      final missed = missedResponse.data!;
      final justificationsResponse = await _justificacionService.obtenerMisJustificaciones();
      
      List<Justificacion> justifications = [];
      if (justificationsResponse.success) {
        justifications = justificationsResponse.data!;
      }

      final stats = RecoveryStats(
        totalMissed: missed.length,
        criticalUrgency: missed.where((m) => m.urgencyLevel == AttendanceUrgencyLevel.critical).length,
        highUrgency: missed.where((m) => m.urgencyLevel == AttendanceUrgencyLevel.high).length,
        withJustifications: missed.where((m) => m.existingJustification != null).length,
        pendingJustifications: justifications.where((j) => j.estado == JustificacionEstado.pendiente).length,
        approvedJustifications: justifications.where((j) => j.estado == JustificacionEstado.aprobada).length,
        rejectedJustifications: justifications.where((j) => j.estado == JustificacionEstado.rechazada).length,
        averageResponseTime: _calculateAverageResponseTime(justifications),
        recoverySuccessRate: _calculateRecoverySuccessRate(missed, justifications),
      );

      debugPrint('✅ Recovery stats calculated');
      return ApiResponse.success(stats);

    } catch (e) {
      debugPrint('❌ Error getting recovery stats: $e');
      return ApiResponse.error('Error obteniendo estadísticas: $e');
    }
  }

  /// 🚀 START RECOVERY PROCESS
  Future<ApiResponse<bool>> startRecoveryProcess({
    required String userId,
    required String eventId,
    required RecoveryType recoveryType,
    Map<String, dynamic>? recoveryData,
  }) async {
    try {
      debugPrint('🚀 Starting recovery process: $recoveryType for event $eventId');

      switch (recoveryType) {
        case RecoveryType.justification:
          return await _processJustification(userId, eventId, recoveryData);
        
        case RecoveryType.lateAttendance:
          return await _processLateAttendance(userId, eventId, recoveryData);
        
        case RecoveryType.emergency:
          return await _processEmergencyRecovery(userId, eventId, recoveryData);
        
        case RecoveryType.technicalIssue:
          return await _processTechnicalIssue(userId, eventId, recoveryData);
      }

    } catch (e) {
      debugPrint('❌ Error starting recovery process: $e');
      return ApiResponse.error('Error iniciando recuperación: $e');
    }
  }

  /// 📋 PROCESS JUSTIFICATION RECOVERY
  Future<ApiResponse<bool>> _processJustification(
    String userId,
    String eventId,
    Map<String, dynamic>? data,
  ) async {
    try {
      if (data == null) {
        return ApiResponse.error('Datos de justificación requeridos');
      }

      final justification = Justificacion.create(
        usuarioId: userId,
        eventoId: eventId,
        motivo: data['motivo'] ?? '',
        linkDocumento: data['linkDocumento'] ?? '',
        tipo: JustificacionTipo.fromString(data['tipo']),
        documentoNombre: data['documentoNombre'],
        metadatos: data['metadatos'],
      );

      final response = await _justificacionService.crearJustificacion(
        eventoId: justification.eventoId,
        motivo: justification.motivo,
        linkDocumento: justification.linkDocumento,
        tipo: justification.tipo,
      );
      
      if (response.success) {
        _invalidateCache(); // Clear cache to force refresh
        debugPrint('✅ Justification created successfully');
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error(response.error ?? 'Error creando justificación');
      }

    } catch (e) {
      debugPrint('❌ Error processing justification: $e');
      return ApiResponse.error('Error procesando justificación: $e');
    }
  }

  /// ⏰ PROCESS LATE ATTENDANCE RECOVERY
  Future<ApiResponse<bool>> _processLateAttendance(
    String userId,
    String eventId,
    Map<String, dynamic>? data,
  ) async {
    try {
      // For late attendance, we can create a special attendance record
      // or a justification marked as "tardanza"
      
      final lateJustification = Justificacion.create(
        usuarioId: userId,
        eventoId: eventId,
        motivo: data?['motivo'] ?? 'Llegada tardía al evento',
        linkDocumento: data?['linkDocumento'] ?? 'N/A',
        tipo: JustificacionTipo.otra,
        documentoNombre: data?['documentoNombre'],
        metadatos: {
          'tipo': 'tardanza',
          'tiempoLlegada': data?['tiempoLlegada'],
          'razonTardanza': data?['razonTardanza'],
        },
      );

      final response = await _justificacionService.crearJustificacion(
        eventoId: lateJustification.eventoId,
        motivo: lateJustification.motivo,
        linkDocumento: lateJustification.linkDocumento,
        tipo: lateJustification.tipo,
      );
      
      if (response.success) {
        _invalidateCache();
        debugPrint('✅ Late attendance processed successfully');
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error(response.error ?? 'Error procesando tardanza');
      }

    } catch (e) {
      debugPrint('❌ Error processing late attendance: $e');
      return ApiResponse.error('Error procesando tardanza: $e');
    }
  }

  /// 🚨 PROCESS EMERGENCY RECOVERY
  Future<ApiResponse<bool>> _processEmergencyRecovery(
    String userId,
    String eventId,
    Map<String, dynamic>? data,
  ) async {
    try {
      final emergencyJustification = Justificacion.create(
        usuarioId: userId,
        eventoId: eventId,
        motivo: data?['motivo'] ?? 'Situación de emergencia',
        linkDocumento: data?['linkDocumento'] ?? '',
        tipo: JustificacionTipo.emergencia,
        documentoNombre: data?['documentoNombre'],
        metadatos: {
          'tipo': 'emergencia',
          'tipoEmergencia': data?['tipoEmergencia'],
          'contactoEmergencia': data?['contactoEmergencia'],
          'fechaEmergencia': DateTime.now().toIso8601String(),
        },
      );

      final response = await _justificacionService.crearJustificacion(
        eventoId: emergencyJustification.eventoId,
        motivo: emergencyJustification.motivo,
        linkDocumento: emergencyJustification.linkDocumento,
        tipo: emergencyJustification.tipo,
      );
      
      if (response.success) {
        _invalidateCache();
        debugPrint('✅ Emergency recovery processed successfully');
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error(response.error ?? 'Error procesando emergencia');
      }

    } catch (e) {
      debugPrint('❌ Error processing emergency recovery: $e');
      return ApiResponse.error('Error procesando emergencia: $e');
    }
  }

  /// 🔧 PROCESS TECHNICAL ISSUE RECOVERY
  Future<ApiResponse<bool>> _processTechnicalIssue(
    String userId,
    String eventId,
    Map<String, dynamic>? data,
  ) async {
    try {
      final technicalJustification = Justificacion.create(
        usuarioId: userId,
        eventoId: eventId,
        motivo: data?['motivo'] ?? 'Problema técnico con la aplicación',
        linkDocumento: data?['linkDocumento'] ?? 'N/A',
        tipo: JustificacionTipo.otra,
        documentoNombre: data?['documentoNombre'],
        metadatos: {
          'tipo': 'problema_tecnico',
          'tipoProblema': data?['tipoProblema'],
          'descripcionTecnica': data?['descripcionTecnica'],
          'dispositivoInfo': data?['dispositivoInfo'],
          'horaIntento': data?['horaIntento'],
        },
      );

      final response = await _justificacionService.crearJustificacion(
        eventoId: technicalJustification.eventoId,
        motivo: technicalJustification.motivo,
        linkDocumento: technicalJustification.linkDocumento,
        tipo: technicalJustification.tipo,
      );
      
      if (response.success) {
        _invalidateCache();
        debugPrint('✅ Technical issue processed successfully');
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error(response.error ?? 'Error procesando problema técnico');
      }

    } catch (e) {
      debugPrint('❌ Error processing technical issue: $e');
      return ApiResponse.error('Error procesando problema técnico: $e');
    }
  }

  /// 🔍 CHECK IF RECOVERY IS AVAILABLE FOR EVENT
  Future<bool> isRecoveryAvailable(String eventId) async {
    try {
      final eventos = await _eventoService.obtenerEventos();
      final event = eventos.firstWhere((e) => e.id == eventId, orElse: () => throw Exception('Event not found'));
      
      final recoveryDeadline = _calculateRecoveryDeadline(event);
      return DateTime.now().isBefore(recoveryDeadline);
      
    } catch (e) {
      debugPrint('❌ Error checking recovery availability: $e');
      return false;
    }
  }

  /// 📅 CALCULATE RECOVERY DEADLINE
  DateTime _calculateRecoveryDeadline(Evento event) {
    final eventEnd = DateTime(
      event.fecha.year,
      event.fecha.month,
      event.fecha.day,
      event.horaFinal.hour,
      event.horaFinal.minute,
    );
    return eventEnd.add(_defaultRecoveryWindow);
  }

  /// ⏰ CALCULATE MISSED TIME
  DateTime _calculateMissedTime(Evento event) {
    final eventStart = DateTime(
      event.fecha.year,
      event.fecha.month,
      event.fecha.day,
      event.horaInicio.hour,
      event.horaInicio.minute,
    );
    return eventStart.add(const Duration(minutes: 15)); // Tolerance period
  }

  /// 🚨 CALCULATE URGENCY LEVEL
  AttendanceUrgencyLevel _calculateUrgencyLevel(Evento event) {
    final deadline = _calculateRecoveryDeadline(event);
    final timeUntilDeadline = deadline.difference(DateTime.now());

    if (timeUntilDeadline <= _criticalThreshold) {
      return AttendanceUrgencyLevel.critical;
    } else if (timeUntilDeadline <= _urgentThreshold) {
      return AttendanceUrgencyLevel.high;
    } else if (timeUntilDeadline <= const Duration(hours: 24)) {
      return AttendanceUrgencyLevel.medium;
    } else {
      return AttendanceUrgencyLevel.low;
    }
  }

  /// 📊 CALCULATE AVERAGE RESPONSE TIME
  Duration _calculateAverageResponseTime(List<Justificacion> justifications) {
    final reviewed = justifications.where((j) => j.fechaRevision != null).toList();
    
    if (reviewed.isEmpty) return Duration.zero;

    final totalSeconds = reviewed.map((j) {
      return j.fechaRevision!.difference(j.fechaCreacion).inSeconds;
    }).reduce((a, b) => a + b);

    return Duration(seconds: (totalSeconds / reviewed.length).round());
  }

  /// 📈 CALCULATE RECOVERY SUCCESS RATE
  double _calculateRecoverySuccessRate(List<MissedAttendance> missed, List<Justificacion> justifications) {
    final totalMissed = missed.length;
    if (totalMissed == 0) return 100.0;

    final successful = justifications.where((j) => j.estado == JustificacionEstado.aprobada).length;
    return (successful / totalMissed) * 100;
  }

  /// 🗄️ CACHE MANAGEMENT
  bool _isCacheValid() {
    return _lastCacheUpdate != null &&
           DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  void _invalidateCache() {
    _cachedMissedAttendances.clear();
    _lastCacheUpdate = null;
  }

  /// 🧹 CLEAR ALL CACHE
  void clearCache() {
    _invalidateCache();
    debugPrint('✅ Recovery service cache cleared');
  }
}

/// 📊 RECOVERY STATISTICS MODEL
class RecoveryStats {
  final int totalMissed;
  final int criticalUrgency;
  final int highUrgency;
  final int withJustifications;
  final int pendingJustifications;
  final int approvedJustifications;
  final int rejectedJustifications;
  final Duration averageResponseTime;
  final double recoverySuccessRate;

  const RecoveryStats({
    required this.totalMissed,
    required this.criticalUrgency,
    required this.highUrgency,
    required this.withJustifications,
    required this.pendingJustifications,
    required this.approvedJustifications,
    required this.rejectedJustifications,
    required this.averageResponseTime,
    required this.recoverySuccessRate,
  });

  /// Get recovery health status
  RecoveryHealthStatus get healthStatus {
    if (criticalUrgency > 0) {
      return RecoveryHealthStatus.critical;
    } else if (highUrgency > 2) {
      return RecoveryHealthStatus.warning;
    } else if (totalMissed > 0) {
      return RecoveryHealthStatus.attention;
    } else {
      return RecoveryHealthStatus.excellent;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMissed': totalMissed,
      'criticalUrgency': criticalUrgency,
      'highUrgency': highUrgency,
      'withJustifications': withJustifications,
      'pendingJustifications': pendingJustifications,
      'approvedJustifications': approvedJustifications,
      'rejectedJustifications': rejectedJustifications,
      'averageResponseHours': averageResponseTime.inHours,
      'recoverySuccessRate': recoverySuccessRate,
    };
  }
}

/// 🎯 RECOVERY TYPES
enum RecoveryType {
  justification,
  lateAttendance,
  emergency,
  technicalIssue,
}

/// 💚 RECOVERY HEALTH STATUS
enum RecoveryHealthStatus {
  excellent('Excelente', Color(0xFF4CAF50)),
  attention('Atención', Color(0xFF2196F3)),
  warning('Advertencia', Color(0xFFFF9800)),
  critical('Crítico', Color(0xFFF44336));

  const RecoveryHealthStatus(this.label, this.color);

  final String label;
  final Color color;
}