// lib/screens/justifications/create_justification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/justificacion_model.dart';
import '../../models/evento_model.dart';
import '../../services/justificacion_service.dart';
import '../../services/evento_service.dart';
import '../../utils/colors.dart';
import '../../utils/app_router.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_skeleton.dart';

/// 📝 PANTALLA PARA CREAR NUEVA JUSTIFICACIÓN
/// Interfaz completa para enviar justificaciones con documentos externos
class CreateJustificationScreen extends StatefulWidget {
  final String? eventoId;

  const CreateJustificationScreen({
    super.key,
    this.eventoId,
  });

  @override
  State<CreateJustificationScreen> createState() => _CreateJustificationScreenState();
}

class _CreateJustificationScreenState extends State<CreateJustificationScreen>
    with TickerProviderStateMixin {
  final JustificacionService _justificacionService = JustificacionService();
  final EventoService _eventoService = EventoService();

  // Controladores de formulario
  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _documentoNombreController = TextEditingController();

  // Estado
  List<Evento> _eventosDisponibles = [];
  String? _eventoSeleccionado;
  JustificacionTipo _tipoSeleccionado = JustificacionTipo.personal;
  bool _isLoading = false;
  bool _isLoadingEventos = true;

  // Controladores de animación
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _cargarEventos();
    
    // Si se pasa un eventoId específico, seleccionarlo
    if (widget.eventoId != null) {
      _eventoSeleccionado = widget.eventoId;
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _linkController.dispose();
    _documentoNombreController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _cargarEventos() async {
    setState(() => _isLoadingEventos = true);

    try {
      final response = await _eventoService.obtenerEventosPublicos();
      
      setState(() {
        _eventosDisponibles = response;
        // Si hay un evento preseleccionado, verificar que exista
        if (widget.eventoId != null) {
          final eventoExiste = _eventosDisponibles.any((e) => e.id == widget.eventoId);
          if (!eventoExiste) {
            _eventoSeleccionado = null;
          }
        }
      });
    } catch (e) {
      _mostrarError('Error de conexión: $e');
    } finally {
      setState(() => _isLoadingEventos = false);
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      AppRouter.showSnackBar(mensaje, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Nueva Justificación',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppColors.primaryOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 20),
          _buildFormulario(),
          const SizedBox(height: 20),
          _buildTipoSelector(),
          const SizedBox(height: 20),
          _buildDocumentosSugeridos(),
          const SizedBox(height: 100), // Espacio para el bottom bar
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
            AppColors.secondaryTeal,
            AppColors.secondaryTeal.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryTeal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.description,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Crear Justificación',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Completa la información para enviar tu justificación con documento de soporte',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de la Justificación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 20),

          // Selector de evento
          _buildEventoSelector(),
          const SizedBox(height: 16),

          // Campo de motivo
          const Text(
            'Motivo de la justificación *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _motivoController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Describe detalladamente el motivo de tu ausencia...',
              hintStyle: TextStyle(color: AppColors.textGray.withOpacity(0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondaryTeal, width: 2),
              ),
              filled: true,
              fillColor: AppColors.lightGray.withOpacity(0.3),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Campo de link del documento
          const Text(
            'Link del documento de soporte *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _linkController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://ejemplo.com/documento.pdf',
              hintStyle: TextStyle(color: AppColors.textGray.withOpacity(0.7)),
              prefixIcon: const Icon(Icons.link, color: AppColors.secondaryTeal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondaryTeal, width: 2),
              ),
              filled: true,
              fillColor: AppColors.lightGray.withOpacity(0.3),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),

          // Campo de nombre del documento (opcional)
          const Text(
            'Nombre del documento (opcional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _documentoNombreController,
            decoration: InputDecoration(
              hintText: 'Ej: Certificado médico Dr. López',
              hintStyle: TextStyle(color: AppColors.textGray.withOpacity(0.7)),
              prefixIcon: const Icon(Icons.description, color: AppColors.secondaryTeal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondaryTeal, width: 2),
              ),
              filled: true,
              fillColor: AppColors.lightGray.withOpacity(0.3),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evento *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingEventos)
          SkeletonLoaders.card(height: 56)
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lightGray),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.lightGray.withOpacity(0.3),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _eventoSeleccionado,
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Selecciona el evento para justificar',
                    style: TextStyle(color: AppColors.textGray),
                  ),
                ),
                isExpanded: true,
                items: _eventosDisponibles.map((evento) {
                  return DropdownMenuItem<String>(
                    value: evento.id,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            evento.titulo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${evento.fechaInicioFormatted} • ${evento.horaInicioFormatted}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _eventoSeleccionado = value;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTipoSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Justificación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: JustificacionTipo.values.map((tipo) {
              final isSelected = _tipoSeleccionado == tipo;
              return GestureDetector(
                onTap: () => setState(() => _tipoSeleccionado = tipo),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? tipo.color.withOpacity(0.2)
                        : AppColors.lightGray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? tipo.color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tipo.icon,
                        color: isSelected ? tipo.color : AppColors.textGray,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tipo.displayName,
                        style: TextStyle(
                          color: isSelected ? tipo.color : AppColors.textGray,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentosSugeridos() {
    final sugerencias = _tipoSeleccionado.documentosSugeridos;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                Icons.lightbulb_outline,
                color: _tipoSeleccionado.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Documentos Sugeridos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _tipoSeleccionado.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Para justificaciones de tipo "${_tipoSeleccionado.displayName}", se sugieren estos documentos:',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 12),
          ...sugerencias.map((sugerencia) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _tipoSeleccionado.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sugerencia,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGray,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                      ),
                    )
                  : CustomButton(
                      text: 'Enviar Justificación',
                      onPressed: _validarYEnviar,
                      isPrimary: true,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validarYEnviar() async {
    // Validaciones
    if (_eventoSeleccionado == null) {
      _mostrarError('Debes seleccionar un evento');
      return;
    }

    if (_motivoController.text.trim().isEmpty) {
      _mostrarError('El motivo es obligatorio');
      return;
    }

    if (_motivoController.text.trim().length < 10) {
      _mostrarError('El motivo debe tener al menos 10 caracteres');
      return;
    }

    if (_linkController.text.trim().isEmpty) {
      _mostrarError('El link del documento es obligatorio');
      return;
    }

    // Validar URL
    try {
      final uri = Uri.parse(_linkController.text.trim());
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        _mostrarError('El link debe ser una URL válida (http/https)');
        return;
      }
    } catch (e) {
      _mostrarError('El formato del link no es válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _justificacionService.crearJustificacion(
        eventoId: _eventoSeleccionado!,
        motivo: _motivoController.text.trim(),
        linkDocumento: _linkController.text.trim(),
        tipo: _tipoSeleccionado,
        documentoNombre: _documentoNombreController.text.trim().isNotEmpty
            ? _documentoNombreController.text.trim()
            : null,
      );

      if (response.success) {
        AppRouter.showSnackBar('✅ Justificación enviada exitosamente');
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _mostrarError(response.error ?? 'Error enviando justificación');
      }
    } catch (e) {
      _mostrarError('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}