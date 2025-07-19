// lib/screens/professor_management_screen.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/app_router.dart';
import '../widgets/custom_button.dart';

class ProfessorManagementScreen extends StatefulWidget {
  const ProfessorManagementScreen({super.key});

  @override
  State<ProfessorManagementScreen> createState() =>
      _ProfessorManagementScreenState();
}

class _ProfessorManagementScreenState extends State<ProfessorManagementScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _professors =
      []; // Temporal hasta implementar backend

  @override
  void initState() {
    super.initState();
    _loadProfessors();
  }

  Future<void> _loadProfessors() async {
    setState(() => _isLoading = true);

    // TODO: Implementar llamada al backend para obtener docentes
    await Future.delayed(const Duration(seconds: 1)); // Simular carga

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Gestionar Docentes'),
        backgroundColor: AppColors.secondaryTeal,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => AppRouter.goToCreateProfessor(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.secondaryTeal,
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_professors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 60,
                color: AppColors.secondaryTeal,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay Docentes registrados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comienza agregando el primer docente al sistema',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Registrar Primer Docente',
              onPressed: () => AppRouter.goToCreateProfessor(),
              isPrimary: false, // Usar color teal
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfessors,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lista de Docentes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_professors.length} docentes',
                  style: const TextStyle(
                    color: AppColors.secondaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Lista de docentes (aquí irían las tarjetas de docentes cuando implementes el backend)
          ..._professors.map((professor) => _buildProfessorCard(professor)),

          // Botón flotante para agregar docente
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfessorCard(Map<String, dynamic> professor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondaryTeal,
              radius: 25,
              child: Text(
                professor['nombre']?[0]?.toUpperCase() ?? 'D',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    professor['nombre'] ?? 'Nombre no disponible',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    professor['correo'] ?? 'Correo no disponible',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, professor),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Map<String, dynamic> professor) {
    switch (action) {
      case 'edit':
        // TODO: Implementar edición de docente
        AppRouter.showSnackBar('Función de editar próximamente');
        break;
      case 'delete':
        _showDeleteConfirmation(professor);
        break;
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> professor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Docente'),
        content: Text(
          '¿Estás seguro de que quieres eliminar al docente ${professor['nombre']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProfessor(professor);
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProfessor(Map<String, dynamic> professor) async {
    // TODO: Implementar eliminación en backend
    AppRouter.showSnackBar('Docente eliminado (simulado)');
  }
}
