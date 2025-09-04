// lib/models/evento_model.dart
import 'package:flutter/material.dart';
import 'ubicacion_model.dart';

/// Estados inteligentes del evento
enum EventStatus {
  upcoming,      // Próximo (antes de la hora de inicio)
  startingSoon,  // Iniciando pronto (menos de 15 min para comenzar)
  active,        // Activo (en progreso)
  paused,        // Pausado (en horario pero no activo)
  expired,       // Expirado (ya pasó la hora de fin)
  finished,      // Finalizado (marcado como finalizado)
}

class Evento {
  final String? id;
  final String titulo;
  final String? tipo;
  final String? lugar;
  final String? descripcion;
  final Ubicacion ubicacion;
  final DateTime fecha; // Backend usa campo separado 'fecha'
  final DateTime horaInicio; // Backend usa 'horaInicio'
  final DateTime horaFinal; // Backend usa 'horaFinal'
  final double rangoPermitido; // 'radio' en el backend
  final String? creadoPor;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String estado; // ✅ AGREGADO campo estado
  final bool isActive; // ✅ AGREGADO campo isActive
  final double? latitud; // ✅ AGREGADO getter latitud
  final double? longitud; // ✅ AGREGADO getter longitud
  final int duracionMinutos; // ✅ AGREGADO duración en minutos

  Evento({
    this.id,
    required this.titulo,
    this.tipo,
    this.lugar,
    this.descripcion,
    required this.ubicacion,
    required this.fecha,
    required this.horaInicio,
    required this.horaFinal,
    this.rangoPermitido = 100.0,
    this.creadoPor,
    this.createdAt,
    this.updatedAt,
    this.estado = 'programado', // ✅ VALOR DEFAULT
    this.isActive = false, // ✅ VALOR DEFAULT
    int? duracionMinutos,
  }) : latitud = ubicacion.latitud, // ✅ GETTER CALCULADO
       longitud = ubicacion.longitud, // ✅ GETTER CALCULADO
       duracionMinutos = duracionMinutos ?? _calculateDuration(horaInicio, horaFinal); // ✅ CALCULAR DURACIÓN

  // ✅ MÉTODO PARA CALCULAR DURACIÓN
  static int _calculateDuration(DateTime inicio, DateTime fin) {
    return fin.difference(inicio).inMinutes;
  }

  factory Evento.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ DEBUG: Log del JSON recibido para investigar problema de horas
      debugPrint('🔍 DEBUG - JSON recibido del backend:');
      debugPrint('🔍   - Título: ${json['titulo'] ?? json['nombre']}');
      debugPrint('🔍   - Lugar: ${json['lugar']}');
      debugPrint('🔍   - fechaInicio: ${json['fechaInicio']} (tipo: ${json['fechaInicio'].runtimeType})');
      debugPrint('🔍   - fechaFin: ${json['fechaFin']} (tipo: ${json['fechaFin'].runtimeType})');
      debugPrint('🔍   - horaInicio: ${json['horaInicio']}');
      debugPrint('🔍   - horaFin/horaFinal: ${json['horaFin'] ?? json['horaFinal']}');
      debugPrint('🔍   - coordenadas: ${json['coordenadas']}');
      debugPrint('🔍   - latitud: ${json['latitud']}');
      debugPrint('🔍   - longitud: ${json['longitud']}');
      debugPrint('🔍   - radio: ${json['radio']}');
      // ✅ MANEJAR AMBOS NOMBRES: titulo (frontend) y nombre (backend)
      final String titulo =
          json['titulo']?.toString() ??
          json['nombre']?.toString() ??
          'Evento sin título';

      // ✅ NUEVOS CAMPOS DEL BACKEND
      final String? tipo = json['tipo']?.toString();
      final String? lugar = json['lugar']?.toString();
      final String? descripcion = json['descripcion']?.toString();
      final String? creadoPor =
          json['creadoPor']?.toString() ??
          json['profesor']?.toString() ??
          json['creadorId']?.toString();

