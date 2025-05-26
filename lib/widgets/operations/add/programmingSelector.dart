import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:plannerop/core/model/programming.dart';
import 'package:plannerop/store/programmings.dart';
import 'package:plannerop/utils/operations.dart';
import 'package:plannerop/widgets/operations/components/workers/selectorModal.dart';
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
  }

  @override
  void didUpdateWidget(ProgrammingSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _openProgrammingSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Esto permite que ocupe toda la pantalla
      backgroundColor: Colors.transparent,
      builder: (context) => ProgrammingSelectionModal(
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
          // _loadProgrammings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programmingProvider = Provider.of<ProgrammingsProvider>(context);
    _filteredProgrammings = programmingProvider.programmings;
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
