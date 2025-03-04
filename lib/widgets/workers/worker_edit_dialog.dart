import 'package:flutter/material.dart';
import 'package:plannerop/core/model/worker.dart';

// Import necesario para el método min
import 'dart:math' as Math;

class WorkerEditDialog extends StatefulWidget {
  final Worker worker;
  final Color specialtyColor;
  final Function(Worker, Worker) onUpdateWorker;

  const WorkerEditDialog({
    Key? key,
    required this.worker,
    required this.specialtyColor,
    required this.onUpdateWorker,
  }) : super(key: key);

  @override
  State<WorkerEditDialog> createState() => _WorkerEditDialogState();
}

class _WorkerEditDialogState extends State<WorkerEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _documentController;
  late TextEditingController _phoneController;
  late TextEditingController _areaController;
  late TextEditingController _codeController;
  bool _isLoading = false;

  // Lista de áreas disponibles
  final List<String> _areas = [
    'CAFE',
    'CARGA GENERAL',
    'CARGA PELIGROSA',
    'CARGA REFRIGERADA',
    'ADMINISTRATIVA',
    'OPERADORES MC',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worker.name);
    _documentController = TextEditingController(text: widget.worker.document);
    _phoneController = TextEditingController(text: widget.worker.phone);
    _areaController = TextEditingController(text: widget.worker.area);
    _codeController = TextEditingController(text: widget.worker.code);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Crear un nuevo trabajador con los datos modificados
        final updatedWorker = Worker(
          name: _nameController.text,
          area: _areaController.text,
          phone: _phoneController.text,
          document: _documentController.text,
          status: widget.worker.status,
          startDate: widget.worker.startDate,
          endDate: widget.worker.endDate,
          code: _codeController.text,
        );

        // Llamar a la función para actualizar el trabajador
        widget.onUpdateWorker(widget.worker, updatedWorker);

        // Cerrar el diálogo con éxito
        Navigator.of(context).pop();
      } catch (e) {
        // Mostrar error en caso de fallo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el trabajador: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Editar Trabajador',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF718096)),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Campo de código de trabajador
                _buildTextField(
                  label: 'Código',
                  controller: _codeController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un código';
                    }
                    return null;
                  },
                  maxLength: 10,
                  prefix: const Icon(Icons.code, size: 18),
                ),
                const SizedBox(height: 16),

                // Campo de nombre
                _buildTextField(
                  label: 'Nombre completo',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                  prefix: const Icon(Icons.person, size: 18),
                ),
                const SizedBox(height: 16),

                // Campo de documento
                _buildTextField(
                  label: 'Documento',
                  controller: _documentController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un número de documento';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  prefix: const Icon(Icons.assignment_ind, size: 18),
                ),
                const SizedBox(height: 16),

                // Campo de teléfono
                _buildTextField(
                  label: 'Teléfono',
                  controller: _phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un teléfono';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.phone,
                  prefix: const Icon(Icons.phone, size: 18),
                ),
                const SizedBox(height: 16),

                // Selector de área
                _buildAreaDropdown(),
                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.specialtyColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Guardar Cambios',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            prefixIcon: prefix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.specialtyColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Área',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonFormField<String>(
            // Aseguramos que el valor sea nulo o exista en la lista
            value: _areas.contains(_areaController.text)
                ? _areaController.text
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.business, size: 18),
            ),
            hint: const Text('Seleccionar área'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor selecciona un área';
              }
              return null;
            },
            items: _areas.map((String area) {
              return DropdownMenuItem<String>(
                value: area,
                child: Text(area),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _areaController.text = newValue;
                });
              }
            },
          ),
        ),
      ],
    );
  }
}