      // ✅ ESTADO E ISACTIVE DEL BACKEND
      final String estado = json['estado']?.toString() ?? 'programado';
      final bool isActive =
          json['isActive'] == true ||
          json['activo'] == true ||
          estado == 'activo';

      // ✅ COORDENADAS DEL BACKEND
      Map<String, dynamic>? coordenadas;
      double lat = 0.0, lng = 0.0, radio = 100.0;

      if (json['coordenadas'] != null) {
        coordenadas = json['coordenadas'] as Map<String, dynamic>;
        lat = (coordenadas['latitud'] as num?)?.toDouble() ?? 0.0;
        lng = (coordenadas['longitud'] as num?)?.toDouble() ?? 0.0;
        radio = (coordenadas['radio'] as num?)?.toDouble() ?? 100.0;
      } else {
        // ✅ FALLBACK SI VIENEN DIRECTAMENTE EN EL JSON
        lat = (json['latitud'] as num?)?.toDouble() ?? 0.0;
        lng = (json['longitud'] as num?)?.toDouble() ?? 0.0;
        radio =
            (json['radio'] as num?)?.toDouble() ??
            (json['rangoPermitido'] as num?)?.toDouble() ??
            100.0;
      }

      // ✅ FECHAS Y HORAS DEL BACKEND - SOPORTE PARA ISO DATETIMES
      DateTime fecha = DateTime.now();
      DateTime horaInicio = DateTime.now();
      DateTime horaFinal = DateTime.now().add(const Duration(hours: 2));

      // ✅ PRIORIZAR fechaInicio y fechaFin como ISO strings (nuevo formato)
      if (json['fechaInicio'] != null) {
        try {
          final fechaInicioStr = json['fechaInicio'].toString();
          if (fechaInicioStr.contains('T') || fechaInicioStr.contains('Z')) {
            // Es un ISO datetime string completo
            horaInicio = DateTime.parse(fechaInicioStr);
            fecha = DateTime(horaInicio.year, horaInicio.month, horaInicio.day);
            debugPrint('   ✅ fechaInicio parseado: $horaInicio');
          } else {
            // Es solo fecha (formato anterior)
            fecha = DateTime.parse(fechaInicioStr);
          }
        } catch (e) {
          debugPrint('   ❌ Error parseando fechaInicio: $e');
        }
      }

      if (json['fechaFin'] != null) {
        try {
          final fechaFinStr = json['fechaFin'].toString();
          if (fechaFinStr.contains('T') || fechaFinStr.contains('Z')) {
            // Es un ISO datetime string completo
            horaFinal = DateTime.parse(fechaFinStr);
            debugPrint('   ✅ fechaFin parseado: $horaFinal');
          }
        } catch (e) {
          debugPrint('   ❌ Error parseando fechaFin: $e');
        }
      }

      // ✅ FALLBACK: si no hay fechaInicio/fechaFin ISO, usar formato anterior
      if (json['fecha'] != null && (json['fechaInicio'] == null || !json['fechaInicio'].toString().contains('T'))) {
        try {
          fecha = DateTime.parse(json['fecha'].toString());
        } catch (e) {
          debugPrint('   ❌ Error parseando fecha: $e');
        }
      }

