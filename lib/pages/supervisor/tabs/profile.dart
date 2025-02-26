import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'dart:math' as math; // Para generar colores aleatorios

class PerfilTab extends StatefulWidget {
  const PerfilTab({super.key});

  @override
  State<PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<PerfilTab> {
  // Datos del usuario - en una app real vendrían de un servicio o base de datos
  final Map<String, String> _userData = {
    'nombre': 'Carlos Méndez',
    'cargo': 'Supervisor de Operaciones',
    'email': 'carlos.mendez@ejemplo.com',
    'telefono': '+52 55 1234 5678',
  };

  // Estado para controlar si estamos en modo edición
  bool _isEditing = false;

  // Controladores para los campos de texto
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;

  // Color aleatorio para el avatar (generado una vez al iniciar)
  late Color _avatarColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: _userData['nombre']);
    _emailController = TextEditingController(text: _userData['email']);
    _telefonoController = TextEditingController(text: _userData['telefono']);

    // Generar un color aleatorio agradable para el avatar
    _avatarColor = _generateRandomColor();
  }

  // Método para generar un color aleatorio agradable (no demasiado claro ni oscuro)
  Color _generateRandomColor() {
    final random = math.Random();

    // Generar componentes RGB entre 50 y 200 para evitar colores demasiado claros u oscuros
    final r = 50 + random.nextInt(150);
    final g = 50 + random.nextInt(150);
    final b = 50 + random.nextInt(150);

    return Color.fromRGBO(r, g, b, 1.0);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  // Método para guardar cambios
  void _saveChanges() {
    setState(() {
      _userData['nombre'] = _nombreController.text;
      _userData['email'] = _emailController.text;
      _userData['telefono'] = _telefonoController.text;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios guardados correctamente'),
        backgroundColor: Color(0xFF38A169),
      ),
    );
  }

  // Método para cancelar edición
  void _cancelEdit() {
    setState(() {
      _nombreController.text = _userData['nombre']!;
      _emailController.text = _userData['email']!;
      _telefonoController.text = _userData['telefono']!;
      _isEditing = false;
    });
  }

  // Método para mostrar diálogo de cerrar sesión
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFE53E3E)),
            SizedBox(width: 8),
            Text('Cerrar sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF718096)),
            ),
          ),
          NeumorphicButton(
            style: NeumorphicStyle(
              color: const Color(0xFFE53E3E),
              depth: 1,
              intensity: 0.8,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
            ),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              // Aquí irías a la pantalla de login o inicializarías la app
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login', // Reemplaza con tu ruta de login
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE0E5EC),
        centerTitle: true,
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Botón para alternar entre modo visualización y edición
          IconButton(
            icon: Icon(
              _isEditing ? Icons.cancel : Icons.edit,
              color: const Color(0xFF3182CE),
            ),
            onPressed: () {
              if (_isEditing) {
                _cancelEdit();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
          // Botón para guardar cambios (solo visible en modo edición)
          if (_isEditing)
            IconButton(
              icon: const Icon(
                Icons.check,
                color: Color(0xFF38A169),
              ),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto de perfil
              const SizedBox(height: 20),
              _buildProfileImage(),
              const SizedBox(height: 24),

              // Información del usuario
              Neumorphic(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.8,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                  color: const Color(0xFFEDF2F7),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cargo - no editable
                      _buildInfoRow(
                        label: 'Cargo',
                        value: _userData['cargo']!,
                        isEditable: false,
                      ),
                      const SizedBox(height: 16),

                      // Nombre - editable
                      _buildInfoRow(
                        label: 'Nombre',
                        value: _userData['nombre']!,
                        isEditable: _isEditing,
                        controller: _nombreController,
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),

                      // Email - editable
                      _buildInfoRow(
                        label: 'Email',
                        value: _userData['email']!,
                        isEditable: _isEditing,
                        controller: _emailController,
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Teléfono - editable
                      _buildInfoRow(
                        label: 'Teléfono',
                        value: _userData['telefono']!,
                        isEditable: _isEditing,
                        controller: _telefonoController,
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Botón de cerrar sesión mejorado
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 4,
                  intensity: 0.8,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                  color: const Color(0xFFE53E3E),
                  shadowDarkColor: Colors.red.shade700.withOpacity(0.5),
                ),
                onPressed: _showLogoutDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para la foto de perfil con la primera letra del nombre
  Widget _buildProfileImage() {
    // Obtener la primera letra del nombre
    String firstLetter = (_userData['nombre']?.isNotEmpty == true)
        ? _userData['nombre']!.substring(0, 1).toUpperCase()
        : 'U'; // "U" para "Usuario" si no hay nombre

    return Stack(
      alignment: Alignment.center,
      children: [
        // Avatar con iniciales
        Neumorphic(
          style: NeumorphicStyle(
            depth: 4,
            boxShape: const NeumorphicBoxShape.circle(),
          ),
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _avatarColor,
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  fontSize: 55,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        // Botón para cambiar foto
        Positioned(
          bottom: 0,
          right: 0,
          child: NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              boxShape: const NeumorphicBoxShape.circle(),
              color: const Color(0xFF3182CE),
            ),
            onPressed: () {
              // Cambiar el color del avatar cuando se presiona el botón
              setState(() {
                _avatarColor = _generateRandomColor();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Color de avatar actualizado'),
                  backgroundColor: Color(0xFF3182CE),
                ),
              );
            },
            child: const Icon(
              Icons.color_lens,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // Widget para cada fila de información
  Widget _buildInfoRow({
    required String label,
    required String value,
    required bool isEditable,
    TextEditingController? controller,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        isEditable
            ? Neumorphic(
                style: NeumorphicStyle(
                  depth: -2,
                  intensity: 0.6,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      icon: icon != null
                          ? Icon(icon, color: const Color(0xFF3182CE))
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              )
            : Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: const Color(0xFF3182CE)),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2D3748),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ],
    );
  }
}
