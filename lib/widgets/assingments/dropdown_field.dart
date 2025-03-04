import 'package:flutter/material.dart';

class DropdownField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final List<String> options;
  final Function(String)? onSelected;
  final bool enabled;

  const DropdownField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.options,
    this.onSelected,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<DropdownField> {
  // Estado local para manejar el texto visible
  late String _displayText;

  @override
  void initState() {
    super.initState();
    _displayText = widget.controller.text;
    // Añadir listener al controller para mantener el texto sincronizado
    widget.controller.addListener(_updateDisplayText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateDisplayText);
    super.dispose();
  }

  void _updateDisplayText() {
    if (mounted) {
      setState(() {
        _displayText = widget.controller.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Asegurarse de que tengamos el valor más actualizado
    _displayText = widget.controller.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: widget.enabled
                ? () {
                    _showDropdownDialog(context);
                  }
                : () {
                    // Si no está habilitado, mostrar un mensaje
                    if (widget.label == 'Tarea') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Primero debes seleccionar un área'),
                          backgroundColor: Color(0xFFE53E3E),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.enabled
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFE2E8F0).withOpacity(0.7),
                ),
                borderRadius: BorderRadius.circular(8),
                color: widget.enabled ? Colors.white : const Color(0xFFF7FAFC),
              ),
              child: Row(
                children: [
                  Icon(widget.icon,
                      size: 20,
                      color: widget.enabled
                          ? const Color(0xFF718096)
                          : const Color(0xFF718096).withOpacity(0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _displayText.isEmpty ? widget.hint : _displayText,
                      style: TextStyle(
                        color: _displayText.isEmpty
                            ? (widget.enabled
                                ? const Color(0xFFA0AEC0)
                                : const Color(0xFFA0AEC0).withOpacity(0.7))
                            : (widget.enabled ? Colors.black : Colors.black87),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down,
                      color: widget.enabled
                          ? const Color(0xFF718096)
                          : const Color(0xFF718096).withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDropdownDialog(BuildContext context) {
    // Comprobar si hay opciones disponibles
    if (widget.options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay opciones disponibles para seleccionar'),
          backgroundColor: Color(0xFFE53E3E),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    debugPrint('Mostrando dropdown con ${widget.options.length} opciones');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(widget.hint),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.options.map((option) {
                return ListTile(
                  title: Text(option),
                  onTap: () {
                    // Actualizar el controlador con la opción seleccionada
                    widget.controller.text = option;
                    // También actualizar el estado local
                    setState(() {
                      _displayText = option;
                    });

                    debugPrint('Seleccionada opción: $option');
                    Navigator.of(context).pop();

                    // Si hay una función de callback, la llamamos
                    if (widget.onSelected != null) {
                      widget.onSelected!(option);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
