// lib/screens/justifications/justification_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/justificacion_model.dart';
import '../../services/justificacion_service.dart';
import '../../utils/colors.dart';
import '../../utils/app_router.dart';
import '../../widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

/// 📋 PANTALLA DE DETALLE DE JUSTIFICACIÓN
/// Vista completa de una justificación específica con acciones
class JustificationDetailScreen extends StatefulWidget {
  final Justificacion justificacion;

  const JustificationDetailScreen({
    super.key,
    required this.justificacion,
  });

  @override
  State<JustificationDetailScreen> createState() => _JustificationDetailScreenState();
}

class _JustificationDetailScreenState extends State<JustificationDetailScreen>
    with TickerProviderStateMixin {
  final JustificacionService _justificacionService = JustificacionService();

  late Justificacion _justificacion;

  // Controladores de animación
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _justificacion = widget.justificacion;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Detalle de Justificación',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: _justificacion.tipo.color,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy_link',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 20),
                  SizedBox(width: 12),
                  Text('Copiar enlace'),
                ],
              ),
            ),
            if (_justificacion.estado == JustificacionEstado.pendiente)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildEventoInfo(),
          const SizedBox(height: 16),
          _buildMotivoCard(),
          const SizedBox(height: 16),
          _buildDocumentoCard(),
          const SizedBox(height: 16),
          _buildEstadoCard(),
          if (_justificacion.comentarioDocente != null) ...[
            const SizedBox(height: 16),
            _buildComentarioDocenteCard(),
          ],
          const SizedBox(height: 16),
          _buildTimelineCard(),
          const SizedBox(height: 100), // Espacio para bottom actions
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _justificacion.tipo.color,
            _justificacion.tipo.color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _justificacion.tipo.color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _justificacion.tipo.icon,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _justificacion.tipo.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _justificacion.estado.icon,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _justificacion.estado.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventoInfo() {
    if (_justificacion.eventTitle == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event,
              color: AppColors.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evento',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _justificacion.eventTitle!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Icon(
                Icons.description,
                color: _justificacion.tipo.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Motivo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _justificacion.motivo,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              const Icon(
                Icons.attach_file,
                color: AppColors.secondaryTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Documento de Soporte',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_justificacion.documentoNombre != null) ...[
            Text(
              _justificacion.documentoNombre!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link,
                  color: AppColors.textGray,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _justificacion.linkDocumento,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _copiarLink(_justificacion.linkDocumento),
                  icon: const Icon(
                    Icons.copy,
                    size: 16,
                    color: AppColors.secondaryTeal,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _abrirDocumento(_justificacion.linkDocumento),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Abrir Documento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Icon(
                _justificacion.estado.icon,
                color: _justificacion.estado.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Estado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _justificacion.estado.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _justificacion.estado.icon,
                  color: _justificacion.estado.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _justificacion.estado.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _justificacion.estado.color,
                        ),
                      ),
                      Text(
                        _getEstadoDescripcion(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _justificacion.estado.color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComentarioDocenteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _justificacion.estado.color.withValues(alpha: 0.3),
          width: 1,
        ),
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
          Row(
            children: [
              const Icon(
                Icons.rate_review,
                color: AppColors.primaryOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Comentario del Docente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _justificacion.comentarioDocente!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkGray,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              const Icon(
                Icons.timeline,
                color: AppColors.textGray,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Cronología',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            'Justificación enviada',
            DateFormat('dd/MM/yyyy HH:mm').format(_justificacion.fechaCreacion),
            Icons.send,
            AppColors.secondaryTeal,
            isFirst: true,
          ),
          if (_justificacion.fechaRevision != null)
            _buildTimelineItem(
              'Revisión realizada',
              DateFormat('dd/MM/yyyy HH:mm').format(_justificacion.fechaRevision!),
              _justificacion.estado.icon,
              _justificacion.estado.color,
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 16,
                color: AppColors.lightGray,
              ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 12,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 16,
                color: AppColors.lightGray,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
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
              child: CustomButton(
                text: 'Abrir Documento',
                onPressed: () => _abrirDocumento(_justificacion.linkDocumento),
                isPrimary: false,
              ),
            ),
            if (_justificacion.estado == JustificacionEstado.pendiente) ...[
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Eliminar',
                  onPressed: _confirmarEliminacion,
                  isPrimary: true,
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getEstadoDescripcion() {
    switch (_justificacion.estado) {
      case JustificacionEstado.pendiente:
        return 'Esperando revisión del profesor';
      case JustificacionEstado.aprobada:
        return 'Justificación aceptada';
      case JustificacionEstado.rechazada:
        return 'Justificación no aceptada';
      case JustificacionEstado.revision:
        return 'En proceso de revisión';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_link':
        _copiarLink(_justificacion.linkDocumento);
        break;
      case 'delete':
        _confirmarEliminacion();
        break;
    }
  }

  void _copiarLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    AppRouter.showSnackBar('📋 Enlace copiado al portapapeles');
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

  void _confirmarEliminacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Justificación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta justificación?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarJustificacion();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarJustificacion() async {
    if (_justificacion.id == null) {
      AppRouter.showSnackBar('No se puede eliminar esta justificación', isError: true);
      return;
    }


    try {
      final response = await _justificacionService.eliminarJustificacion(_justificacion.id!);
      
      if (response.success) {
        AppRouter.showSnackBar('✅ Justificación eliminada exitosamente');
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        AppRouter.showSnackBar(response.error ?? 'Error eliminando justificación', isError: true);
      }
    } catch (e) {
      AppRouter.showSnackBar('Error de conexión: $e', isError: true);
    } finally {
      if (mounted) {
      }
    }
  }
}