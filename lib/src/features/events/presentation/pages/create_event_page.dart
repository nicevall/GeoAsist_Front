import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/use_cases/create_event_use_case.dart';
import '../controllers/event_management_controller.dart';
// Unused import removed: event_form_widget
import '../widgets/location_picker_widget.dart';
// Progress widget is implemented inline in this file

/// **CreateEventPage**: Modern UI for comprehensive event creation
/// 
/// **Purpose**: Provides intuitive multi-step interface for event creation with validation
/// **AI Context**: Stateful page managing complex event creation workflow with location services
/// **Dependencies**: EventManagementController via Provider, location services
/// **Used by**: Event management system when professors create new events
/// **Performance**: Optimized form handling with real-time validation and location services
class CreateEventPage extends StatefulWidget {
  /// **Property**: Route name for navigation system
  /// **AI Context**: Used by router for type-safe navigation
  static const String routeName = '/events/create';

  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage>
    with TickerProviderStateMixin {
  /// **Property**: Page controller for multi-step wizard navigation
  /// **AI Context**: Controls smooth navigation between creation steps
  final PageController _pageController = PageController();

  /// **Property**: Animation controller for smooth transitions
  /// **AI Context**: Provides polished transitions between form steps
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  /// **Property**: Global key for form validation across steps
  /// **AI Context**: Enables comprehensive form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// **Property**: Current step in the creation wizard
  /// **AI Context**: Tracks progress through multi-step creation process
  int _currentStep = 0;

  /// **Property**: Total number of steps in creation wizard
  /// **AI Context**: Used for progress indication and navigation
  static const int _totalSteps = 4;

  /// **Property**: Form data collection across all steps
  /// **AI Context**: Accumulates form data as user progresses through wizard
  final Map<String, dynamic> _eventFormData = {};

  /// **Property**: Validation state for each step
  /// **AI Context**: Tracks which steps have been completed and validated
  final List<bool> _stepValidationStatus = List.filled(_totalSteps, false);

  @override
  void initState() {
    super.initState();
    
    // AI Context: Initialize animation controller for smooth transitions
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // AI Context: Start animation and setup event controller listener
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupEventControllerListener();
    });
  }

  @override
  void dispose() {
    // AI Context: Clean up controllers and animations to prevent memory leaks
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<EventManagementController>(
        builder: (context, eventController, child) {
          // AI Context: Show loading overlay during event creation
          if (eventController.isOperationInProgress) {
            return _buildLoadingOverlay(context);
          }

          return SafeArea(
            child: Column(
              children: [
                // AI Context: Custom app bar with progress indication
                _buildCustomAppBar(context, eventController),
                
                // AI Context: Progress indicator showing current step
                _buildEventCreationProgressWidget(),

                // AI Context: Main content area with form steps
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildEventCreationWizard(context, eventController),
                  ),
                ),

                // AI Context: Navigation controls for wizard steps
                _buildNavigationControls(context, eventController),
              ],
            ),
          );
        },
      ),
    );
  }

  /// **Method**: Build custom app bar with context-aware title and actions
  /// **AI Context**: Creates modern app bar with step-specific titles and actions
  /// **Returns**: Widget containing styled app bar
  Widget _buildCustomAppBar(BuildContext context, EventManagementController controller) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // AI Context: Back button with confirmation if form has data
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _handleBackNavigation(context),
            tooltip: 'Cancelar creación',
          ),
          
          const SizedBox(width: 8),
          
          // AI Context: Step-specific title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear Evento',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                
                Text(
                  _getStepTitle(_currentStep),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // AI Context: Help button for current step
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showStepHelp(context, _currentStep),
            tooltip: 'Ayuda',
          ),
        ],
      ),
    );
  }

  /// **Method**: Build multi-step creation wizard with smooth transitions
  /// **AI Context**: Creates paginated form interface with validation
  /// **Returns**: Widget containing wizard steps
  Widget _buildEventCreationWizard(BuildContext context, EventManagementController controller) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(), // AI Context: Prevent swipe navigation
      children: [
        // AI Context: Step 1 - Basic event information
        _buildBasicInfoStep(context),
        
        // AI Context: Step 2 - Location and coordinates
        _buildLocationStep(context),
        
        // AI Context: Step 3 - Schedule and timing
        _buildScheduleStep(context),
        
        // AI Context: Step 4 - Advanced settings and policies
        _buildAdvancedSettingsStep(context),
      ],
    );
  }

  /// **Method**: Build basic information form step
  /// **AI Context**: First step collecting title, description, and event type
  /// **Returns**: Widget containing basic info form
  Widget _buildBasicInfoStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _eventFormData['title'] as String?,
                decoration: const InputDecoration(
                  labelText: 'Título del evento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El título es requerido';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _eventFormData['title'] = value;
                    _stepValidationStatus[0] = _validateStep(0);
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _eventFormData['description'] as String?,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _eventFormData['description'] = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EventType>(
                initialValue: _eventFormData['eventType'] as EventType?,
                decoration: const InputDecoration(
                  labelText: 'Tipo de evento',
                  border: OutlineInputBorder(),
                ),
                items: EventType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _eventFormData['eventType'] = value;
                    _stepValidationStatus[0] = _validateStep(0);
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona un tipo de evento';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Method**: Build location selection form step
  /// **AI Context**: Second step with interactive map and location services
  /// **Returns**: Widget containing location picker
  Widget _buildLocationStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: LocationPickerWidget(
        initialLat: (_eventFormData['coordinates'] as EventGeolocationCoordinates?)?.latitude,
        initialLng: (_eventFormData['coordinates'] as EventGeolocationCoordinates?)?.longitude,
        onLocationSelected: (lat, lng) {
          setState(() {
            _eventFormData['locationName'] = 'Selected Location';
            _eventFormData['coordinates'] = EventGeolocationCoordinates(
              latitude: lat,
              longitude: lng,
              geofenceRadiusMeters: 100.0,
            );
            _stepValidationStatus[1] = _validateStep(1);
          });
        },
      ),
    );
  }

  /// **Method**: Build schedule configuration form step
  /// **AI Context**: Third step for date, time, and duration settings
  /// **Returns**: Widget containing schedule form
  Widget _buildScheduleStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha y Hora',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de inicio',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _eventFormData['startDateTime'] != null
                            ? (_eventFormData['startDateTime'] as DateTime)
                                .toString()
                                .split(' ')[0]
                            : 'Seleccionar',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartTime(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora de inicio',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _eventFormData['startDateTime'] != null
                            ? TimeOfDay.fromDateTime(
                                _eventFormData['startDateTime'] as DateTime)
                                .format(context)
                            : 'Seleccionar',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de fin',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _eventFormData['endDateTime'] != null
                            ? (_eventFormData['endDateTime'] as DateTime)
                                .toString()
                                .split(' ')[0]
                            : 'Seleccionar',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndTime(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora de fin',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _eventFormData['endDateTime'] != null
                            ? TimeOfDay.fromDateTime(
                                _eventFormData['endDateTime'] as DateTime)
                                .format(context)
                            : 'Seleccionar',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// **Method**: Build advanced settings form step
  /// **AI Context**: Final step for attendance policies and capacity settings
  /// **Returns**: Widget containing advanced configuration
  Widget _buildAdvancedSettingsStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración Avanzada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _eventFormData['maxParticipants']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Máximo de participantes (opcional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _eventFormData['maxParticipants'] = int.tryParse(value);
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _eventFormData['geofenceRadius']?.toString() ?? '100',
              decoration: const InputDecoration(
                labelText: 'Radio de geofence (metros)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _eventFormData['geofenceRadius'] = double.tryParse(value) ?? 100.0;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Requerir validación de ubicación'),
              subtitle: const Text('Los estudiantes deben estar en el lugar para marcar asistencia'),
              value: _eventFormData['requiresGeolocationValidation'] ?? true,
              onChanged: (value) {
                setState(() {
                  _eventFormData['requiresGeolocationValidation'] = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enviar notificaciones'),
              subtitle: const Text('Notificar a los estudiantes sobre el evento'),
              value: _eventFormData['sendsNotifications'] ?? true,
              onChanged: (value) {
                setState(() {
                  _eventFormData['sendsNotifications'] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// **Method**: Build navigation controls for wizard steps
  /// **AI Context**: Creates context-aware navigation with validation
  /// **Returns**: Widget containing navigation buttons
  Widget _buildNavigationControls(BuildContext context, EventManagementController controller) {
    final theme = Theme.of(context);
    final canProceed = _stepValidationStatus[_currentStep];
    final isLastStep = _currentStep == _totalSteps - 1;
    
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // AI Context: Previous step button (hidden on first step)
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goToPreviousStep(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Anterior'),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          // AI Context: Next/Create button with validation
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: canProceed ? () {
                if (isLastStep) {
                  _handleEventCreation(controller);
                } else {
                  _goToNextStep();
                }
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isLastStep ? 'Crear Evento' : 'Siguiente',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **Method**: Build loading overlay during event creation
  /// **AI Context**: Shows progress and prevents user interaction during creation
  /// **Returns**: Widget containing loading interface
  Widget _buildLoadingOverlay(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Creando evento...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Por favor espera mientras configuramos tu evento',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// **Method**: Navigate to next step with animation
  /// **AI Context**: Smooth progression through wizard steps
  /// **Side Effects**: Updates current step, animates page transition
  void _goToNextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // AI Context: Restart fade animation for new step
      _animationController.reset();
      _animationController.forward();
    }
  }

  /// **Method**: Navigate to previous step with animation
  /// **AI Context**: Allow users to review and modify previous steps
  /// **Side Effects**: Updates current step, animates page transition
  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      _animationController.reset();
      _animationController.forward();
    }
  }

  /// **Method**: Handle event creation submission
  /// **AI Context**: Collect all form data and trigger event creation
  /// **Side Effects**: Creates event via controller, handles success/error states
  Future<void> _handleEventCreation(EventManagementController controller) async {
    if (!_validateAllSteps()) {
      _showValidationErrorDialog(context);
      return;
    }

    try {
      // AI Context: Transform form data into EventCreationData
      final eventCreationData = _transformFormDataToCreationData();
      
      // AI Context: Trigger event creation via controller
      await controller.createNewEvent(eventCreationData: eventCreationData);
      
    } catch (e) {
      // AI Context: Handle unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error preparando datos del evento: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// **Method**: Handle back navigation with confirmation
  /// **AI Context**: Prevent accidental data loss during navigation
  /// **Side Effects**: May show confirmation dialog or navigate back
  void _handleBackNavigation(BuildContext context) {
    if (_hasUnsavedChanges()) {
      _showExitConfirmationDialog(context);
    } else {
      Navigator.of(context).pop();
    }
  }

  /// **Method**: Setup event controller listener for state changes
  /// **AI Context**: Listen for creation success/failure to handle navigation
  /// **Side Effects**: Navigates on success, shows errors on failure
  void _setupEventControllerListener() {
    final controller = context.read<EventManagementController>();
    
    controller.addListener(() {
      if (controller.currentState.hasSuccessMessage) {
        // AI Context: Navigate to event details on successful creation
        Navigator.of(context).pop(controller.selectedEvent);
        
        // AI Context: Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.currentSuccessMessage!),
            backgroundColor: Colors.green,
          ),
        );
      } else if (controller.currentState.hasError) {
        // AI Context: Show error message for failed creation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.currentErrorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () => controller.retryLastOperation(),
            ),
          ),
        );
      }
    });
  }

  // **Helper Methods**: Validation, data transformation, and utility functions

  /// **Method**: Validate specific step
  bool _validateStep(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return _eventFormData['title']?.toString().trim().isNotEmpty == true &&
               _eventFormData['eventType'] != null;
      case 1:
        return _eventFormData['locationName']?.toString().trim().isNotEmpty == true &&
               _eventFormData['coordinates'] != null;
      case 2:
        return _eventFormData['startDateTime'] != null &&
               _eventFormData['endDateTime'] != null;
      case 3:
        return true; // AI Context: Advanced settings are optional
      default:
        return false;
    }
  }

  /// **Method**: Validate all steps
  bool _validateAllSteps() {
    return _stepValidationStatus.every((isValid) => isValid);
  }

  /// **Method**: Check if form has unsaved changes
  bool _hasUnsavedChanges() {
    return _eventFormData.isNotEmpty;
  }

  /// **Method**: Get step title for UI display
  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Información Básica';
      case 1:
        return 'Ubicación';
      case 2:
        return 'Horario';
      case 3:
        return 'Configuración Avanzada';
      default:
        return 'Paso $step';
    }
  }

  /// **Method**: Transform form data to creation data
  EventCreationData _transformFormDataToCreationData() {
    // AI Context: Mock implementation - would extract actual form data
    return EventCreationData.fromFormInput(
      title: _eventFormData['title'] ?? '',
      description: _eventFormData['description'] ?? '',
      location: _eventFormData['locationName'] ?? '',
      latitude: _eventFormData['coordinates']?.latitude ?? 0.0,
      longitude: _eventFormData['coordinates']?.longitude ?? 0.0,
      startDateTime: _eventFormData['startDateTime'] ?? DateTime.now(),
      endDateTime: _eventFormData['endDateTime'] ?? DateTime.now().add(Duration(hours: 1)),
      type: _eventFormData['eventType'] ?? EventType.lecture,
      creator: EventCreatorInfo(
        creatorUserId: 'current_user_id', // AI Context: Would get from auth
        creatorDisplayName: 'Professor Name',
        creatorEmailAddress: 'professor@university.edu',
        creatorRoleType: 'profesor',
      ),
      authToken: 'auth_token', // AI Context: Would get from auth service
      maxParticipants: _eventFormData['maxParticipants'],
      geofenceRadius: _eventFormData['geofenceRadius'] ?? 100.0,
    );
  }

  /// **Method**: Show validation error dialog
  void _showValidationErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información Incompleta'),
        content: const Text('Por favor completa todos los campos requeridos antes de continuar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// **Method**: Show exit confirmation dialog
  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la creación?'),
        content: const Text('Se perderán los datos ingresados. ¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  /// **Method**: Show step-specific help dialog
  void _showStepHelp(BuildContext context, int step) {
    final helpContent = _getStepHelpContent(step);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ayuda - ${_getStepTitle(step)}'),
        content: Text(helpContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// **Method**: Get help content for specific step
  String _getStepHelpContent(int step) {
    switch (step) {
      case 0:
        return 'Ingresa el título y descripción del evento. Selecciona el tipo de evento apropiado.';
      case 1:
        return 'Selecciona la ubicación del evento tocando en el mapa o buscando por nombre.';
      case 2:
        return 'Configura la fecha y hora de inicio y fin del evento.';
      case 3:
        return 'Ajusta las políticas de asistencia y configuraciones avanzadas.';
      default:
        return 'Información de ayuda no disponible.';
    }
  }

  // **Date/Time Selection Methods**: Helper methods for schedule step
  
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventFormData['startDateTime'] as DateTime? ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final currentDateTime = _eventFormData['startDateTime'] as DateTime? ?? DateTime.now();
      final newDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        currentDateTime.hour,
        currentDateTime.minute,
      );
      setState(() {
        _eventFormData['startDateTime'] = newDateTime;
        _stepValidationStatus[2] = _validateStep(2);
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _eventFormData['startDateTime'] != null
          ? TimeOfDay.fromDateTime(_eventFormData['startDateTime'] as DateTime)
          : TimeOfDay.now(),
    );
    if (time != null) {
      final currentDateTime = _eventFormData['startDateTime'] as DateTime? ?? DateTime.now();
      final newDateTime = DateTime(
        currentDateTime.year,
        currentDateTime.month,
        currentDateTime.day,
        time.hour,
        time.minute,
      );
      setState(() {
        _eventFormData['startDateTime'] = newDateTime;
        _stepValidationStatus[2] = _validateStep(2);
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventFormData['endDateTime'] as DateTime? ?? 
                  (_eventFormData['startDateTime'] as DateTime? ?? DateTime.now()).add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final currentDateTime = _eventFormData['endDateTime'] as DateTime? ?? 
                             (_eventFormData['startDateTime'] as DateTime? ?? DateTime.now()).add(const Duration(hours: 1));
      final newDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        currentDateTime.hour,
        currentDateTime.minute,
      );
      setState(() {
        _eventFormData['endDateTime'] = newDateTime;
        _stepValidationStatus[2] = _validateStep(2);
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _eventFormData['endDateTime'] != null
          ? TimeOfDay.fromDateTime(_eventFormData['endDateTime'] as DateTime)
          : (_eventFormData['startDateTime'] != null 
              ? TimeOfDay.fromDateTime((_eventFormData['startDateTime'] as DateTime).add(const Duration(hours: 1)))
              : TimeOfDay.now()),
    );
    if (time != null) {
      final currentDateTime = _eventFormData['endDateTime'] as DateTime? ?? 
                             (_eventFormData['startDateTime'] as DateTime? ?? DateTime.now()).add(const Duration(hours: 1));
      final newDateTime = DateTime(
        currentDateTime.year,
        currentDateTime.month,
        currentDateTime.day,
        time.hour,
        time.minute,
      );
      setState(() {
        _eventFormData['endDateTime'] = newDateTime;
        _stepValidationStatus[2] = _validateStep(2);
      });
    }
  }

  /// **Method**: Build event creation progress widget
  /// **AI Context**: Shows current step progress and validation status
  /// **Returns**: Widget displaying progress indicator
  Widget _buildEventCreationProgressWidget() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep || _stepValidationStatus[index];
          // Unused variable isValid removed
          
          return Expanded(
            child: Row(
              children: [
                // Step indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted 
                        ? theme.colorScheme.primary
                        : isActive
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: isActive
                          ? theme.colorScheme.primary
                          : isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            color: theme.colorScheme.onPrimary,
                            size: 16,
                          )
                        : Text(
                            '${index + 1}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                // Connection line (except for last step)
                if (index < _totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}