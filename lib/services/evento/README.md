# EventoService Modular - Estructura

## 🎯 Objetivo
Solucionar el problema de **soft delete** donde eventos eliminados seguían apareciendo en el frontend, y hacer el código modular respetando límites de líneas.

## 📏 Límites de Código
- **Límite crítico**: 2400 líneas por archivo (límite Claude Code)
- **Límite recomendado**: 400 líneas por archivo
- **Acción automática**: Si archivo > 2000 líneas → modularizar inmediatamente

## 📁 Estructura Modular

```
lib/services/evento/
├── evento_service.dart         (coordinador principal, <400 líneas)
├── evento_repository.dart      (llamadas API, <400 líneas)
├── evento_mapper.dart          (mapeo + filtro soft delete, <400 líneas)
├── evento_validator.dart       (validaciones business, <400 líneas)
└── README.md                   (esta documentación)
```

## 🔄 Flujo de Datos

```
Frontend → evento_service.dart (coordinador)
    ↓
evento_validator.dart (validaciones)
    ↓
evento_repository.dart (API calls)
    ↓
evento_mapper.dart (mapeo + filtro soft delete)
    ↓
Frontend (datos limpios)
```

## 🚨 Problema Solucionado: Soft Delete

### **Antes** (❌ PROBLEMA):
- Backend retorna eventos con `estado: "eliminado"`
- Frontend mostraba TODOS los eventos incluyendo eliminados
- "EXPO PROYECTOS" eliminado seguía apareciendo

### **Después** (✅ SOLUCIÓN):
- `evento_mapper.dart` filtra automáticamente eventos eliminados
- Solo muestra eventos con estado: `"activo"`, `"inactivo"`, `"en espera"`
- **NUNCA** muestra eventos con estado: `"eliminado"`

## 📋 Estados de Eventos

| Estado | Mostrar | Descripción |
|--------|---------|-------------|
| `"activo"` | ✅ | Evento activo y disponible |
| `"en espera"` | ✅ | Evento programado |
| `"inactivo"` | ✅ | Evento pausado (puede reactivarse) |
| `"finalizado"` | ✅ | Evento terminado |
| `"eliminado"` | ❌ | **FILTRAR - NO MOSTRAR** |

## 🔧 Archivos y Responsabilidades

### 1. **evento_service.dart** (Coordinador)
- Punto de entrada único para el frontend
- Coordina entre validator, repository y mapper
- Mantiene estados de loading
- Expone API pública consistente

**Métodos públicos:**
```dart
Future<List<Evento>> obtenerEventos()
Future<Evento?> obtenerEventoPorId(String id)
Future<List<Evento>> getEventosByCreador(String creadorId)
Future<bool> crearEvento(Evento evento)
Future<bool> editarEvento(Evento evento)
Future<bool> eliminarEvento(String id) // Soft delete
Future<bool> toggleEventoActive(String id, bool isActive)
```

### 2. **evento_repository.dart** (API Layer)
- Todas las llamadas HTTP al backend
- Manejo de errores de red y timeouts
- Retry logic para llamadas fallidas
- Parsing inicial de responses

**Responsabilidades:**
- GET /eventos
- GET /eventos/:id
- POST /eventos
- PUT /eventos/:id
- DELETE /eventos/:id (soft delete)

### 3. **evento_mapper.dart** (Transformaciones + Filtros)
- **CRÍTICO**: Filtrar eventos eliminados
- Mapeo backend → frontend
- Mapeo frontend → backend
- Validaciones de datos de mapeo

**Función crítica:**
```dart
List<Evento> filterActiveEvents(List<dynamic> backendEvents) {
  return backendEvents
    .where((event) => event['estado'] != 'eliminado')
    .map((event) => mapBackendToFlutter(event))
    .toList();
}
```

### 4. **evento_validator.dart** (Validaciones)
- Validaciones de entrada de datos
- Business rules y permisos
- Validaciones antes de operaciones CRUD

**Validaciones implementadas:**
- Evento no eliminado antes de operaciones
- Permisos del usuario para CRUD
- Coordenadas válidas
- Fechas coherentes
- Capacidad máxima válida

## 🧪 Testing Manual

Después de la refactorización, validar:

1. **Dashboard Estudiante**:
   - ✅ Solo muestra eventos activos/en espera
   - ❌ NO muestra eventos eliminados
   - ✅ "EXPO PROYECTOS" eliminado NO aparece

2. **Dashboard Profesor**:
   - ✅ Solo muestra sus eventos no eliminados
   - ✅ Puede crear nuevos eventos
   - ✅ Puede eliminar (soft delete) eventos

3. **Operaciones CRUD**:
   - ✅ Crear evento funciona
   - ✅ Editar evento funciona
   - ✅ Eliminar evento (soft delete) funciona
   - ✅ Toggle activo/inactivo funciona

## 🔒 Garantías de Seguridad

