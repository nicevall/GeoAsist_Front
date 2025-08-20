// lib/screens/justifications/justifications_screen.dart
import 'package:flutter/material.dart';
import '../../models/justificacion_model.dart';
import '../../services/justificacion_service.dart';
import '../../utils/colors.dart';
import '../../utils/app_router.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/custom_button.dart';
import 'create_justification_screen.dart';
import 'justification_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// 📄 PANTALLA PRINCIPAL DE JUSTIFICACIONES
/// Vista completa para gestionar justificaciones de estudiantes
class JustificationsScreen extends StatefulWidget {
  const JustificationsScreen({super.key});

  @override
  State<JustificationsScreen> createState() => _JustificationsScreenState();
}

class _JustificationsScreenState extends State<JustificationsScreen>
    with TickerProviderStateMixin {
  final JustificacionService _justificacionService = JustificacionService();

  // Estado
  List<Justificacion> _justificaciones = [];
  JustificacionStats? _stats;
  bool _isLoading = true;

  // Filtros
  JustificacionEstado? _filtroEstado;
  JustificacionTipo? _filtroTipo;

  // Controladores de animación
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _cargarDatos();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 4, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      // Cargar justificaciones
      final response = await _justificacionService.obtenerMisJustificaciones();
      
      if (response.success) {
        _justificaciones = response.data!;
        _stats = JustificacionStats.fromList(_justificaciones);
        _fadeController.forward();
      } else {
        _mostrarError(response.error ?? 'Error cargando justificaciones');
      }
    } catch (e) {
      _mostrarError('Error de conexión: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      AppRouter.showSnackBar(mensaje, isError: true);
    }
  }

  List<Justificacion> get _justificacionesFiltradas {
    var filtradas = _justificaciones;

    if (_filtroEstado != null) {
      filtradas = filtradas.where((j) => j.estado == _filtroEstado).toList();
    }

    if (_filtroTipo != null) {
      filtradas = filtradas.where((j) => j.tipo == _filtroTipo).toList();
    }

    return filtradas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mis Justificaciones',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppColors.primaryOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _mostrarFiltros,
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtrar',
        ),
        IconButton(
          onPressed: _cargarDatos,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
      ],
      bottom: _stats != null ? _buildStatsBar() : null,
    );
  }

  PreferredSizeWidget _buildStatsBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        color: AppColors.primaryOrange,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatItem('Total', _stats!.total.toString(), Icons.description),
            _buildStatItem('Pendientes', _stats!.pendientes.toString(), Icons.schedule),
            _buildStatItem('Aprobadas', _stats!.aprobadas.toString(), Icons.check_circle),
            _buildStatItem('Rechazadas', _stats!.rechazadas.toString(), Icons.cancel),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
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
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SkeletonLoaders.card(height: 140),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          if (_stats != null) _buildSummaryCard(),
          Expanded(child: _buildJustificationsList()),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryTeal,
            AppColors.secondaryTeal.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryTeal.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Resumen de Justificaciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Tasa de Aprobación',
                  '${_stats!.porcentajeAprobacion.toStringAsFixed(1)}%',
                  Icons.thumb_up,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Pendientes',
                  '${_stats!.porcentajePendientes.toStringAsFixed(1)}%',
                  Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildJustificationsList() {
    final justificacionesFiltradas = _justificacionesFiltradas;

    if (justificacionesFiltradas.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: justificacionesFiltradas.length,
        itemBuilder: (context, index) {
          final justificacion = justificacionesFiltradas[index];
          return _buildJustificationCard(justificacion, index);
        },
      ),
    );
  }

  Widget _buildJustificationCard(Justificacion justificacion, int index) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _verDetalleJustificacion(justificacion),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con tipo y estado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: justificacion.tipo.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            justificacion.tipo.icon,
                            color: justificacion.tipo.color,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            justificacion.tipo.displayName,
                            style: TextStyle(
                              color: justificacion.tipo.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: justificacion.estado.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            justificacion.estado.icon,
                            color: justificacion.estado.color,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            justificacion.estado.displayName,
                            style: TextStyle(
                              color: justificacion.estado.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Título del evento
                if (justificacion.eventTitle != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.event,
                        color: AppColors.textGray,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          justificacion.eventTitle!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Motivo (preview)
                Text(
                  justificacion.motivo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Footer con fecha y acciones
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      justificacion.tiempoTranscurrido,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                    const Spacer(),
                    if (justificacion.linkDocumento.isNotEmpty) ...[
                      IconButton(
                        onPressed: () => _abrirDocumento(justificacion.linkDocumento),
                        icon: const Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: AppColors.primaryOrange,
                        ),
                        tooltip: 'Ver documento',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                    IconButton(
                      onPressed: () => _verDetalleJustificacion(justificacion),
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textGray,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                Icons.description,
                size: 60,
                color: AppColors.secondaryTeal,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay justificaciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aún no has enviado ninguna justificación.\nPuedes crear una nueva tocando el botón +',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Crear Justificación',
              onPressed: _crearNuevaJustificacion,
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _crearNuevaJustificacion,
      backgroundColor: AppColors.primaryOrange,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Nueva'),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFiltrosBottomSheet(),
    );
  }

  Widget _buildFiltrosBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar Justificaciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 20),
          
          // Filtro por estado
          const Text(
            'Estado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                'Todos',
                _filtroEstado == null,
                () => setState(() => _filtroEstado = null),
              ),
              ...JustificacionEstado.values.map(
                (estado) => _buildFilterChip(
                  estado.displayName,
                  _filtroEstado == estado,
                  () => setState(() => _filtroEstado = estado),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Filtro por tipo
          const Text(
            'Tipo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                'Todos',
                _filtroTipo == null,
                () => setState(() => _filtroTipo = null),
              ),
              ...JustificacionTipo.values.map(
                (tipo) => _buildFilterChip(
                  tipo.displayName,
                  _filtroTipo == tipo,
                  () => setState(() => _filtroTipo = tipo),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _filtroEstado = null;
                      _filtroTipo = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar Filtros'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryOrange.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primaryOrange,
    );
  }

  void _crearNuevaJustificacion() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateJustificationScreen(),
      ),
    ).then((_) => _cargarDatos());
  }

  void _verDetalleJustificacion(Justificacion justificacion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JustificationDetailScreen(
          justificacion: justificacion,
        ),
      ),
    ).then((_) => _cargarDatos());
  }

  void _abrirDocumento(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppRouter.showSnackBar('No se puede abrir el documento', isError: true);
      }
    } catch (e) {
      AppRouter.showSnackBar('Error abriendo documento: $e', isError: true);
    }
  }
}