/// Descarte registrado (RF11) e consultado no histórico (RF12).
class DisposalRecord {
  const DisposalRecord({
    required this.id,
    required this.disposedOn,
    required this.items,
    this.pointName,
    this.pointAddress,
    this.notes = '',
  });

  final String id;
  final DateTime disposedOn;
  final List<DisposalItem> items;
  final String? pointName;
  final String? pointAddress;
  final String notes;

  int get totalUnits => items.fold(0, (sum, item) => sum + item.quantity);
}

/// Cópia do medicamento no momento do descarte.
class DisposalItem {
  const DisposalItem({
    required this.name,
    required this.quantity,
    required this.expirationDate,
  });

  final String name;
  final int quantity;
  final DateTime expirationDate;
}

/// Local informado pela pessoa ou escolhido entre os pontos consultados.
class DisposalPoint {
  const DisposalPoint({required this.name, this.externalId, this.address});

  final String name;
  final String? externalId;
  final String? address;
}

class DisposalRequest {
  const DisposalRequest({
    required this.medicationIds,
    required this.disposedOn,
    this.point,
    this.notes = '',
  });

  final List<String> medicationIds;
  final DateTime disposedOn;
  final DisposalPoint? point;
  final String notes;
}

abstract interface class DisposalRepository {
  Future<List<DisposalRecord>> fetchAll();

  /// Registra o descarte e retira os medicamentos da farmácia ativa.
  Future<DisposalRecord> register(DisposalRequest request);
}

class DisposalRepositoryException implements Exception {
  const DisposalRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'DisposalRepositoryException: $message';
}
