import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class RecentOps extends StatelessWidget {
  const RecentOps({super.key});

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 3,
        intensity: 0.5,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
        color: const Color(0xFFF7FAFC),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize
              .min, // Importante: esto evita que Column tome todo el espacio disponible
          children: [
            Row(
              children: const [
                Icon(Icons.history, color: Color(0xFF4299E1), size: 24),
                SizedBox(width: 8),
                Text(
                  'Operaciones Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Lista con altura limitada, sin Expanded
            SizedBox(
              height: 270, // Altura fija para evitar desbordamiento
              child: Neumorphic(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.6,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                  color: Colors.white,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: 5,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    // Determinar el estado de la operación
                    String estado;
                    Color colorFondo;
                    Color colorTexto;

                    if (index < 2) {
                      estado = 'En progreso';
                      colorFondo = const Color(0xFFEBF4FF);
                      colorTexto = const Color(0xFF2B6CB0);
                    } else if (index == 2) {
                      estado = 'Finalizada';
                      colorFondo = const Color(0xFFE6FFED);
                      colorTexto = const Color(0xFF2F855A);
                    } else {
                      estado = 'Pendiente';
                      colorFondo = const Color(0xFFFEF5E7);
                      colorTexto = const Color(0xFFB7791F);
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 6.0),
                      title: Text(
                        'Operación #${100 + index}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      subtitle: Text(
                        'Área: ${[
                          "Mantenimiento",
                          "Logística",
                          "Producción",
                          "Calidad",
                          "Almacén"
                        ][index]}',
                        style: const TextStyle(
                          color: Color(0xFF718096),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorFondo,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: colorTexto,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      onTap: () {},
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
