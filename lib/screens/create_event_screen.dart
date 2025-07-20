// lib/screens/create_event_screen.dart - VERSIÓN COMPLETA CON FECHA+HORA
import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../services/evento_service.dart';
import '../models/evento_model.dart';

class CreateEventScreen extends StatefulWidget {
  final Evento? editEvent; // Para modo edición (null = crear nuevo)

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
  final TextEditingController _rangoController = TextEditingController();

  // Servicios
  final EventoService _eventoService = EventoService();

  // Variables de estado
  bool _isLoading = false;
  DateTime? _fechaInicio; // ✅ NUEVO: Fecha + hora inicio
  DateTime? _fechaFinal; // ✅ NUEVO: Fecha + hora fin

  // Ubicación fija para UIDE (por ahora)
  final double _defaultLatitude = -0.1805;
  final double _defaultLongitude = -78.4680;

  // Modo edición
  bool get _isEditMode => widget.editEvent != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  /// Inicializa los campos si estamos en modo edición
  void _initializeFields() {
    if (_isEditMode && widget.editEvent != null) {
      final evento = widget.editEvent!;
      _tituloController.text = evento.titulo;
      _descripcionController.text = evento.descripcion ?? '';
      _rangoController.text = evento.rangoPermitido.toString();
      _fechaInicio = evento.horaInicio;
      _fechaFinal = evento.horaFinal;
    } else {
      // Valores por defecto para nuevo evento
      _rangoController.text = '100'; // Rango por defecto
      _fechaInicio = DateTime.now()
          .add(const Duration(days: 1, hours: 1)); // Mañana + 1 hora
      _fechaFinal = DateTime.now()
          .add(const Duration(days: 1, hours: 3)); // Mañana + 3 horas
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

  /// Construye todos los campos del formulario
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

        // ✅ NUEVO: Fecha y hora de inicio combinados
        _buildDateTimeField(
          label: 'Fecha y hora de inicio',
          icon: Icons.event,
          selectedDateTime: _fechaInicio,
          onDateTimeSelected: (dateTime) =>
              setState(() => _fechaInicio = dateTime),
        ),

        // ✅ NUEVO: Fecha y hora de fin combinados
        _buildDateTimeField(
          label: 'Fecha y hora de fin',
          icon: Icons.event_available,
          selectedDateTime: _fechaFinal,
          onDateTimeSelected: (dateTime) =>
              setState(() => _fechaFinal = dateTime),
        ),

        // Rango permitido
        CustomTextField(
          hintText: 'Rango permitido (metros)',
          controller: _rangoController,
          prefixIcon: Icons.location_on,
          keyboardType: TextInputType.number,
        ),

        // Información de ubicación
        _buildLocationInfo(),
      ],
    );
  }

  /// Información de ubicación
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
          const Text(
            'UIDE Campus Principal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${_defaultLatitude.toStringAsFixed(4)}, '
            'Lng: ${_defaultLongitude.toStringAsFixed(4)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Campo de fecha y hora combinados
  Widget _buildDateTimeField({
    required String label,
    required IconData icon,
    required DateTime? selectedDateTime,
    required Function(DateTime) onDateTimeSelected,
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
          selectedDateTime != null
              ? '$label: ${_formatDateTime(selectedDateTime)}'
              : 'Seleccionar $label',
          style: TextStyle(
            color: selectedDateTime != null
                ? AppColors.darkGray
                : AppColors.textGray,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: AppColors.textGray, size: 16),
        onTap: () => _selectDateTime(onDateTimeSelected),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  /// ✅ NUEVO: Selecciona fecha y hora en un solo picker
  Future<void> _selectDateTime(Function(DateTime) onDateTimeSelected) async {
    // Primero seleccionar fecha
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
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
      // Luego seleccionar hora
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
        // Combinar fecha y hora
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        onDateTimeSelected(selectedDateTime);
      }
    }
  }

  /// ✅ NUEVO: Formatea fecha y hora para mostrar
  String _formatDateTime(DateTime dateTime) {
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
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Maneja el envío del formulario
  Future<void> _handleSubmit() async {
    // Validaciones
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        // Actualizar evento existente
        final response = await _eventoService.actualizarEvento(
          widget.editEvent!.id!,
          {
            'titulo': _tituloController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
            'ubicacion': {
              'latitud': _defaultLatitude,
              'longitud': _defaultLongitude,
            },
            'fechaInicio': _fechaInicio!.toIso8601String(),
            'fechaFinal': _fechaFinal!.toIso8601String(),
            'rangoPermitido': double.parse(_rangoController.text.trim()),
          },
        );

        if (response.success) {
          AppRouter.showSnackBar('¡Evento actualizado exitosamente!');
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          AppRouter.showSnackBar(
            response.error != null
                ? response.error!
                : (response.message.isNotEmpty
                    ? response.message
                    : 'Error al actualizar evento'),
            isError: true,
          );
        }
      } else {
        // Crear nuevo evento
        final response = await _eventoService.crearEvento(
          titulo: _tituloController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          latitud: _defaultLatitude,
          longitud: _defaultLongitude,
          fecha: _fechaInicio!, // Solo para compatibilidad con el servicio
          horaInicio: _fechaInicio!,
          horaFinal: _fechaFinal!,
          rangoPermitido: double.parse(_rangoController.text.trim()),
        );

        if (response.success) {
          AppRouter.showSnackBar('¡Evento creado exitosamente!');
          if (mounted) Navigator.of(context).pop(true); // Indica que se creó
        } else {
          // ✅ AGREGADO: Debug de la respuesta del backend
          debugPrint('Respuesta de error del backend: ${response.error}');
          debugPrint('Mensaje del backend: ${response.message}');
          AppRouter.showSnackBar(
            response.error != null
                ? response.error!
                : (response.message.isNotEmpty
                    ? response.message
                    : 'Error al crear evento'),
            isError: true,
          );
        }
      }
    } catch (e) {
      // ✅ AGREGADO: Debug detallado del error
      debugPrint('Error completo al crear evento: $e');
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

  /// Valida el formulario antes del envío
  bool _validateForm() {
    if (_tituloController.text.trim().isEmpty) {
      AppRouter.showSnackBar('El título del evento es requerido',
          isError: true);
      return false;
    }

    if (_fechaInicio == null) {
      AppRouter.showSnackBar('Selecciona la fecha y hora de inicio',
          isError: true);
      return false;
    }

    if (_fechaFinal == null) {
      AppRouter.showSnackBar('Selecciona la fecha y hora de fin',
          isError: true);
      return false;
    }

    // Validar que la fecha de fin sea después de la de inicio
    if (_fechaFinal!.isBefore(_fechaInicio!) ||
        _fechaFinal!.isAtSameMomentAs(_fechaInicio!)) {
      AppRouter.showSnackBar(
        'La fecha y hora de fin debe ser posterior a la de inicio',
        isError: true,
      );
      return false;
    }

    // Validar rango
    final rango = double.tryParse(_rangoController.text.trim());
    if (rango == null || rango <= 0) {
      AppRouter.showSnackBar(
        'Ingresa un rango válido mayor a 0',
        isError: true,
      );
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _rangoController.dispose();
    super.dispose();
  }
}
