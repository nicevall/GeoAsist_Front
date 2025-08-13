// lib/screens/dashboard/widgets/student_activity_list_widget.dart
// 🎯 LISTA DE ACTIVIDAD DE ESTUDIANTES FASE A1.2 - Dashboard del docente
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../models/evento_model.dart';

class StudentActivityListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> studentActivities;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final Evento activeEvent;

  const StudentActivityListWidget({
    super.key,
    required this.studentActivities,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.activeEvent,
  });

  @override
  State<StudentActivityListWidget> createState() =>
      _StudentActivityListWidgetState();
}

class _StudentActivityListWidgetState extends State<StudentActivityListWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 HEADER CON FILTROS
          _buildHeader(),

          // 🎯 FILTROS DE ESTUDIANTES
          _buildFilterTabs(),

          // 🎯 LISTA DE ESTUDIANTES
          Expanded(
            child: _buildStudentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final filteredStudents = _getFilteredStudents();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.people,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actividad de Estudiantes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${filteredStudents.length} de ${widget.studentActivities.length} estudiantes',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Indicador de evento activo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'En vivo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'Todos', 'icon': Icons.group},
      {'key': 'present', 'label': 'Presentes', 'icon': Icons.check_circle},
      {'key': 'absent', 'label': 'Ausentes', 'icon': Icons.cancel},
      {'key': 'outside', 'label': 'Fuera del área', 'icon': Icons.location_off},
      {'key': 'grace', 'label': 'En gracia', 'icon': Icons.access_time},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = widget.selectedFilter == filter['key'];
            final count = _getFilteredStudentsCount(filter['key'] as String);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterTabWidget(
                label: filter['label'] as String,
                icon: filter['icon'] as IconData,
                count: count,
                isSelected: isSelected,
                onTap: () => widget.onFilterChanged(filter['key'] as String),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    final filteredStudents = _getFilteredStudents();

    if (filteredStudents.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStudents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        return StudentActivityCard(
          studentData: student,
          activeEvent: widget.activeEvent,
          onTap: () => _showStudentDetails(student),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = 'No hay estudiantes';
    IconData icon = Icons.people_outline;

    switch (widget.selectedFilter) {
      case 'present':
        message = 'No hay estudiantes presentes aún';
        icon = Icons.check_circle_outline;
        break;
      case 'absent':
        message = 'Todos los estudiantes están presentes';
        icon = Icons.celebration;
        break;
      case 'outside':
        message = 'Todos los estudiantes están en el área';
        icon = Icons.location_on;
        break;
      case 'grace':
        message = 'Ningún estudiante en período de gracia';
        icon = Icons.access_time;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textGray,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 🎯 MÉTODOS DE FILTRADO

  List<Map<String, dynamic>> _getFilteredStudents() {
    return _getFilteredStudentsByKey(widget.selectedFilter);
  }

  List<Map<String, dynamic>> _getFilteredStudentsByKey(String filterKey) {
    switch (filterKey) {
      case 'all':
        return widget.studentActivities;
      case 'present':
        return widget.studentActivities
            .where((s) => s['status'] == 'presente')
            .toList();
      case 'absent':
        return widget.studentActivities
            .where((s) => s['status'] != 'presente')
            .toList();
      case 'outside':
        return widget.studentActivities
            .where((s) => s['isInsideGeofence'] == false)
            .toList();
      case 'grace':
        return widget.studentActivities
            .where((s) => s['status'] == 'grace_period')
            .toList();
      default:
        return widget.studentActivities;
    }
  }

  int _getFilteredStudentsCount(String filterKey) {
    return _getFilteredStudentsByKey(filterKey).length;
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StudentDetailsModal(
        studentData: student,
        activeEvent: widget.activeEvent,
      ),
    );
  }
}

// 🎯 WIDGET DE TAB DE FILTRO
class FilterTabWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterTabWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.1)
              : AppColors.lightGray.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.lightGray,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryOrange : AppColors.textGray,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected ? AppColors.primaryOrange : AppColors.textGray,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primaryOrange : AppColors.textGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 🎯 WIDGET DE TARJETA DE ESTUDIANTE
class StudentActivityCard extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final Evento activeEvent;
  final VoidCallback onTap;

  const StudentActivityCard({
    super.key,
    required this.studentData,
    required this.activeEvent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = studentData['status'] ?? 'unknown';
    final isInsideGeofence = studentData['isInsideGeofence'] ?? false;
    final distance = studentData['distance'] ?? 0.0;
    final timestamp = studentData['timestamp'] as DateTime? ?? DateTime.now();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor(status).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar del estudiante
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getStatusColor(status),
                  width: 2,
                ),
              ),
              child: Icon(
                _getStatusIcon(status, isInsideGeofence),
                color: _getStatusColor(status),
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            // Información del estudiante
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentData['studentName'] ?? 'Estudiante',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusMessage(status, isInsideGeofence),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${distance.toStringAsFixed(0)}m',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Indicador de acción
            Icon(
              Icons.chevron_right,
              color: AppColors.textGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'presente':
        return Colors.green;
      case 'grace_period':
        return Colors.orange;
      case 'ausente':
        return Colors.red;
      case 'outside_geofence':
        return AppColors.primaryOrange;
      default:
        return AppColors.textGray;
    }
  }

  IconData _getStatusIcon(String status, bool isInsideGeofence) {
    switch (status) {
      case 'presente':
        return Icons.check_circle;
      case 'grace_period':
        return Icons.access_time;
      case 'ausente':
        return Icons.cancel;
      default:
        return isInsideGeofence ? Icons.location_on : Icons.location_off;
    }
  }

  String _getStatusMessage(String status, bool isInsideGeofence) {
    switch (status) {
      case 'presente':
        return 'Asistencia registrada';
      case 'grace_period':
        return 'En período de gracia';
      case 'ausente':
        return 'Ausente del evento';
      case 'outside_geofence':
        return 'Fuera del área permitida';
      default:
        return isInsideGeofence ? 'En el área del evento' : 'Fuera del área';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'hace ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours}h';
    } else {
      return 'hace ${difference.inDays}d';
    }
  }
}

// 🎯 MODAL DE DETALLES DEL ESTUDIANTE
class StudentDetailsModal extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final Evento activeEvent;

  const StudentDetailsModal({
    super.key,
    required this.studentData,
    required this.activeEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    studentData['studentName'] ?? 'Estudiante',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Contenido del modal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información básica
                  _buildDetailSection(
                    title: 'Estado Actual',
                    items: [
                      'Estado: ${studentData['status'] ?? 'Desconocido'}',
                      'En área del evento: ${studentData['isInsideGeofence'] == true ? 'Sí' : 'No'}',
                      'Distancia: ${(studentData['distance'] ?? 0.0).toStringAsFixed(1)}m',
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Ubicación
                  _buildDetailSection(
                    title: 'Ubicación',
                    items: [
                      'Latitud: ${studentData['location']?['latitude']?.toStringAsFixed(6) ?? 'N/A'}',
                      'Longitud: ${studentData['location']?['longitude']?.toStringAsFixed(6) ?? 'N/A'}',
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Historial
                  _buildDetailSection(
                    title: 'Última Actividad',
                    items: [
                      'Última actualización: ${_getTimeAgo(studentData['timestamp'] as DateTime? ?? DateTime.now())}',
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
              ),
            )),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'hace ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours}h';
    } else {
      return 'hace ${difference.inDays}d';
    }
  }
}
