import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class Cifras extends StatelessWidget {
  const Cifras({super.key});

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 3,
        intensity: 0.5,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
        color: const Color.fromARGB(255, 234, 241, 245),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.insights, color: Color(0xFF4299E1), size: 24),
                SizedBox(width: 8),
                Text(
                  'Cifras Clave',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Fila con 3 tarjetas neumórficas para cifras
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 100, // Altura fija para todas las tarjetas
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        depth: 4,
                        intensity: 0.8,
                        lightSource: LightSource.topLeft,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12)),
                        color: const Color(0xFFE6F0FF),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Centrar verticalmente
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // Centrar horizontalmente
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.person,
                                    color: Color(0xFF3182CE), size: 13),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Trabajadores',
                                    style: TextStyle(
                                      color: Color(0xFF3182CE),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '32',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 100, // Altura fija para todas las tarjetas
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        depth: 4,
                        intensity: 0.8,
                        lightSource: LightSource.topLeft,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12)),
                        color: const Color(0xFFE6FFED),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Centrar verticalmente
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // Centrar horizontalmente
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.assignment,
                                    color: Color(0xFF2F855A), size: 13),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Operaciones',
                                    style: TextStyle(
                                      color: Color(0xFF2F855A),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '18',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 100, // Altura fija para todas las tarjetas
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        depth: 4,
                        intensity: 0.8,
                        lightSource: LightSource.topLeft,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(12)),
                        color: const Color(0xFFFFFAE6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Centrar verticalmente
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // Centrar horizontalmente
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.pending_actions,
                                    color: Color(0xFFDD6B20), size: 13),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Pendientes',
                                    style: TextStyle(
                                      color: Color(0xFFDD6B20),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '7',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
