# AttendanceManager Modular - FASE 2

## 🎯 Objetivo
Modularizar StudentAttendanceManager separando responsabilidades de tracking, estados y grace periods duales sin conflictos.

## 📏 Límites de Código
- **Límite crítico**: 2400 líneas por archivo
- **Límite recomendado**: 400 líneas por archivo
- **Estado actual**: Archivos entre 358-498 líneas ✅

## 📁 Estructura Modular

```
lib/services/attendance/
├── student_attendance_manager.dart    (coordinador, 498 líneas)
├── attendance_state_manager.dart      (estados backend, 358 líneas)
├── grace_period_manager.dart          (grace periods duales, 372 líneas)
└── README.md                          (esta documentación)
```

## 🔄 Flujo de Tracking

```
StudentAttendanceManager (coordinador principal)
    ↓
attendance_state_manager.dart (estados según backend)
    ↓
grace_period_manager.dart (períodos duales)
    ↓
Integración con asistencia/ (heartbeat + geofence)
```

## 🚨 Grace Periods Duales Sin Conflictos

### **CRÍTICO**: Dos timers independientes y sin conflictos
```dart
class GracePeriodManager {
  Timer? _geofenceGraceTimer;    // 60 segundos
  Timer? _appClosedGraceTimer;   // 30 segundos
  
  void startGeofenceGracePeriod() {
    // Solo para salidas de geocerca
    // 60 segundos de gracia
  }
  
  void startAppClosedGracePeriod() {
    // Solo para cierre de app
    // 30 segundos de gracia
  }
}
```

### **Casos de Uso**:
1. **Geofence Grace (60s)**: Estudiante sale del área permitida
2. **App Closed Grace (30s)**: App va a background/se cierra
3. **Sin conflictos**: Pueden ejecutarse simultáneamente

## 📊 Estados de Asistencia Backend

### **Implementación Exacta del Backend**:
```dart
enum EstadoAsistencia {
  inicial,      // Estado inicial
  presente,     // Dentro del radio permitido
  pendiente,    // Fuera del radio pero <10min del inicio
  ausente,      // Fuera del radio y >10min
  justificado,  // Con documento válido
  tarde,        // Llegó tarde pero dentro del tiempo
}
```

### **Transiciones Válidas**:
- `inicial` → `presente`, `pendiente`, `ausente`
- `pendiente` → `presente`, `ausente`, `tarde`
- `presente` → `ausente`, `tarde`
- `ausente` → `justificado`, `presente`
- `tarde` → `ausente`, `justificado`
- `justificado` → (estado final)

## 🔧 Archivos y Responsabilidades

### 1. **student_attendance_manager.dart** (Coordinador Principal)
- Coordinación central de todos los managers
- App lifecycle management
- Tracking principal de estudiante
- Integración con servicios de localización
- Manejo de estados globales

**Métodos principales:**
```dart
Future<bool> startTrackingForEvent(Evento evento)
Future<void> stopTracking()
void handleAppLifecycleChange(AppLifecycleState state)
StudentTrackingState getCurrentState()
```

### 2. **attendance_state_manager.dart** (Estados Backend)
- Estados de asistencia exactos del backend
- Transiciones válidas según flujo backend
- Cache de estados para optimización
- Historial de cambios de estado

**Funcionalidades clave:**
- Matriz de transiciones válidas
- Cálculo de estado según lógica backend
- Historial de cambios con timestamps
- Validación de transiciones

### 3. **grace_period_manager.dart** (Grace Periods Duales)
- Grace period geofence (60 segundos)
- Grace period app cerrada (30 segundos)
- Timers separados sin conflictos
- Notificaciones específicas para cada tipo

**Estados independientes:**
- Geofence grace: Solo para salidas de área
- App closed grace: Solo para app en background
- Pueden coexistir sin interferencias
- Cancelación individual de cada uno

## 🧪 Testing Manual

Validar que funcionen correctamente:

1. **Grace Periods Duales**:
   - ✅ Geofence grace (60s) funciona al salir del área
   - ✅ App closed grace (30s) funciona al cerrar app
   - ✅ Pueden ejecutarse simultáneamente sin conflictos
   - ✅ Cancelación individual funciona

2. **Estados Backend**:
   - ✅ Estados se calculan según lógica exacta del backend
   - ✅ Transiciones válidas funcionan correctamente
   - ✅ Historial de estados se mantiene

3. **Tracking Coordinado**:
   - ✅ Lifecycle de app maneja grace periods correctamente
   - ✅ Location tracking integra con geofence
   - ✅ Heartbeat continúa en background

## 🚨 Garantías Críticas

1. **Grace periods sin conflictos**: Dos timers independientes
2. **Estados backend exactos**: Siguiendo flujo documentado
3. **App lifecycle robusto**: Manejo correcto de foreground/background
4. **Tracking continuo**: No debe interrumpirse por cambios de estado
5. **Notificaciones específicas**: Cada grace period tiene sus propias notificaciones

## 📊 Coordinación con AsistenciaService

```
StudentAttendanceManager
    ↓
attendance_state_manager.dart → Calcula estados
    ↓
grace_period_manager.dart → Maneja grace periods
    ↓
AsistenciaService → Registra en backend
    ↓
HeartbeatManager → Heartbeat cada 30s
    ↓
GeofenceManager → Detecta entrada/salida
```

## 📈 Métricas de Éxito

- ✅ Grace periods duales funcionan sin conflictos
- ✅ Estados backend implementados correctamente
- ✅ App lifecycle maneja todos los casos
- ✅ Tracking robusto y continuo
- ✅ Integración correcta con AsistenciaService

---

**FASE 2 - AttendanceManager**: ✅ Implementado y funcional  
**Fecha de creación**: 2025-08-22  
**Responsable**: Claude Code Assistant