1. **Funcionalidad preservada**: Todos los métodos públicos funcionan igual
2. **Estados de loading**: Mantenidos en el coordinador
3. **Validaciones**: Preservadas y mejoradas
4. **Filtrado automático**: Eventos eliminados nunca llegan al frontend
5. **Modularidad**: Código fácil de mantener y debuggear

## 📊 Métricas de Éxito

- ✅ Todos los archivos < 400 líneas
- ✅ Eventos eliminados NO aparecen en frontend
- ✅ Funcionalidad existente preservada
- ✅ Código más mantenible y debuggeable
- ✅ Problema "EXPO PROYECTOS" solucionado definitivamente

---

# FASE 2: AsistenciaService y AttendanceManager Modular

## 🎯 Objetivo FASE 2
Modularizar AsistenciaService y StudentAttendanceManager separando responsabilidades. El sistema debe seguir exactamente el flujo del backend documentado en DETALLES BACK.md.

## 📏 Límites de Código FASE 2
- **Límite crítico**: 2400 líneas por archivo
- **Límite recomendado**: 400 líneas por archivo
- **Acción automática**: Si archivo > 2000 líneas → modularizar

## 📁 Estructura Modular FASE 2

```
lib/services/asistencia/
├── asistencia_service.dart           (coordinador, max 400 líneas)
├── heartbeat_manager.dart            (heartbeats, max 400 líneas)
├── geofence_manager.dart             (geocerca, max 400 líneas)
└── README.md                         (documentación)

lib/services/attendance/
├── attendance_state_manager.dart     (estados, max 400 líneas)
├── grace_period_manager.dart         (grace periods, max 400 líneas)
├── student_attendance_manager.dart   (coordinador, max 400 líneas)
└── README.md                         (documentación)
```

## 📊 Estados Backend Implementados
- **"presente"**: dentro del radio permitido
- **"pendiente"**: fuera del radio pero <10min del inicio
- **"ausente"**: fuera del radio y >10min
- **"justificado"**: con documento válido
- **"tarde"**: llegó tarde pero dentro del tiempo

## 🔄 Flujo Backend a Implementar
1. Estudiante envía `POST /asistencia/registrar` con coords
2. API verifica evento activo y que no haya registrado antes
3. Se calcula distancia Haversine respecto a geocerca:
   - **Presente**: dentro del radio
   - **Pendiente**: fuera del radio pero antes de 10min del inicio
   - **Ausente**: fuera del radio y pasado tiempo de gracia
4. Cron job cambia "Pendiente" a "Ausente" después de 10min

## 🚨 Grace Periods Duales Sin Conflictos
- **Grace period geofence**: 60 segundos (solo para salidas de geocerca)
- **Grace period app cerrada**: 30 segundos (solo para cierre de app)
- **Heartbeat crítico**: cada 30 segundos obligatorio

---

# FASE 3: DashboardScreen Modular - Preservando Estética

## 🎯 Objetivo FASE 3
Modularizar dashboard_screen.dart manteniendo EXACTAMENTE la estética actual pero separando en widgets especializados por rol. La UI debe verse idéntica al usuario final.

## 📏 Límites de Código FASE 3
- **Límite crítico**: 2400 líneas por archivo
- **Límite recomendado**: 400 líneas por archivo
- **Acción automática**: Si archivo > 2000 líneas → modularizar

## 📁 Estructura Modular FASE 3

```
lib/screens/dashboard/
├── dashboard_screen.dart               (coordinador, max 400 líneas)
└── README.md                           (documentación)

lib/widgets/dashboard/
├── admin_dashboard_section.dart        (admin UI, max 400 líneas)
├── professor_dashboard_section.dart    (profesor UI, max 400 líneas)
├── student_dashboard_section.dart      (estudiante UI, max 400 líneas)
├── dashboard_metrics_widget.dart       (métricas, max 400 líneas)
├── dashboard_events_widget.dart        (eventos, max 400 líneas)
└── README.md                           (documentación widgets)
```

## 🚨 CRÍTICO: Estética Preservada
- **Colores**: AppColors.primaryOrange (#FF6B35), AppColors.secondaryTeal (#4ECDC4)
- **Gradientes y estilos**: mantenidos EXACTAMENTE iguales
- **Animaciones**: preservadas completamente
- **Navegación contextual**: intacta por rol

## 🔄 Navegación por Rol Preservada

### **Admin Dashboard**:
- Métricas del sistema reales
- Vista de todos los eventos
- Alertas del sistema
- Navegación a gestión completa

### **Profesor Dashboard**:
- Solo eventos creados por él
- Botón "Crear Evento" funcional
- Toggle activar/desactivar eventos
- Navegación a event_monitor

### **Estudiante Dashboard**:
- Eventos disponibles para unirse
- Estado actual de tracking
- Botones de justificaciones
- Historial personal

---

**FASE 1**: ✅ Implementado y funcional  
**FASE 2**: ✅ Implementado y funcional  
**FASE 3**: 🔄 En progreso  
**Fecha de actualización**: 2025-08-22  
**Responsable**: Claude Code Assistant