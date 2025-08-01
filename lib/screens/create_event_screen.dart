// lib/screens/create_event_screen.dart - HORARIOS ESPECÍFICOS POR DÍA
import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../services/evento_service.dart';
import '../models/evento_model.dart';

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

  // Variables de estado
  bool _isLoading = false;
  bool _isMultiDay = false;

  // Para evento de un solo día
  DateTime? _fechaUnica;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFinal;

  // ✅ NUEVO: Para eventos multi-día con horarios específicos
  List<EventDay> _eventDays = [];

  // ✅ NUEVO: Ubicación y rango seleccionados
  final double _selectedLatitude = -0.1805; // UIDE por defecto
  final double _selectedLongitude = -78.4680;
  double _selectedRange = 100.0; // NO final - se puede modificar en UI
  final String _selectedLocationName = 'UIDE Campus Principal';

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
      _selectedRange = evento.rangoPermitido; // ✅ NUEVO: Cargar rango

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
        // TODO: Implementar carga de múltiples días desde el backend
        _eventDays = [
          EventDay(
            fecha: fechaInicio,
            horaInicio: TimeOfDay.fromDateTime(evento.horaInicio),
            horaFinal: TimeOfDay.fromDateTime(evento.horaFinal),
          ),
        ];
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
        // Título del evento
        CustomTextField(
          hintText: 'Título del evento',
          controller: _tituloController,
          prefixIcon: Icons.title,
          keyboardType: TextInputType.text,
        ),

        // Descripción
        CustomTextField(
          hintText: 'Descripción (opcional)',
          controller: _descripcionController,
          prefixIcon: Icons.description,
          keyboardType: TextInputType.multiline,
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
      ],
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
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navegar a pantalla de selección de mapa con slider de rango
              AppRouter.showSnackBar(
                  'Próximamente: Selector de ubicación y rango en mapa');
            },
            icon: const Icon(Icons.map, size: 16),
            label: const Text('Seleccionar en Mapa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryTeal,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
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

        // TODO: Aquí necesitarías enviar todos los días al backend
        // Por ahora enviamos solo el primero y último para compatibilidad
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
        final response = await _eventoService.actualizarEvento(
          widget.editEvent!.id!,
          {
            'titulo': _tituloController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
            'ubicacion': {
              'latitud': _selectedLatitude,
              'longitud': _selectedLongitude,
            },
            // ✅ CORREGIDO: Usar nombres del backend original
            'fecha': fechaInicio.toIso8601String(),
            'horaInicio': fechaInicio.toIso8601String(),
            'horaFinal': fechaFinal.toIso8601String(),
            'rangoPermitido': _selectedRange,
          },
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
        final response = await _eventoService.crearEvento(
          titulo: _tituloController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          latitud: _selectedLatitude,
          longitud: _selectedLongitude,
          fecha: _fechaUnica ?? _eventDays.first.fecha, // Solo fecha base
          horaInicio: fechaInicio, // Fecha + hora inicio
          horaFinal: fechaFinal, // Fecha + hora fin
          rangoPermitido: _selectedRange,
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

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
