// lib/screens/create_event_screen.dart - HORARIOS ESPECÍFICOS POR DÍA
import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../services/evento_service.dart';
import '../models/evento_model.dart';
import '../core/app_constants.dart';
import '../utils/location_helper.dart';
import 'package:flutter/foundation.dart';

// ✅ NUEVO: Modelo para día específico del evento
class EventDay {
  final DateTime fecha;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFinal;

  EventDay({
    required this.fecha,
    required this.horaInicio,
    required this.horaFinal,
  });

  DateTime get fechaInicioCompleta => DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        horaInicio.hour,
        horaInicio.minute,
      );

  DateTime get fechaFinalCompleta => DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        horaFinal.hour,
        horaFinal.minute,
      );
}

class CreateEventScreen extends StatefulWidget {
  final Evento? editEvent;

  const CreateEventScreen({
    super.key,
    this.editEvent,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  // Controladores de texto
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  // Servicios
  final EventoService _eventoService = EventoService();

  // Controladores adicionales para el backend
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _lugarController = TextEditingController();
  final TextEditingController _capacidadController = TextEditingController();

  // Variables de estado
  bool _isLoading = false;
  bool _isMultiDay = false;

  // Para evento de un solo día
  DateTime? _fechaUnica;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFinal;

  // ✅ NUEVO: Para eventos multi-día con horarios específicos
  List<EventDay> _eventDays = [];

  // ✅ CORREGIDO: Variables de ubicación que se pueden cambiar
  double _selectedLatitude = AppConstants.defaultLatitude; // Valor inicial, pero modificable
  double _selectedLongitude = AppConstants.defaultLongitude; // Valor inicial, pero modificable
  double _selectedRange = AppConstants.defaultRange;
  String _selectedLocationName = AppConstants.defaultAddress;

  // ✅ NUEVO: Tipos de evento disponibles
  final List<String> _tiposEvento = [
    'clase',
    'seminario',
    'conferencia',
    'taller',
    'evaluacion'
  ];
  String _selectedTipo = 'clase';

  // ✅ NUEVO: Configuraciones de políticas de asistencia
  int _tiempoGracia = 10; // minutos
  int _maximoSalidas = 3;
  final int _tiempoLimiteSalida = 15; // minutos
  bool _verificacionContinua = true;
  bool _requiereJustificacion = false;

  bool get _isEditMode => widget.editEvent != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (_isEditMode && widget.editEvent != null) {
      final evento = widget.editEvent!;
      _tituloController.text = evento.titulo;
      _descripcionController.text = evento.descripcion ?? '';
      _selectedRange = evento.rangoPermitido;

      // ✅ NUEVO: Cargar ubicación real del evento
      _selectedLatitude = evento.ubicacion.latitud;
      _selectedLongitude = evento.ubicacion.longitud;

      // ✅ NUEVO: Inicializar campos adicionales para edición
      _tipoController.text = 'clase'; // Valor por defecto si no está disponible
      _lugarController.text = 'UIDE Campus Principal'; // Valor por defecto
      _capacidadController.text = '50'; // Valor por defecto

      // Determinar si es multi-día
      final fechaInicio = DateTime(
        evento.horaInicio.year,
        evento.horaInicio.month,
        evento.horaInicio.day,
      );
      final fechaFinal = DateTime(
        evento.horaFinal.year,
        evento.horaFinal.month,
        evento.horaFinal.day,
      );

      _isMultiDay = !fechaInicio.isAtSameMomentAs(fechaFinal);

      if (_isMultiDay) {
        // ✅ Implementación básica de múltiples días
        _eventDays = _generateDaysFromRange(fechaInicio, fechaFinal, evento.horaInicio, evento.horaFinal);
      } else {
        _fechaUnica = fechaInicio;
        _horaInicio = TimeOfDay.fromDateTime(evento.horaInicio);
        _horaFinal = TimeOfDay.fromDateTime(evento.horaFinal);
      }
    } else {
      // Valores por defecto
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _fechaUnica = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      _horaInicio = const TimeOfDay(hour: 8, minute: 0);
      _horaFinal = const TimeOfDay(hour: 10, minute: 0);
      _isMultiDay = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Evento' : 'Crear Evento'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Icono y título
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.event_note,
                  color: AppColors.white,
                  size: 50,
                ),
              ),

              const SizedBox(height: 30),

              Text(
                _isEditMode ? 'EDITAR EVENTO' : 'NUEVO EVENTO',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                _isEditMode
                    ? 'Modifica la información del evento'
                    : 'Completa la información del evento de asistencia',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Campos del formulario
              _buildFormFields(),

              const SizedBox(height: 30),

              // Botón de acción
              _isLoading
                  ? const CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    )
                  : CustomButton(
                      text: _isEditMode ? 'Actualizar Evento' : 'Crear Evento',
                      onPressed: _handleSubmit,
                    ),

              const SizedBox(height: 16),

              // Botón cancelar
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Título del evento (REQUERIDO por backend: nombre)
        CustomTextField(
          hintText: 'Título del evento',
          controller: _tituloController,
          prefixIcon: Icons.title,
          keyboardType: TextInputType.text,
        ),

        // ✅ NUEVO: Tipo de evento (REQUERIDO por backend)
        _buildTipoEventoDropdown(),

        // ✅ NUEVO: Lugar del evento (REQUERIDO por backend)
        CustomTextField(
          hintText: 'Lugar del evento (ej: Aula 205, Laboratorio A)',
          controller: _lugarController,
          prefixIcon: Icons.location_city,
          keyboardType: TextInputType.text,
        ),

        // Descripción
        CustomTextField(
          hintText: 'Descripción (opcional)',
          controller: _descripcionController,
          prefixIcon: Icons.description,
          keyboardType: TextInputType.multiline,
        ),

        // ✅ NUEVO: Capacidad máxima
        CustomTextField(
          hintText: 'Capacidad máxima de estudiantes',
          controller: _capacidadController,
          prefixIcon: Icons.group,
          keyboardType: TextInputType.number,
        ),

        // Switch para evento multi-día
        _buildMultiDaySwitch(),

        // Campos según tipo de evento
        if (_isMultiDay) ...[
          _buildMultiDaySchedule(),
        ] else ...[
          _buildSingleDateField(),
          _buildTimeField(
            label: 'Hora de inicio',
            icon: Icons.access_time,
            selectedTime: _horaInicio,
            onTimeSelected: (time) => setState(() => _horaInicio = time),
          ),
          _buildTimeField(
            label: 'Hora de fin',
            icon: Icons.access_time_filled,
            selectedTime: _horaFinal,
            onTimeSelected: (time) => setState(() => _horaFinal = time),
          ),
        ],

        // ✅ MEJORADO: Información de ubicación con rango
        _buildLocationInfo(),
        
        // ✅ DEBUG: Widget de depuración (solo en modo debug)
        if (kDebugMode) _buildLocationDebugInfo(),
        
        // ✅ NUEVO: Configuraciones de política de asistencia
        _buildAttendancePolicyConfig(),
      ],
    );
  }

  /// ✅ NUEVO: Dropdown para seleccionar tipo de evento
  Widget _buildTipoEventoDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedTipo,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.category, color: AppColors.textGray),
          hintText: 'Tipo de evento',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        items: _tiposEvento.map((String tipo) {
          return DropdownMenuItem<String>(
            value: tipo,
            child: Text(
              tipo.toUpperCase(),
              style: const TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() => _selectedTipo = newValue);
          }
        },
        dropdownColor: AppColors.white,
        style: const TextStyle(color: AppColors.darkGray),
      ),
    );
  }

  /// Switch para eventos multi-día
  Widget _buildMultiDaySwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.event_repeat, color: AppColors.textGray),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evento de múltiples días',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  _isMultiDay
                      ? 'Configura horarios específicos por día'
                      : 'Evento de un solo día con horarios específicos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isMultiDay,
            onChanged: (value) {
              setState(() {
                _isMultiDay = value;
                if (_isMultiDay) {
                  // Inicializar con el primer día
                  _eventDays = [
                    EventDay(
                      fecha: _fechaUnica ??
                          DateTime.now().add(const Duration(days: 1)),
                      horaInicio:
                          _horaInicio ?? const TimeOfDay(hour: 8, minute: 0),
                      horaFinal:
                          _horaFinal ?? const TimeOfDay(hour: 10, minute: 0),
                    ),
                  ];
                  _fechaUnica = null;
                  _horaInicio = null;
                  _horaFinal = null;
                } else {
                  // Volver a modo de un día
                  if (_eventDays.isNotEmpty) {
                    _fechaUnica = _eventDays.first.fecha;
                    _horaInicio = _eventDays.first.horaInicio;
                    _horaFinal = _eventDays.first.horaFinal;
                  }
                  _eventDays.clear();
                }
              });
            },
            activeColor: AppColors.primaryOrange,
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Gestión de horarios multi-día
  Widget _buildMultiDaySchedule() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Horarios por Día',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              IconButton(
                onPressed: _addEventDay,
                icon: const Icon(Icons.add_circle,
                    color: AppColors.primaryOrange),
                tooltip: 'Agregar día',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Lista de días del evento
          if (_eventDays.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Agrega días al evento',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ] else ...[
            ...List.generate(
                _eventDays.length, (index) => _buildEventDayCard(index)),
          ],
        ],
      ),
    );
  }

  /// ✅ NUEVO: Tarjeta de día individual
  Widget _buildEventDayCard(int index) {
    final eventDay = _eventDays[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Día ${index + 1}: ${_formatDate(eventDay.fecha)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeEventDay(index),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInlineTimePicker(
                  'Inicio: ${_formatTime(eventDay.horaInicio)}',
                  eventDay.horaInicio,
                  (time) => _updateEventDayTime(index, horaInicio: time),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInlineTimePicker(
                  'Fin: ${_formatTime(eventDay.horaFinal)}',
                  eventDay.horaFinal,
                  (time) => _updateEventDayTime(index, horaFinal: time),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Selector de tiempo inline
  Widget _buildInlineTimePicker(
      String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.primaryOrange,
                    ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.darkGray,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Campo para fecha única
  Widget _buildSingleDateField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: AppColors.textGray),
        title: Text(
          _fechaUnica != null
              ? 'Fecha: ${_formatDate(_fechaUnica!)}'
              : 'Seleccionar fecha del evento',
          style: TextStyle(
            color:
                _fechaUnica != null ? AppColors.darkGray : AppColors.textGray,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: AppColors.textGray, size: 16),
        onTap: _selectSingleDate,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  /// Campo para hora
  Widget _buildTimeField({
    required String label,
    required IconData icon,
    required TimeOfDay? selectedTime,
    required Function(TimeOfDay) onTimeSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textGray),
        title: Text(
          selectedTime != null
              ? '$label: ${_formatTime(selectedTime)}'
              : 'Seleccionar $label',
          style: TextStyle(
            color:
                selectedTime != null ? AppColors.darkGray : AppColors.textGray,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: AppColors.textGray, size: 16),
        onTap: () => _selectTime(onTimeSelected),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  /// ✅ MEJORADO: Información de ubicación con rango visible
  Widget _buildLocationInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondaryTeal, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.secondaryTeal),
              SizedBox(width: 8),
              Text(
                'Ubicación del Evento',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _selectedLocationName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${_selectedLatitude.toStringAsFixed(4)}, '
            'Lng: ${_selectedLongitude.toStringAsFixed(4)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),

          // ✅ NUEVO: Mostrar rango seleccionado
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.radio_button_checked,
                  color: AppColors.primaryOrange,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Rango: ${_selectedRange.toInt()}m',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ✅ BOTÓN FUNCIONAL: Navegar a selector de mapa
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openLocationPicker,
              icon: const Icon(Icons.map, size: 20),
              label: const Text(
                'Seleccionar en Mapa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Configuración de políticas de asistencia
  Widget _buildAttendancePolicyConfig() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.policy, color: AppColors.primaryOrange),
              SizedBox(width: 8),
              Text(
                'Políticas de Asistencia',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tiempo de gracia
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Tiempo de gracia (min):',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _tiempoGracia.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  label: '$_tiempoGracia min',
                  onChanged: (value) =>
                      setState(() => _tiempoGracia = value.toInt()),
                  activeColor: AppColors.primaryOrange,
                ),
              ),
              Text('$_tiempoGracia min'),
            ],
          ),

          // Máximo de salidas
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Máximo salidas permitidas:',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _maximoSalidas.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_maximoSalidas',
                  onChanged: (value) =>
                      setState(() => _maximoSalidas = value.toInt()),
                  activeColor: AppColors.primaryOrange,
                ),
              ),
              Text('$_maximoSalidas'),
            ],
          ),

          // Switches de configuración
          SwitchListTile(
            title: const Text('Verificación continua',
                style: TextStyle(fontSize: 14)),
            subtitle: const Text('Monitorear ubicación durante todo el evento',
                style: TextStyle(fontSize: 12)),
            value: _verificacionContinua,
            onChanged: (value) => setState(() => _verificacionContinua = value),
            activeColor: AppColors.primaryOrange,
            contentPadding: EdgeInsets.zero,
          ),

          SwitchListTile(
            title: const Text('Requiere justificación',
                style: TextStyle(fontSize: 14)),
            subtitle: const Text('Los estudiantes pueden justificar ausencias',
                style: TextStyle(fontSize: 12)),
            value: _requiereJustificacion,
            onChanged: (value) =>
                setState(() => _requiereJustificacion = value),
            activeColor: AppColors.primaryOrange,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// ✅ DEBUG: Widget temporal para verificar datos de ubicación (solo debug)
  Widget _buildLocationDebugInfo() {
    if (!kDebugMode) return const SizedBox.shrink(); // Solo en debug
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEBUG - Ubicación seleccionada:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text('Latitud: $_selectedLatitude'),
          Text('Longitud: $_selectedLongitude'),
          Text('Nombre: $_selectedLocationName'),
          Text('Rango: $_selectedRange m'),
          Text('¿Es ubicación por defecto?: ${LocationHelper.isDefaultLocation(_selectedLatitude, _selectedLongitude)}'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('=== DEBUG MANUAL ===');
                    debugPrint(_validateLocationDataBeforeSending() 
                        ? 'Validación exitosa' 
                        : 'Validación falló');
                    debugPrint('==================');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Debug Validation',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedLatitude = -0.2;
                      _selectedLongitude = -78.5;
                      _selectedLocationName = 'Ubicación de prueba';
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text(
                    'Test Custom',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Método para abrir el selector de ubicación
  Future<void> _openLocationPicker() async {
    debugPrint('=== DEPURACIÓN UBICACIÓN FRONTEND ===');
    debugPrint('Ubicación inicial antes del picker:');
    debugPrint('  - Lat: $_selectedLatitude');
    debugPrint('  - Lng: $_selectedLongitude');
    debugPrint('  - Range: $_selectedRange');
    debugPrint('  - Name: $_selectedLocationName');
    
    final result = await Navigator.of(context).pushNamed(
      AppConstants.locationPickerRoute,
      arguments: {
        'initialLatitude': _selectedLatitude,
        'initialLongitude': _selectedLongitude,
        'initialRange': _selectedRange,
        'initialLocationName': _selectedLocationName,
      },
    );

    debugPrint('Resultado del LocationPicker: $result');
    debugPrint('Tipo del resultado: ${result.runtimeType}');

    // Actualizar las variables si el usuario seleccionó una ubicación
    if (result != null && result is Map<String, dynamic>) {
      final previousLat = _selectedLatitude;
      final previousLng = _selectedLongitude;
      final previousName = _selectedLocationName;
      
      // Usar LocationHelper para normalizar los datos
      final normalizedResult = LocationHelper.normalizeLocationPickerResult(result);
      debugPrint('Datos normalizados: $normalizedResult');
      
      // Validar datos antes de usar
      if (LocationHelper.isLocationValid(normalizedResult)) {
        setState(() {
          _selectedLatitude = normalizedResult['latitude'];
          _selectedLongitude = normalizedResult['longitude'];
          _selectedRange = normalizedResult['range'];
          _selectedLocationName = normalizedResult['address'];
        });

        debugPrint('Ubicación después de la selección:');
        debugPrint('  - Lat: $_selectedLatitude (anterior: $previousLat)');
        debugPrint('  - Lng: $_selectedLongitude (anterior: $previousLng)');
        debugPrint('  - Range: $_selectedRange');
        debugPrint('  - Name: $_selectedLocationName (anterior: $previousName)');
        
        final bool locationChanged = (previousLat != _selectedLatitude || 
                                    previousLng != _selectedLongitude ||
                                    previousName != _selectedLocationName);
        debugPrint('¿Ubicación cambió?: $locationChanged');
        
        // Mostrar resumen completo usando LocationHelper
        debugPrint(LocationHelper.getLocationSummary(
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          locationName: _selectedLocationName,
          range: _selectedRange,
        ));
      } else {
        debugPrint('❌ Datos de ubicación inválidos recibidos del picker');
      }
      debugPrint('=====================================');
    } else {
      debugPrint('❌ Resultado del picker es null o formato inválido');
      debugPrint('=====================================');
    }
  }

  // ✅ NUEVOS: Métodos para manejar eventos multi-día
  void _addEventDay() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _eventDays.isNotEmpty
          ? _eventDays.last.fecha.add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryOrange,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _eventDays.add(EventDay(
          fecha: pickedDate,
          horaInicio: const TimeOfDay(hour: 8, minute: 0),
          horaFinal: const TimeOfDay(hour: 18, minute: 0),
        ));
      });
    }
  }

  void _removeEventDay(int index) {
    setState(() {
      _eventDays.removeAt(index);
    });
  }

  void _updateEventDayTime(int index,
      {TimeOfDay? horaInicio, TimeOfDay? horaFinal}) {
    setState(() {
      final currentDay = _eventDays[index];
      _eventDays[index] = EventDay(
        fecha: currentDay.fecha,
        horaInicio: horaInicio ?? currentDay.horaInicio,
        horaFinal: horaFinal ?? currentDay.horaFinal,
      );
    });
  }

  // Métodos existentes...
  Future<void> _selectSingleDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaUnica ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryOrange,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      setState(() => _fechaUnica = pickedDate);
    }
  }

  Future<void> _selectTime(Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryOrange,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      onTimeSelected(pickedTime);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      DateTime fechaInicio;
      DateTime fechaFinal;

      if (_isMultiDay) {
        // ✅ NUEVO: Para eventos multi-día, usar el primer y último día
        _eventDays.sort((a, b) => a.fecha.compareTo(b.fecha));

        final firstDay = _eventDays.first;
        final lastDay = _eventDays.last;

        fechaInicio = firstDay.fechaInicioCompleta;
        fechaFinal = lastDay.fechaFinalCompleta;

        // ✅ Para múltiples días, enviamos el rango completo al backend
        // El backend puede manejar eventos de múltiples días usando fecha inicio y final
      } else {
        fechaInicio = DateTime(
          _fechaUnica!.year,
          _fechaUnica!.month,
          _fechaUnica!.day,
          _horaInicio!.hour,
          _horaInicio!.minute,
        );
        fechaFinal = DateTime(
          _fechaUnica!.year,
          _fechaUnica!.month,
          _fechaUnica!.day,
          _horaFinal!.hour,
          _horaFinal!.minute,
        );
      }

      if (_isEditMode) {
        final response = await _eventoService.editarEvento(
          eventoId: widget.editEvent!.id!,
          titulo: _tituloController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          tipo: _selectedTipo,
          lugar: _lugarController.text.trim().isEmpty
              ? _selectedLocationName
              : _lugarController.text.trim(),
          capacidadMaxima: int.tryParse(_capacidadController.text.trim()) ?? 50,
          latitud: _selectedLatitude,
          longitud: _selectedLongitude,
          fecha: _fechaUnica ?? _eventDays.first.fecha,
          horaInicio: fechaInicio,
          horaFinal: fechaFinal,
          rangoPermitido: _selectedRange,
          tiempoGracia: _tiempoGracia,
          maximoSalidas: _maximoSalidas,
          tiempoLimiteSalida: _tiempoLimiteSalida,
          verificacionContinua: _verificacionContinua,
          requiereJustificacion: _requiereJustificacion,
        );

        if (response.success) {
          AppRouter.showSnackBar('¡Evento actualizado exitosamente!');
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          AppRouter.showSnackBar(
            response.error ?? response.message,
            isError: true,
          );
        }
      } else {
        // ✅ VALIDACIÓN ROBUSTA: Verificar datos de ubicación antes de envío
        if (!_validateLocationDataBeforeSending()) {
          return; // No proceder si los datos son inválidos
        }

        final response = await _eventoService.crearEvento(
          titulo: _tituloController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          tipo: _selectedTipo, // ✅ NUEVO: Campo requerido por backend
          lugar: _lugarController.text.trim().isEmpty
              ? _selectedLocationName
              : _lugarController.text.trim(), // ✅ NUEVO: Campo requerido
          capacidadMaxima:
              int.tryParse(_capacidadController.text.trim()) ?? 50, // ✅ NUEVO
          latitud: _selectedLatitude,
          longitud: _selectedLongitude,
          fecha: _fechaUnica ?? _eventDays.first.fecha,
          horaInicio: fechaInicio,
          horaFinal: fechaFinal,
          rangoPermitido: _selectedRange,
          // ✅ NUEVO: Políticas de asistencia
          tiempoGracia: _tiempoGracia,
          maximoSalidas: _maximoSalidas,
          tiempoLimiteSalida: _tiempoLimiteSalida,
          verificacionContinua: _verificacionContinua,
          requiereJustificacion: _requiereJustificacion,
        );

        if (response.success) {
          AppRouter.showSnackBar('¡Evento creado exitosamente!');
          if (mounted) Navigator.of(context).pop(true);
        } else {
          debugPrint('❌ Error del backend: ${response.error}');
          debugPrint('❌ Mensaje del backend: ${response.message}');
          AppRouter.showSnackBar(
            response.error ?? response.message,
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error completo: $e');
      AppRouter.showSnackBar(
        'Error: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateForm() {
    if (_tituloController.text.trim().isEmpty) {
      AppRouter.showSnackBar('El título del evento es requerido',
          isError: true);
      return false;
    }

    if (_lugarController.text.trim().isEmpty) {
      AppRouter.showSnackBar('El lugar del evento es requerido', isError: true);
      return false;
    }

    if (_capacidadController.text.trim().isEmpty ||
        int.tryParse(_capacidadController.text.trim()) == null ||
        int.parse(_capacidadController.text.trim()) <= 0) {
      AppRouter.showSnackBar('La capacidad debe ser un número válido mayor a 0',
          isError: true);
      return false;
    }

    if (_isMultiDay) {
      // Validaciones para eventos multi-día
      if (_eventDays.isEmpty) {
        AppRouter.showSnackBar('Agrega al menos un día al evento',
            isError: true);
        return false;
      }

      // Validar que cada día tenga horarios válidos
      for (int i = 0; i < _eventDays.length; i++) {
        final day = _eventDays[i];
        final inicioMinutos = day.horaInicio.hour * 60 + day.horaInicio.minute;
        final finalMinutos = day.horaFinal.hour * 60 + day.horaFinal.minute;

        if (finalMinutos <= inicioMinutos) {
          AppRouter.showSnackBar(
            'En el día ${i + 1}, la hora de fin debe ser posterior a la de inicio',
            isError: true,
          );
          return false;
        }
      }

      // Validar que no haya fechas duplicadas
      final fechas = _eventDays.map((day) => day.fecha).toList();
      final fechasUnicas = fechas.toSet();
      if (fechas.length != fechasUnicas.length) {
        AppRouter.showSnackBar(
          'No puede haber fechas duplicadas en el evento',
          isError: true,
        );
        return false;
      }
    } else {
      // Validaciones para eventos de un día
      if (_fechaUnica == null) {
        AppRouter.showSnackBar('Selecciona la fecha del evento', isError: true);
        return false;
      }

      if (_horaInicio == null) {
        AppRouter.showSnackBar('Selecciona la hora de inicio', isError: true);
        return false;
      }

      if (_horaFinal == null) {
        AppRouter.showSnackBar('Selecciona la hora de fin', isError: true);
        return false;
      }

      // Validar que la hora de fin sea después de la de inicio
      final inicioMinutos = _horaInicio!.hour * 60 + _horaInicio!.minute;
      final finalMinutos = _horaFinal!.hour * 60 + _horaFinal!.minute;

      if (finalMinutos <= inicioMinutos) {
        AppRouter.showSnackBar(
          'La hora de fin debe ser posterior a la de inicio',
          isError: true,
        );
        return false;
      }
    }

    return true;
  }

  /// ✅ NUEVO: Validación robusta de datos de ubicación antes del envío
  bool _validateLocationDataBeforeSending() {
    debugPrint('=== VALIDACIÓN ROBUSTA DE UBICACIÓN ===');
    
    final lugar = _lugarController.text.trim().isEmpty 
        ? _selectedLocationName 
        : _lugarController.text.trim();
    
    // Usar LocationHelper para validación completa
    final validationResult = LocationHelper.validateLocationBeforeSend(
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      locationName: lugar,
      range: _selectedRange,
    );
    
    debugPrint('Datos de ubicación a validar:');
    debugPrint('  - Título: ${_tituloController.text.trim()}');
    debugPrint('  - Lugar: $lugar');
    debugPrint('  - Latitud: $_selectedLatitude');
    debugPrint('  - Longitud: $_selectedLongitude');
    debugPrint('  - Rango: $_selectedRange');
    debugPrint('  - Tipo: $_selectedTipo');
    
    // Mostrar resumen completo
    debugPrint(LocationHelper.getLocationSummary(
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      locationName: lugar,
      range: _selectedRange,
    ));
    
    debugPrint('Resultado de validación: ${validationResult.isValid}');
    if (!validationResult.isValid) {
      debugPrint('Errores encontrados: ${validationResult.errors}');
      AppRouter.showSnackBar(
        'Error en ubicación: ${validationResult.errorMessage}',
        isError: true,
      );
      debugPrint('======================================');
      return false;
    }
    
    debugPrint('✅ Validación exitosa - Procediendo con creación del evento');
    debugPrint('======================================');
    return true;
  }

  /// ✅ Generar días de evento desde un rango de fechas
  List<EventDay> _generateDaysFromRange(DateTime startDate, DateTime endDate, DateTime startTime, DateTime endTime) {
    final List<EventDay> days = [];
    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime lastDate = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(lastDate) || currentDate.isAtSameMomentAs(lastDate)) {
      days.add(EventDay(
        fecha: currentDate,
        horaInicio: TimeOfDay.fromDateTime(startTime),
        horaFinal: TimeOfDay.fromDateTime(endTime),
      ));
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return days;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _tipoController.dispose();
    _lugarController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }
}
