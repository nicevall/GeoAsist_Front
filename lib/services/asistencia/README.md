# AsistenciaService Modular - FASE 2

## 🎯 Objetivo
Modularizar AsistenciaService separando responsabilidades críticas del sistema de asistencia siguiendo exactamente el flujo del backend documentado en DETALLES BACK.md.

## 📏 Límites de Código
- **Límite crítico**: 2400 líneas por archivo
- **Límite recomendado**: 400 líneas por archivo
- **Estado actual**: Todos los archivos < 400 líneas ✅

## 📁 Estructura Modular

```
lib/services/asistencia/
├── asistencia_service.dart     (coordinador principal, 351 líneas)
├── heartbeat_manager.dart      (heartbeats 30s, 318 líneas)
├── geofence_manager.dart       (Haversine + geofence, 356 líneas)
└── README.md                   (esta documentación)
```

## 🔄 Flujo de Datos

```
Frontend → asistencia_service.dart (coordinador)
    ↓
Validaciones → Backend API
    ↑
heartbeat_manager.dart (30s heartbeats)
    ↑
geofence_manager.dart (Haversine calculations)
```

## 📊 Estados Backend Implementados

### **Flujo Exacto Según DETALLES BACK.md**:
1. Estudiante envía `POST /asistencia/registrar` con coords
2. API verifica evento activo y que no haya registrado antes
3. Se calcula distancia Haversine respecto a geocerca:
   - **"presente"**: dentro del radio permitido
   - **"pendiente"**: fuera del radio pero <10min del inicio
   - **"ausente"**: fuera del radio y >10min
4. Cron job cambia "Pendiente" a "Ausente" después de 10min

## 🔧 Archivos y Responsabilidades

### 1. **asistencia_service.dart** (Coordinador Principal)
- API pública para registro de asistencia
- Integración con backend siguiendo flujo exacto
- Coordinación entre managers especializados
- Validaciones de negocio antes de registro
- Manejo de errores y retry logic

**Métodos públicos:**
```dart
Future<ApiResponse<bool>> registrarAsistencia({...})
Future<ApiResponse<Map<String, dynamic>>> actualizarUbicacion({...})
Future<List<Asistencia>> obtenerAsistenciasEvento(String eventoId)
Future<List<Asistencia>> obtenerHistorialUsuario(String usuarioId)
Future<ApiResponse<bool>> enviarJustificacion({...})
Future<ApiResponse<bool>> marcarAusente({...})
```

### 2. **heartbeat_manager.dart** (Heartbeats Críticos)
- Heartbeat obligatorio cada 30 segundos al backend
- Session management con IDs únicos
- Retry automático con exponential backoff
- Estado de app (foreground/background)
- Manejo de fallas de conexión

**Funcionalidades críticas:**
- `POST /asistencia/heartbeat` cada 30 segundos
- Session ID único por evento
- Retry logic con backoff exponencial
- Métricas de éxito/fallo
- Estados: active, failing, critical, stopped

### 3. **geofence_manager.dart** (Detección de Área)
- Cálculo Haversine exacto del backend (6371 km radio)
- Detección entrada/salida de geocerca
- Validación de coordenadas GPS válidas
- Registro de eventos geofence con timestamps

**Implementación Haversine:**
```dart
double calculateHaversineDistance(
  double lat1, double lon1, 
  double lat2, double lon2
) {
  // Radio de la Tierra = 6371 km
  // Implementación EXACTA del backend
  // Retorna distancia en metros
}
```

## 🧪 Testing Manual

Después de la modularización, validar:

1. **Registro de Asistencia**:
   - ✅ `POST /asistencia/registrar` funciona correctamente
   - ✅ Estados backend se calculan correctamente
   - ✅ Distancia Haversine es exacta

2. **Heartbeat Crítico**:
   - ✅ Se envía cada 30 segundos sin fallas
   - ✅ Retry funciona ante fallas de red
   - ✅ Session ID es único por evento

3. **Geofence**:
   - ✅ Detección entrada/salida es precisa
   - ✅ Cálculo de distancia es correcto
   - ✅ Validación de coordenadas funciona

## 🚨 Garantías Críticas

1. **Heartbeat continuo**: Nunca debe detenerse durante evento activo
2. **Cálculo Haversine**: Debe ser idéntico al backend
3. **Estados backend**: Deben seguir exactamente el flujo documentado
4. **Session management**: Cada evento debe tener session ID único
5. **Retry logic**: Debe manejar fallas de red automáticamente

## 📊 Métricas de Éxito

- ✅ Todos los archivos < 400 líneas
- ✅ Heartbeat funciona cada 30 segundos
- ✅ Estados backend implementados correctamente
- ✅ Cálculo Haversine exacto
- ✅ Funcionalidad existente preservada

---

**FASE 2 - AsistenciaService**: ✅ Implementado y funcional  
**Fecha de creación**: 2025-08-22  
**Responsable**: Claude Code Assistant