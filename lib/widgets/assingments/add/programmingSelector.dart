import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:plannerop/store/programmings.dart';
import 'package:provider/provider.dart';

class ProgrammingSelector extends StatefulWidget {
  final String? startDate;
  final Function(Programming) onProgrammingSelected;
  final Programming? initialValue;

  const ProgrammingSelector({
    Key? key,
    required this.startDate,
    required this.onProgrammingSelected,
    this.initialValue,
  }) : super(key: key);

  @override
  State<ProgrammingSelector> createState() => _ProgrammingSelectorState();
}

class _ProgrammingSelectorState extends State<ProgrammingSelector> {
  List<Programming> _filteredProgrammings = [];
  bool _isLoading = false;
  Programming? _selectedProgramming;

  @override
  void initState() {
    super.initState();
    _selectedProgramming = widget.initialValue;

    if (widget.startDate != null) {
      _loadProgrammings();
    }
  }

  @override
  void didUpdateWidget(ProgrammingSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si la fecha o el cliente cambia, recargamos
    if (widget.startDate != oldWidget.startDate) {
      _loadProgrammings();
    }
  }

  Future<void> _loadProgrammings() async {
    if (widget.startDate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Formatear fecha para la API (DD/MM/YYYY -> YYYY-MM-DD)
      final dateParts = widget.startDate!.split('/');
      if (dateParts.length != 3) {
        setState(() {
          _isLoading = false;
          _filteredProgrammings = [];
        });
        return;
      }

      final formattedDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';

      final programmingsProvider =
          Provider.of<ProgrammingsProvider>(context, listen: false);

      // Obtener programaciones
      await programmingsProvider.fetchProgrammingsByDate(
          formattedDate, context);

      if (mounted) {
        setState(() {
          // Filtrar por cliente y excluir las completadas
          _filteredProgrammings = programmingsProvider.programmings
              .where((p) =>
                  p.status.toUpperCase() != 'COMPLETED') // Excluir completadas
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _filteredProgrammings = [];
        });
      }
      debugPrint('Error cargando programaciones: $e');
    }
  }

  void _openProgrammingSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Esto permite que ocupe toda la pantalla
      backgroundColor: Colors.transparent,
      builder: (context) => _ProgrammingSelectionModal(
        startDate: widget.startDate!,
        programmings: _filteredProgrammings,
        selectedProgramming: _selectedProgramming,
        isLoading: _isLoading,
        onProgrammingSelected: (programming) {
          setState(() {
            _selectedProgramming = programming;
          });
          widget.onProgrammingSelected(programming);
          Navigator.pop(context);
        },
        onRefresh: () {
          _loadProgrammings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con contador
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Row(
            children: [
              const Icon(
                Icons.event_note,
                size: 14,
                color: Color(0xFF4A5568),
              ),
              const SizedBox(width: 4),
              const Text(
                'Programación del Cliente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
              ),
              const SizedBox(width: 8),
              // if (_filteredProgrammings.isNotEmpty && !_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_filteredProgrammings.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              const Spacer(),
              if (_isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                ),
            ],
          ),
        ),

        // Selector
        GestureDetector(
          onTap: _openProgrammingSelector,
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: 2,
              intensity: 0.3,
              color: Colors.white,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icono o indicador
                _buildLeadingIcon(),
                const SizedBox(width: 12),

                // Contenido principal
                Expanded(
                  child: _isLoading
                      ? _buildLoadingContent()
                      : _selectedProgramming != null
                          ? _buildSelectedContent()
                          : _buildEmptyContent(),
                ),

                // Flecha
                // if (widget.enabled)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF718096),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeadingIcon() {
    if (_isLoading) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3182CE)),
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.event_note,
        color: const Color(0xFF3182CE),
        size: 18,
      ),
    );
  }

  Widget _buildLoadingContent() {
    return const Text(
      'Cargando programaciones...',
      style: TextStyle(
        fontSize: 14,
        color: Color(0xFF718096),
      ),
    );
  }

  Widget _buildSelectedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedProgramming!.service,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 12,
              color: Color(0xFF718096),
            ),
            const SizedBox(width: 4),
            Text(
              _selectedProgramming!.timeStart,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF718096),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.location_on_outlined,
              size: 12,
              color: Color(0xFF718096),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _selectedProgramming!.ubication,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    final hasNoProgrammings = _filteredProgrammings.isEmpty && !_isLoading;

    return Text(
      hasNoProgrammings
          ? 'No hay programaciones disponibles'
          : 'Seleccionar programación del cliente',
      style: TextStyle(
        fontSize: 14,
        color: const Color(0xFF718096),
        fontStyle: hasNoProgrammings ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }
}

