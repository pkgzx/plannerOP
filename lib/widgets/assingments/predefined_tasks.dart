class PredefinedTasks {
  static final Map<String, List<String>> _tasks = {
    'CAFE': [
      'Inspección de granos',
      'Control de calidad',
      'Medición de humedad',
      'Pesaje de carga',
      'Clasificación de granos',
      'Etiquetado de lotes',
    ],
    'CARGA GENERAL': [
      'Recepción de mercancía',
      'Verificación de documentos',
      'Inspección de contenedores',
      'Control de inventario',
      'Despacho de carga',
      'Embalaje de productos',
    ],
    'CARGA PELIGROSA': [
      'Verificación de etiquetas ADR',
      'Inspección de sellos',
      'Control de temperatura',
      'Verificación de fugas',
      'Control de documentación especial',
      'Inspección de embalajes',
    ],
    'CARGA REFRIGERADA': [
      'Control de temperatura',
      'Inspección de equipos de frío',
      'Verificación de aislamiento',
      'Registro de temperatura',
      'Control de cadena de frío',
      'Inspección de sellos herméticos',
    ],
    'OPERADORES MC': [
      'Revisión de maquinaria',
      'Mantenimiento preventivo',
      'Operación de grúas',
      'Movimiento de contenedores',
      'Inspección de equipos',
      'Registro de operaciones',
    ],
    'ADMINISTRATIVA': [
      'Gestión documental',
      'Trámites aduaneros',
      'Coordinación logística',
      'Atención a clientes',
      'Facturación',
      'Archivo de documentos',
    ],
  };

  // Método para obtener tareas para un área específica
  static List<String> getTasksForArea(String area) {
    // Si el área existe en nuestro mapa, devolver sus tareas
    if (_tasks.containsKey(area)) {
      return _tasks[area] ?? [];
    }

    // Si no, generar algunas tareas genéricas basadas en el área
    return [
      'Inspección de $area',
      'Mantenimiento en $area',
      'Control de calidad de $area',
      'Supervisión de $area',
      'Carga y descarga en $area',
      'Documentación de $area',
    ];
  }
}