      // ✅ FALLBACK: parsing de horaInicio/horaFin separadas (formato anterior)
      if (json['horaInicio'] != null && (json['fechaInicio'] == null || !json['fechaInicio'].toString().contains('T'))) {
        try {
          final timeStr = json['horaInicio'].toString();
          final parts = timeStr.split(':');
          if (parts.length >= 2) {
            horaInicio = DateTime(
              fecha.year,
              fecha.month,
              fecha.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
          }
        } catch (e) {
          debugPrint('   ❌ Error parseando horaInicio: $e');
        }
      }

      if ((json['horaFin'] != null || json['horaFinal'] != null) && 
          (json['fechaFin'] == null || !json['fechaFin'].toString().contains('T'))) {
        try {
          final timeStr = (json['horaFin'] ?? json['horaFinal']).toString();
          final parts = timeStr.split(':');
          if (parts.length >= 2) {
            horaFinal = DateTime(
              fecha.year,
              fecha.month,
              fecha.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
          }
        } catch (e) {
          debugPrint('   ❌ Error parseando horaFin/horaFinal: $e');
        }
      }
      
      // ✅ DEBUG: Log valores finales parseados
      debugPrint('🔍 DEBUG - Valores finales parseados:');
      debugPrint('🔍   - horaInicio final: $horaInicio');
      debugPrint('🔍   - horaFinal final: $horaFinal');
      debugPrint('🔍   - fecha final: $fecha');
      debugPrint('🔍   - lat: $lat, lng: $lng, radio: $radio');

      return Evento(
        id: json['id']?.toString() ?? json['_id']?.toString(),
        titulo: titulo,
        tipo: tipo,
        lugar: lugar,
        descripcion: descripcion,
        ubicacion: Ubicacion(latitud: lat, longitud: lng),
        fecha: fecha,
        horaInicio: horaInicio,
        horaFinal: horaFinal,
        rangoPermitido: radio,
        creadoPor: creadoPor,
        createdAt: json['creadoEn'] != null
            ? DateTime.parse(json['creadoEn'].toString())
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'].toString())
            : null,
        estado: estado,
        isActive: isActive,
        duracionMinutos: json['duracionMinutos'] as int?,
      );
    } catch (e) {
      debugPrint('❌ Error parsing Evento from JSON: $e');
      debugPrint('❌ JSON data: $json');
      throw Exception('Error parsing Evento: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'nombre': titulo, // ✅ ENVIAR AMBOS NOMBRES
      'tipo': tipo,
      'lugar': lugar,
      'descripcion': descripcion,
      'coordenadas': {
        'latitud': ubicacion.latitud,
        'longitud': ubicacion.longitud,
        'radio': rangoPermitido,
      },
      'fecha': fecha.toIso8601String().split('T')[0],
      'fechaInicio': fecha.toIso8601String().split('T')[0],
      'horaInicio':
          '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}',
      'horaFin':
          '${horaFinal.hour.toString().padLeft(2, '0')}:${horaFinal.minute.toString().padLeft(2, '0')}',
      'horaFinal':
          '${horaFinal.hour.toString().padLeft(2, '0')}:${horaFinal.minute.toString().padLeft(2, '0')}',
      'creadoPor': creadoPor,
      'profesor': creadoPor,
      'estado': estado,
      'isActive': isActive,
      'activo': isActive,
      'duracionMinutos': duracionMinutos,
    };
  }

  /// ✅ FACTORY METHOD PARA CREAR NUEVO EVENTO
  factory Evento.crear({
    required String titulo,
    required String tipo,
    required String lugar,
    required String descripcion,
    required double latitud,
    required double longitud,
    required double radio,
    required DateTime fecha,
    required DateTime horaInicio,
    required DateTime horaFin,
    required String creadoPor,
  }) {
    return Evento(
      titulo: titulo,
      tipo: tipo,
      lugar: lugar,
      descripcion: descripcion,
      ubicacion: Ubicacion(latitud: latitud, longitud: longitud),
      fecha: fecha,
      horaInicio: horaInicio,
      horaFinal: horaFin,
      rangoPermitido: radio,
      creadoPor: creadoPor,
      estado: 'programado',
      isActive: false,
    );
  }

  // ✅ MÉTODO PARA ACTUALIZAR isActive
  Evento copyWith({
    String? id,
    String? titulo,
    String? tipo,
    String? lugar,
    String? descripcion,
    Ubicacion? ubicacion,
    DateTime? fecha,
    DateTime? horaInicio,
    DateTime? horaFinal,
    double? rangoPermitido,
    String? creadoPor,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? estado,
    bool? isActive,
    int? duracionMinutos,
  }) {
    return Evento(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      tipo: tipo ?? this.tipo,
      lugar: lugar ?? this.lugar,
      descripcion: descripcion ?? this.descripcion,
      ubicacion: ubicacion ?? this.ubicacion,
      fecha: fecha ?? this.fecha,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFinal: horaFinal ?? this.horaFinal,
      rangoPermitido: rangoPermitido ?? this.rangoPermitido,
      creadoPor: creadoPor ?? this.creadoPor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estado: estado ?? this.estado,
      isActive: isActive ?? this.isActive,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
    );
  }

  // ✅ GETTERS PARA FECHAS FORMATEADAS
  String get fechaInicioFormatted {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String get horaInicioFormatted {
    return '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}';
  }

  String get horaFinalFormatted {
    return '${horaFinal.hour.toString().padLeft(2, '0')}:${horaFinal.minute.toString().padLeft(2, '0')}';
  }

  // ✅ GETTER PARA COMPATIBILIDAD
  DateTime get fechaInicio => fecha;

  // ✅ NUEVOS GETTERS INTELIGENTES PARA ESTADO DEL EVENTO
  /// Obtiene el estado inteligente del evento basado en fecha/hora actual
  EventStatus get currentStatus {
    final now = DateTime.now();
    final eventStart = DateTime(fecha.year, fecha.month, fecha.day, 
                               horaInicio.hour, horaInicio.minute);
    final eventEnd = DateTime(fecha.year, fecha.month, fecha.day, 
                             horaFinal.hour, horaFinal.minute);

    // Si el estado ya está marcado como finalizado o cancelado
    if (estado.toLowerCase() == 'finalizado' || estado.toLowerCase() == 'cancelado') {
      return EventStatus.finished;
    }

    // Lógica basada en tiempo
    if (now.isBefore(eventStart)) {
      // El evento aún no ha comenzado
      final diffInMinutes = eventStart.difference(now).inMinutes;
      if (diffInMinutes <= 15) {
        return EventStatus.startingSoon; // Próximo a comenzar (menos de 15 min)
      }
      return EventStatus.upcoming; // Próximo
    } else if (now.isAfter(eventEnd)) {
      // El evento ya terminó
      return EventStatus.expired;
    } else {
      // El evento está en progreso
      return isActive ? EventStatus.active : EventStatus.paused;
    }
  }

  /// Obtiene el texto del estado para mostrar al usuario
  String get statusText {
    switch (currentStatus) {
      case EventStatus.upcoming:
        return 'PRÓXIMO';
      case EventStatus.startingSoon:
        return 'INICIANDO PRONTO';
      case EventStatus.active:
        return 'ACTIVO';
      case EventStatus.paused:
        return 'PAUSADO';
      case EventStatus.expired:
        return 'EXPIRADO';
      case EventStatus.finished:
        return 'FINALIZADO';
    }
  }

  /// Obtiene el color del estado
  Color get statusColor {
    switch (currentStatus) {
      case EventStatus.upcoming:
        return Colors.blue;
      case EventStatus.startingSoon:
        return Colors.orange;
      case EventStatus.active:
        return Colors.green;
      case EventStatus.paused:
        return Colors.yellow;
      case EventStatus.expired:
        return Colors.red;
      case EventStatus.finished:
        return Colors.grey;
    }
  }

  /// Determina si el estudiante puede unirse al evento
  bool get canJoin {
    final status = currentStatus;
    return status == EventStatus.upcoming || 
           status == EventStatus.startingSoon || 
           status == EventStatus.active;
  }

  @override
  String toString() {
    return 'Evento(id: $id, titulo: $titulo, tipo: $tipo, estado: $estado, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Evento && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
