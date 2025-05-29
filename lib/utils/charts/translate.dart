String normalizeStatus(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return 'Completada';
    case 'INPROGRESS':
      return 'En curso';
    case 'PENDING':
      return 'Pendiente';
    case 'CANCELED':
      return 'Cancelada';
    default:
      return status;
  }
}