// Modal a pantalla completa para mostrar las programaciones
class _ProgrammingSelectionModal extends StatefulWidget {
  final String startDate;
  final List<Programming> programmings;
  final Programming? selectedProgramming;
  final bool isLoading;
  final Function(Programming) onProgrammingSelected;
  final VoidCallback onRefresh;

  const _ProgrammingSelectionModal({
    Key? key,
    required this.startDate,
    required this.programmings,
    required this.selectedProgramming,
    required this.isLoading,
    required this.onProgrammingSelected,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _ProgrammingSelectionModalState createState() =>
      _ProgrammingSelectionModalState();
}

class _ProgrammingSelectionModalState
    extends State<_ProgrammingSelectionModal> {
  String _searchQuery = '';
  List<Programming> _filteredList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredList = widget.programmings;
  }

  @override
  void didUpdateWidget(_ProgrammingSelectionModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programmings != widget.programmings) {
      _updateFilteredList();
    }
  }

  void _updateFilteredList() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredList = widget.programmings;
      });
    } else {
      final query = _searchQuery.toLowerCase();
      setState(() {
        _filteredList = widget.programmings.where((programming) {
          return programming.service.toLowerCase().contains(query) ||
              programming.service_request.toLowerCase().contains(query) ||
              programming.ubication.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _updateFilteredList();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9, // 90% de la altura de la pantalla
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra superior con título y acciones
          _buildHeader(),

          // Barra de búsqueda
          _buildSearchBar(),

          // Lista de programaciones
          Expanded(
            child: widget.isLoading
                ? _buildLoadingView()
                : _filteredList.isEmpty
                    ? _buildEmptyView()
                    : _buildProgrammingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Programaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: widget.onRefresh,
                color: const Color(0xFF4A5568),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                color: const Color(0xFF4A5568),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 14,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                widget.startDate,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar programación...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF718096)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF718096)),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Cargando programaciones...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    String message = widget.programmings.isEmpty
        ? 'No hay programaciones disponibles para este cliente y fecha'
        : 'No se encontraron resultados para "$_searchQuery"';

    IconData icon =
        widget.programmings.isEmpty ? Icons.event_busy : Icons.search_off;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Limpiar búsqueda'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgrammingList() {
    final list = List.from(_filteredList);

    // Agrupar por hora de inicio
    final Map<String, List<Programming>> groupedByTime = {};

    for (var programming in list) {
      if (!groupedByTime.containsKey(programming.timeStart)) {
        groupedByTime[programming.timeStart] = [];
      }
      groupedByTime[programming.timeStart]!.add(programming);
    }

    // Ordenar las horas
    final sortedTimes = groupedByTime.keys.toList()
      ..sort((a, b) {
        // Convertir a formato de 24 horas para ordenar correctamente
        final timeA = _convertTo24Hour(a);
        final timeB = _convertTo24Hour(b);
        return timeA.compareTo(timeB);
      });

    return ListView.builder(
      itemCount: sortedTimes.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final time = sortedTimes[index];
        final programmings = groupedByTime[time]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del grupo de hora
            Container(
              margin: const EdgeInsets.only(
                  top: 16, bottom: 8, left: 16, right: 16),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF3182CE),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3182CE),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${programmings.length} programación${programmings.length > 1 ? 'es' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de programaciones en este grupo de hora
            ...programmings
                .map((programming) => _buildProgrammingItem(programming)),

            // Divisor entre grupos
            if (index < sortedTimes.length - 1)
              Divider(
                color: Colors.grey.shade200,
                height: 24,
                thickness: 1,
                indent: 72,
                endIndent: 16,
              ),
          ],
        );
      },
    );
  }

  Widget _buildProgrammingItem(Programming programming) {
    final isSelected =
        widget.selectedProgramming?.id_operation == programming.id_operation;
    final Color serviceColor = _getServiceColor(programming.service);

    return Material(
      color: isSelected ? serviceColor.withOpacity(0.05) : Colors.transparent,
      child: InkWell(
        onTap: () => widget.onProgrammingSelected(programming),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? serviceColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono del servicio
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: serviceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? serviceColor
                        : serviceColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isSelected
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              _getServiceIcon(programming.service),
                              color: serviceColor.withOpacity(0.3),
                              size: 22,
                            ),
                            Icon(
                              Icons.check_circle,
                              color: serviceColor,
                              size: 24,
                            ),
                          ],
                        )
                      : Icon(
                          _getServiceIcon(programming.service),
                          color: serviceColor,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Contenido principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Servicio
                    Text(
                      programming.service,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? serviceColor : const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Descripción
                    Text(
                      programming.service_request,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Detalles adicionales
                    Row(
                      children: [
                        // Estado
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(programming.status)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(programming.status),
                                size: 12,
                                color: _getStatusColor(programming.status),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                programming.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getStatusColor(programming.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Ubicación
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: Color(0xFF718096),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  programming.ubication,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF718096),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Checkbox o indicador de selección
              isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: serviceColor,
                      size: 24,
                    )
                  : const Icon(
                      Icons.radio_button_unchecked,
                      color: Color(0xFFCBD5E0),
                      size: 24,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getServiceColor(String service) {
    final String lowercaseService = service.toLowerCase();

    if (lowercaseService.contains('carga')) return Colors.blue;
    if (lowercaseService.contains('descarga')) return Colors.green;
    if (lowercaseService.contains('trasiego')) return Colors.purple;
    if (lowercaseService.contains('almacen')) return Colors.amber;
    if (lowercaseService.contains('inventario')) return Colors.teal;
    if (lowercaseService.contains('limpieza')) return Colors.cyan;
    if (lowercaseService.contains('mantenimiento')) return Colors.deepOrange;

    return const Color(0xFF3182CE); // Color default azul
  }

  IconData _getServiceIcon(String service) {
    final String lowercaseService = service.toLowerCase();

    if (lowercaseService.contains('carga')) return Icons.local_shipping;
    if (lowercaseService.contains('descarga')) return Icons.archive;
    if (lowercaseService.contains('trasiego')) return Icons.swap_horiz;
    if (lowercaseService.contains('almacen')) return Icons.store;
    if (lowercaseService.contains('inventario')) return Icons.list_alt;
    if (lowercaseService.contains('limpieza')) return Icons.cleaning_services;
    if (lowercaseService.contains('mantenimiento')) return Icons.build;

    return Icons.work;
  }

  Color _getStatusColor(String status) {
    final String uppercaseStatus = status.toUpperCase();

    switch (uppercaseStatus) {
      case 'PENDING':
        return Colors.orange;
      case 'INPROGRESS':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    final String uppercaseStatus = status.toUpperCase();

    switch (uppercaseStatus) {
      case 'PENDING':
        return Icons.schedule;
      case 'INPROGRESS':
        return Icons.play_circle_outline;
      case 'COMPLETED':
        return Icons.check_circle_outline;
      case 'CANCELED':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // Función para convertir hora a formato 24 horas para ordenación correcta
  String _convertTo24Hour(String time) {
    // Asumiendo formato como "8:00 AM" o "2:30 PM"
    final parts = time.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    if (parts.length > 1 && parts[1] == 'PM' && hour < 12) {
      hour += 12;
    } else if (parts.length > 1 && parts[1] == 'AM' && hour == 12) {
      hour = 0;
    }

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
