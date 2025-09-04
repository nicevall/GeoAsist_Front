// lib/screens/settings/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/notification_settings_model.dart';
import '../../services/notification_settings_service.dart';
import '../../utils/colors.dart';
import '../../utils/app_router.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/custom_button.dart';

/// ⚙️ PANTALLA DE CONFIGURACIÓN DE NOTIFICACIONES
/// Interfaz completa para personalizar todas las notificaciones
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with TickerProviderStateMixin {
  final NotificationSettingsService _settingsService = NotificationSettingsService();

  // Estado
  NotificationSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  // Controladores de animación
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSettings();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 6, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final response = await _settingsService.loadSettings();
      
      if (response.success) {
        setState(() {
          _settings = response.data!;
          _hasChanges = false;
        });
        _fadeController.forward();
      } else {
        _mostrarError(response.error ?? 'Error cargando configuraciones');
      }
    } catch (e) {
      _mostrarError('Error de conexión: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    setState(() => _isSaving = true);

    try {
      final response = await _settingsService.saveSettings(_settings!);
      
      if (response.success) {
        setState(() => _hasChanges = false);
        AppRouter.showSnackBar('✅ Configuraciones guardadas');
      } else {
        _mostrarError(response.error ?? 'Error guardando configuraciones');
      }
    } catch (e) {
      _mostrarError('Error de conexión: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      AppRouter.showSnackBar(mensaje, isError: true);
    }
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasChanges) {
          final navigator = Navigator.of(context);
          final shouldDiscard = await _mostrarDialogoDescarte();
          if (shouldDiscard == true && mounted) {
            navigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        appBar: _buildAppBar(),
        body: _isLoading ? _buildLoadingState() : _buildContent(),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Configuración de Notificaciones',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppColors.primaryOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [
        if (_hasChanges)
          IconButton(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            tooltip: 'Guardar cambios',
          ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'reset',
              child: Row(
                children: [
                  Icon(Icons.restore, size: 20),
                  SizedBox(width: 12),
                  Text('Restablecer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.file_download, size: 20),
                  SizedBox(width: 12),
                  Text('Exportar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.file_upload, size: 20),
                  SizedBox(width: 12),
                  Text('Importar'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: _settings != null ? _buildTabBar() : null,
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
      tabs: const [
        Tab(icon: Icon(Icons.tune), text: 'General'),
        Tab(icon: Icon(Icons.event), text: 'Eventos'),
        Tab(icon: Icon(Icons.location_on), text: 'Asistencia'),
        Tab(icon: Icon(Icons.description), text: 'Justificaciones'),
        Tab(icon: Icon(Icons.school), text: 'Docente'),
        Tab(icon: Icon(Icons.access_time), text: 'Horarios'),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonLoaders.card(height: 120),
          const SizedBox(height: 16),
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SkeletonLoaders.card(height: 80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_settings == null) {
      return const Center(
        child: Text(
          'No se pudieron cargar las configuraciones',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textGray,
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildMasterSwitch(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralTab(),
                _buildEventsTab(),
                _buildAttendanceTab(),
                _buildJustificationsTab(),
                _buildTeacherTab(),
                _buildScheduleTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterSwitch() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _settings!.enabled ? AppColors.secondaryTeal : Colors.grey,
            (_settings!.enabled ? AppColors.secondaryTeal : Colors.grey).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_settings!.enabled ? AppColors.secondaryTeal : Colors.grey).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _settings!.enabled ? Icons.notifications_active : Icons.notifications_off,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _settings!.enabled ? 'Notificaciones Activadas' : 'Notificaciones Desactivadas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _settings!.enabled 
                      ? 'Recibirás notificaciones según tu configuración'
                      : 'No recibirás ninguna notificación',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings!.enabled,
            onChanged: (value) {
              setState(() {
                _settings = _settings!.copyWith(enabled: value);
              });
              _markAsChanged();
            },
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard(
            title: 'Configuración General',
            icon: Icons.tune,
            children: [
              _buildSwitchTile(
                'Sonido',
                'Reproducir sonido con las notificaciones',
                Icons.volume_up,
                _settings!.soundEnabled,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(soundEnabled: value);
                  });
                  _markAsChanged();
                },
              ),
              _buildSwitchTile(
                'Vibración',
                'Vibrar cuando lleguen notificaciones',
                Icons.vibration,
                _settings!.vibrationEnabled,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(vibrationEnabled: value);
                  });
                  _markAsChanged();
                },
              ),
              _buildSwitchTile(
                'LED',
                'Usar LED de notificación (si está disponible)',
                Icons.lightbulb_outline,
                _settings!.ledEnabled,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(ledEnabled: value);
                  });
                  _markAsChanged();
                },
              ),
              _buildSwitchTile(
                'Vista previa',
                'Mostrar contenido en notificaciones',
                Icons.preview,
                _settings!.showPreview,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(showPreview: value);
                  });
                  _markAsChanged();
                },
              ),
              _buildSwitchTile(
                'Agrupar similares',
                'Agrupar notificaciones del mismo tipo',
                Icons.group_work,
                _settings!.groupSimilarNotifications,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(groupSimilarNotifications: value);
                  });
                  _markAsChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            title: 'Límites y Prioridades',
            icon: Icons.priority_high,
            children: [
              _buildSliderTile(
                'Máximo por hora',
                'Máximo número de notificaciones por hora',
                Icons.schedule,
                _settings!.maxNotificationsPerHour.toDouble(),
                1.0,
                50.0,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(maxNotificationsPerHour: value.round());
                  });
                  _markAsChanged();
                },
                valueText: '${_settings!.maxNotificationsPerHour} notificaciones',
              ),
              _buildDropdownTile(
                'Prioridad por defecto',
                'Prioridad predeterminada para notificaciones',
                Icons.flag,
                _settings!.defaultPriority,
                NotificationPriority.values,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(defaultPriority: value);
                  });
                  _markAsChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard(
            title: 'Notificaciones de Eventos',
            icon: Icons.event,
            children: [
              _buildSwitchTile(
                'Habilitar eventos',
                'Recibir notificaciones sobre eventos',
                Icons.event,
                _settings!.eventSettings.enabled,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(
                      eventSettings: _settings!.eventSettings.copyWith(enabled: value),
                    );
                  });
                  _markAsChanged();
                },
              ),
              if (_settings!.eventSettings.enabled) ...[
                _buildSwitchTile(
                  'Recordatorios',
                  'Recordar eventos próximos',
                  Icons.access_time,
                  _settings!.eventSettings.reminderBefore,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        eventSettings: _settings!.eventSettings.copyWith(reminderBefore: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                if (_settings!.eventSettings.reminderBefore)
                  _buildSliderTile(
                    'Minutos antes',
                    'Tiempo de anticipación para recordatorios',
                    Icons.timer,
                    _settings!.eventSettings.reminderMinutes.toDouble(),
                    5.0,
                    120.0,
                    (value) {
                      setState(() {
                        _settings = _settings!.copyWith(
                          eventSettings: _settings!.eventSettings.copyWith(reminderMinutes: value.round()),
                        );
                      });
                      _markAsChanged();
                    },
                    valueText: '${_settings!.eventSettings.reminderMinutes} minutos',
                  ),
                _buildSwitchTile(
                  'Evento iniciando',
                  'Notificar cuando un evento esté iniciando',
                  Icons.play_arrow,
                  _settings!.eventSettings.eventStarting,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        eventSettings: _settings!.eventSettings.copyWith(eventStarting: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Evento terminando',
                  'Notificar cuando un evento esté terminando',
                  Icons.stop,
                  _settings!.eventSettings.eventEnding,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        eventSettings: _settings!.eventSettings.copyWith(eventEnding: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Eventos cancelados',
                  'Notificar cuando se cancele un evento',
                  Icons.cancel,
                  _settings!.eventSettings.eventCanceled,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        eventSettings: _settings!.eventSettings.copyWith(eventCanceled: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Eventos actualizados',
                  'Notificar cambios en eventos',
                  Icons.update,
                  _settings!.eventSettings.eventUpdated,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        eventSettings: _settings!.eventSettings.copyWith(eventUpdated: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard(
            title: 'Notificaciones de Asistencia',
            icon: Icons.location_on,
            children: [
              _buildSwitchTile(
                'Habilitar asistencia',
                'Recibir notificaciones sobre asistencia',
                Icons.location_on,
                _settings!.attendanceSettings.enabled,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(
                      attendanceSettings: _settings!.attendanceSettings.copyWith(enabled: value),
                    );
                  });
                  _markAsChanged();
                },
              ),
              if (_settings!.attendanceSettings.enabled) ...[
                _buildSwitchTile(
                  'Confirmación de entrada',
                  'Confirmar cuando entres al área del evento',
                  Icons.login,
                  _settings!.attendanceSettings.entryConfirmation,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        attendanceSettings: _settings!.attendanceSettings.copyWith(entryConfirmation: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Advertencia de salida',
                  'Advertir cuando salgas del área del evento',
                  Icons.logout,
                  _settings!.attendanceSettings.exitWarning,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        attendanceSettings: _settings!.attendanceSettings.copyWith(exitWarning: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Regreso al área',
                  'Notificar cuando regreses al área',
                  Icons.keyboard_return,
                  _settings!.attendanceSettings.backInArea,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        attendanceSettings: _settings!.attendanceSettings.copyWith(backInArea: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Llegada tardía',
                  'Notificar llegadas tardías',
                  Icons.schedule,
                  _settings!.attendanceSettings.lateArrival,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        attendanceSettings: _settings!.attendanceSettings.copyWith(lateArrival: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Ausencia detectada',
                  'Notificar cuando se detecte una ausencia',
                  Icons.person_off,
                  _settings!.attendanceSettings.absenceDetected,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        attendanceSettings: _settings!.attendanceSettings.copyWith(absenceDetected: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Problemas de GPS',
                  'Notificar problemas con la ubicación',
                  Icons.gps_off,
                  _settings!.attendanceSettings.gpsIssues,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        attendanceSettings: _settings!.attendanceSettings.copyWith(gpsIssues: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJustificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard(
            title: 'Notificaciones de Justificaciones',
            icon: Icons.description,
            children: [
              _buildSwitchTile(
                'Habilitar justificaciones',
                'Recibir notificaciones sobre justificaciones',
                Icons.description,
                _settings!.justificationSettings.enabled,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(
                      justificationSettings: _settings!.justificationSettings.copyWith(enabled: value),
                    );
                  });
                  _markAsChanged();
                },
              ),
              if (_settings!.justificationSettings.enabled) ...[
                _buildSwitchTile(
                  'Cambios de estado',
                  'Notificar cambios en el estado de justificaciones',
                  Icons.update,
                  _settings!.justificationSettings.statusUpdates,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        justificationSettings: _settings!.justificationSettings.copyWith(statusUpdates: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Aprobaciones',
                  'Notificar cuando se apruebe una justificación',
                  Icons.check_circle,
                  _settings!.justificationSettings.approvalNotifications,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        justificationSettings: _settings!.justificationSettings.copyWith(approvalNotifications: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Rechazos',
                  'Notificar cuando se rechace una justificación',
                  Icons.cancel,
                  _settings!.justificationSettings.rejectionNotifications,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        justificationSettings: _settings!.justificationSettings.copyWith(rejectionNotifications: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Recordatorios de envío',
                  'Recordar enviar justificaciones pendientes',
                  Icons.notifications_active,
                  _settings!.justificationSettings.reminderToSubmit,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        justificationSettings: _settings!.justificationSettings.copyWith(reminderToSubmit: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Recordatorios de documentos',
                  'Recordar adjuntar documentos faltantes',
                  Icons.attach_file,
                  _settings!.justificationSettings.documentReminders,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        justificationSettings: _settings!.justificationSettings.copyWith(documentReminders: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard(
            title: 'Notificaciones para Docentes',
            icon: Icons.school,
            children: [
              _buildSwitchTile(
                'Habilitar notificaciones profesor',
                'Recibir notificaciones específicas para profesors',
                Icons.school,
                _settings!.teacherSettings.enabled,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(
                      teacherSettings: _settings!.teacherSettings.copyWith(enabled: value),
                    );
                  });
                  _markAsChanged();
                },
              ),
              if (_settings!.teacherSettings.enabled) ...[
                _buildSwitchTile(
                  'Estudiante se unió',
                  'Notificar cuando un estudiante se una al evento',
                  Icons.person_add,
                  _settings!.teacherSettings.studentJoinedEvent,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        teacherSettings: _settings!.teacherSettings.copyWith(studentJoinedEvent: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Estudiante salió del área',
                  'Notificar cuando un estudiante salga del área',
                  Icons.person_remove,
                  _settings!.teacherSettings.studentLeftArea,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        teacherSettings: _settings!.teacherSettings.copyWith(studentLeftArea: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Llegadas tardías',
                  'Notificar llegadas tardías de estudiantes',
                  Icons.schedule,
                  _settings!.teacherSettings.lateArrivals,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        teacherSettings: _settings!.teacherSettings.copyWith(lateArrivals: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Alertas de ausencia',
                  'Notificar ausencias de estudiantes',
                  Icons.person_off,
                  _settings!.teacherSettings.absenceAlerts,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        teacherSettings: _settings!.teacherSettings.copyWith(absenceAlerts: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Justificaciones recibidas',
                  'Notificar cuando se reciba una justificación',
                  Icons.description,
                  _settings!.teacherSettings.justificationReceived,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        teacherSettings: _settings!.teacherSettings.copyWith(justificationReceived: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Métricas de eventos',
                  'Notificar estadísticas de eventos',
                  Icons.analytics,
                  _settings!.teacherSettings.eventMetrics,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        teacherSettings: _settings!.teacherSettings.copyWith(eventMetrics: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsCard(
            title: 'Horarios Silenciosos',
            icon: Icons.access_time,
            children: [
              _buildSwitchTile(
                'Habilitar horarios silenciosos',
                'Silenciar notificaciones en horarios específicos',
                Icons.access_time,
                _settings!.quietHours.enabled,
                (value) {
                  setState(() {
                    _settings = _settings!.copyWith(
                      quietHours: _settings!.quietHours.copyWith(enabled: value),
                    );
                  });
                  _markAsChanged();
                },
              ),
              if (_settings!.quietHours.enabled) ...[
                _buildTimeTile(
                  'Hora de inicio',
                  'Hora en que inician los horarios silenciosos',
                  Icons.bedtime,
                  _settings!.quietHours.startTime,
                  (time) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        quietHours: _settings!.quietHours.copyWith(startTime: time),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildTimeTile(
                  'Hora de fin',
                  'Hora en que terminan los horarios silenciosos',
                  Icons.wb_sunny,
                  _settings!.quietHours.endTime,
                  (time) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        quietHours: _settings!.quietHours.copyWith(endTime: time),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                _buildSwitchTile(
                  'Permitir urgentes',
                  'Permitir notificaciones urgentes durante horarios silenciosos',
                  Icons.priority_high,
                  _settings!.quietHours.allowUrgentNotifications,
                  (value) {
                    setState(() {
                      _settings = _settings!.copyWith(
                        quietHours: _settings!.quietHours.copyWith(allowUrgentNotifications: value),
                      );
                    });
                    _markAsChanged();
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            title: 'Configuración por Días',
            icon: Icons.calendar_today,
            children: [
              const Text(
                'Puedes configurar diferentes horarios para cada día de la semana',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 16),
              ..._buildWeekdaySettings(),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeekdaySettings() {
    const weekdays = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    
    return List.generate(7, (index) {
      final dayIndex = index + 1;
      final dayName = weekdays[index];
      final isEnabled = _settings!.weekdaySettings.enabledDays[dayIndex] ?? true;
      
      return ExpansionTile(
        leading: Icon(
          isEnabled ? Icons.check_circle : Icons.cancel,
          color: isEnabled ? Colors.green : Colors.red,
        ),
        title: Text(dayName),
        subtitle: Text(
          isEnabled ? 'Notificaciones habilitadas' : 'Notificaciones deshabilitadas',
          style: TextStyle(
            fontSize: 12,
            color: isEnabled ? Colors.green : Colors.red,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Habilitar $dayName'),
                  value: isEnabled,
                  onChanged: (value) {
                    final newEnabledDays = Map<int, bool>.from(_settings!.weekdaySettings.enabledDays);
                    newEnabledDays[dayIndex] = value;
                    
                    setState(() {
                      _settings = _settings!.copyWith(
                        weekdaySettings: _settings!.weekdaySettings.copyWith(enabledDays: newEnabledDays),
                      );
                    });
                    _markAsChanged();
                  },
                ),
                if (isEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.wb_sunny),
                    title: const Text('Hora de inicio'),
                    subtitle: Text(
                      _settings!.weekdaySettings.startTimes[dayIndex]?.format(context) ?? '06:00',
                    ),
                    onTap: () => _selectTime(
                      context,
                      _settings!.weekdaySettings.startTimes[dayIndex] ?? const TimeOfDay(hour: 6, minute: 0),
                      (time) {
                        final newStartTimes = Map<int, TimeOfDay>.from(_settings!.weekdaySettings.startTimes);
                        newStartTimes[dayIndex] = time;
                        
                        setState(() {
                          _settings = _settings!.copyWith(
                            weekdaySettings: _settings!.weekdaySettings.copyWith(startTimes: newStartTimes),
                          );
                        });
                        _markAsChanged();
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bedtime),
                    title: const Text('Hora de fin'),
                    subtitle: Text(
                      _settings!.weekdaySettings.endTimes[dayIndex]?.format(context) ?? '22:00',
                    ),
                    onTap: () => _selectTime(
                      context,
                      _settings!.weekdaySettings.endTimes[dayIndex] ?? const TimeOfDay(hour: 22, minute: 0),
                      (time) {
                        final newEndTimes = Map<int, TimeOfDay>.from(_settings!.weekdaySettings.endTimes);
                        newEndTimes[dayIndex] = time;
                        
                        setState(() {
                          _settings = _settings!.copyWith(
                            weekdaySettings: _settings!.weekdaySettings.copyWith(endTimes: newEndTimes),
                          );
                        });
                        _markAsChanged();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBottomBar() {
    if (!_hasChanges) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _mostrarDialogoDescarte,
                child: const Text(
                  'Descartar Cambios',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _isSaving
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                      ),
                    )
                  : CustomButton(
                      text: 'Guardar Cambios',
                      onPressed: _saveSettings,
                      isPrimary: true,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== WIDGETS AUXILIARES ==========

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryOrange),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.textGray),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textGray,
        ),
      ),
      value: value,
      onChanged: _settings!.enabled ? onChanged : null,
      activeThumbColor: AppColors.primaryOrange,
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String? valueText,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textGray),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: (max - min).round(),
                  activeColor: AppColors.primaryOrange,
                  onChanged: _settings!.enabled ? onChanged : null,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  valueText ?? value.round().toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile<T>(
    String title,
    String subtitle,
    IconData icon,
    T value,
    List<T> items,
    ValueChanged<T?> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textGray),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButton<T>(
            value: value,
            isExpanded: true,
            onChanged: _settings!.enabled ? onChanged : null,
            items: items.map((item) {
              String displayText = '';
              Color? color;
              IconData? itemIcon;
              
              if (item is NotificationPriority) {
                displayText = item.displayName;
                color = item.color;
                itemIcon = item.icon;
              } else {
                displayText = item.toString();
              }
              
              return DropdownMenuItem<T>(
                value: item,
                child: Row(
                  children: [
                    if (itemIcon != null) ...[
                      Icon(itemIcon, color: color, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      displayText,
                      style: TextStyle(
                        color: color ?? AppColors.darkGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile(
    String title,
    String subtitle,
    IconData icon,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textGray),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textGray,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          time.format(context),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryOrange,
          ),
        ),
      ),
      onTap: () => _selectTime(context, time, onChanged),
    );
  }

  // ========== MÉTODOS AUXILIARES ==========

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay initialTime,
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (time != null) {
      onChanged(time);
    }
  }

  Future<bool?> _mostrarDialogoDescarte() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar Cambios'),
        content: const Text(
          'Tienes cambios sin guardar. ¿Estás seguro de que quieres descartarlos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'reset':
        _confirmarRestablecimiento();
        break;
      case 'export':
        _exportarConfiguraciones();
        break;
      case 'import':
        _importarConfiguraciones();
        break;
    }
  }

  void _confirmarRestablecimiento() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer Configuraciones'),
        content: const Text(
          'Esto restablecerá todas las configuraciones a sus valores por defecto. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final result = await _settingsService.resetToDefaults();
              if (result.success) {
                await _loadSettings();
                AppRouter.showSnackBar('✅ Configuraciones restablecidas');
              } else {
                _mostrarError(result.error ?? 'Error restableciendo configuraciones');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
  }

  void _exportarConfiguraciones() async {
    try {
      final result = await _settingsService.exportSettings();
      if (result.success) {
        await Clipboard.setData(ClipboardData(text: result.data!));
        AppRouter.showSnackBar('✅ Configuraciones copiadas al portapapeles');
      } else {
        _mostrarError(result.error ?? 'Error exportando configuraciones');
      }
    } catch (e) {
      _mostrarError('Error exportando configuraciones: $e');
    }
  }

  void _importarConfiguraciones() {
    // Por simplicidad, mostrar un diálogo para pegar las configuraciones
    // En una implementación real, podrías usar file_picker para seleccionar un archivo
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        
        return AlertDialog(
          title: const Text('Importar Configuraciones'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pega las configuraciones exportadas aquí:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Configuraciones en formato JSON...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                if (controller.text.trim().isNotEmpty) {
                  final result = await _settingsService.importSettings(controller.text.trim());
                  if (result.success) {
                    await _loadSettings();
                    AppRouter.showSnackBar('✅ Configuraciones importadas');
                  } else {
                    _mostrarError(result.error ?? 'Error importando configuraciones');
                  }
                }
              },
              child: const Text('Importar'),
            ),
          ],
        );
      },
    );
  }
}