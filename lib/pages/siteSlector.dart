import 'package:flutter/material.dart';
import 'package:plannerop/core/model/site.dart';
import 'package:plannerop/store/user.dart';
import 'package:provider/provider.dart';

class SiteSelector {
  /// Función principal para manejar la selección de sede
  static Future<void> handleSiteSelection(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Solo mostrar para superadmin
    if (userProvider.user.role != "SUPERADMIN") return;

    // Simular carga de sedes (reemplazar con tu API)
    final sites = await _loadAvailableSites();

    if (sites.isEmpty) return;

    // Configurar sedes disponibles
    userProvider.setAvailableSites(sites);

    // Mostrar selector
    final selectedSite = await _showSiteSelector(context, sites);

    if (selectedSite != null) {
      userProvider.setSelectedSite(selectedSite);
    }
  }

  /// Cargar sedes disponibles (reemplazar con tu API)
  static Future<List<Site>> _loadAvailableSites() async {
    // Simular delay de API
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      Site(id: 1, name: "Sede Central", subSites: []),
      Site(id: 2, name: "Sede Norte", subSites: []),
      Site(id: 3, name: "Sede Sur", subSites: []),
      Site(id: 4, name: "Sede Este", subSites: []),
    ];
  }

  /// Mostrar el diálogo de selección de sede
  static Future<Site?> _showSiteSelector(
      BuildContext context, List<Site> sites) async {
    return showDialog<Site>(
      context: context,
      barrierDismissible: false,
      // ✅ USAR WillPopScope PARA EVITAR CERRAR CON BACK
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Evitar cerrar con botón atrás
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ HEADER DEL DIÁLOGO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4299E1), Color(0xFF3182CE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.business_center,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Seleccionar Sede',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Como SuperAdmin, selecciona la sede a gestionar',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // ✅ CONTENIDO DEL DIÁLOGO
                Flexible(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxHeight: 400,
                      minWidth: 300,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: sites.length,
                            itemBuilder: (context, index) {
                              final site = sites[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => Navigator.pop(context, site),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade50,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4299E1)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.business,
                                              color: const Color(0xFF4299E1),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  site.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'ID: ${site.id}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.grey,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }
}
