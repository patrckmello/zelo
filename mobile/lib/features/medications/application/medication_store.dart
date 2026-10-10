import 'package:flutter/foundation.dart';

import '../data/in_memory_medication_repository.dart';
import '../domain/medication.dart';
import '../domain/medication_repository.dart';

typedef Clock = DateTime Function();

enum MedicationLoadStatus { idle, loading, ready, failure }

/// Estado compartilhado dos medicamentos da sessão atual.
///
/// Mantém uma cópia ordenada do [MedicationRepository], deduplica cargas
/// concorrentes e converte falhas em mensagens seguras.
class MedicationStore extends ChangeNotifier {
  MedicationStore({
    MedicationRepository? repository,
    Iterable<Medication> medications = const [],
    Clock? clock,
    String? initialError,
  }) : _repository =
           repository ??
           InMemoryMedicationRepository(
             medications: medications,
             failNextFetch: initialError,
           ),
       _clock = clock ?? DateTime.now;

  factory MedicationStore.seeded({Clock? clock}) {
    final effectiveClock = clock ?? DateTime.now;
    return MedicationStore(
      clock: effectiveClock,
      repository: InMemoryMedicationRepository.seeded(today: effectiveClock()),
    );
  }

  static const loadErrorMessage =
      'Não foi possível carregar os medicamentos. Tente novamente.';
  static const saveErrorMessage =
      'Não foi possível salvar o medicamento. Tente novamente.';
  static const removeErrorMessage =
      'Não foi possível remover o medicamento. Tente novamente.';

  final MedicationRepository _repository;
  final Clock _clock;

  var _status = MedicationLoadStatus.idle;
  var _medications = const <Medication>[];
  String? _errorMessage;
  Future<void>? _loadInFlight;
  var _generation = 0;
  var _disposed = false;

  DateTime get today => dateOnly(_clock());

  /// Fonte dos dados, compartilhada com o registro de descartes em memória.
  MedicationRepository get repository => _repository;

  MedicationLoadStatus get status => _status;

  /// Verdadeiro até a primeira carga terminar com sucesso ou falha.
  bool get isLoading =>
      _status == MedicationLoadStatus.idle ||
      _status == MedicationLoadStatus.loading;

  String? get errorMessage => _errorMessage;

  /// Medicamentos ordenados pela validade e, depois, pelo nome.
  List<Medication> get medications {
    final sorted = List<Medication>.of(_medications)
      ..sort((first, second) {
        final byDate = first.expirationDate.compareTo(second.expirationDate);
        return byDate != 0 ? byDate : first.name.compareTo(second.name);
      });
    return List.unmodifiable(sorted);
  }

  int get totalCount => _medications.length;

  int countByStatus(MedicationStatus status) => _medications
      .where((medication) => medication.statusAt(today) == status)
      .length;

  List<Medication> medicationsWithStatus(MedicationStatus status) => medications
      .where((medication) => medication.statusAt(today) == status)
      .toList(growable: false);

  /// Vencidos e próximos do vencimento, do mais urgente ao menos urgente.
  List<Medication> get needingAttention => medications
      .where(
        (medication) => medication.statusAt(today) != MedicationStatus.valid,
      )
      .toList(growable: false);

  Medication? findById(String id) {
    for (final medication in _medications) {
      if (medication.id == id) {
        return medication;
      }
    }
    return null;
  }

  Future<void> load() {
    final activeLoad = _loadInFlight;
    if (activeLoad != null) {
      return activeLoad;
    }

    late final Future<void> operation;
    operation = _performLoad().whenComplete(() {
      if (identical(_loadInFlight, operation)) {
        _loadInFlight = null;
      }
    });
    _loadInFlight = operation;
    return operation;
  }

  Future<void> retry() => load();

  /// Atualiza sem trocar a lista por carregamento; falhas mantêm os dados
  /// atuais e são relançadas como [MedicationRepositoryException].
  Future<void> refresh() async {
    if (_status != MedicationLoadStatus.ready) {
      return load();
    }
    final generation = _generation;
    final medications = await _guard(_repository.fetchAll, loadErrorMessage);
    if (generation != _generation) {
      return;
    }
    _medications = List.unmodifiable(medications);
    _notify();
  }

  Future<Medication> add(MedicationDraft draft) async {
    final created = await _guard(
      () => _repository.create(draft.normalized()),
      saveErrorMessage,
    );
    _medications = [
      for (final medication in _medications)
        if (medication.id != created.id) medication,
      created,
    ];
    _notify();
    return created;
  }

  Future<Medication> update(String id, MedicationDraft draft) async {
    final updated = await _guard(
      () => _repository.update(id, draft.normalized()),
      saveErrorMessage,
    );
    _medications = [
      for (final medication in _medications)
        medication.id == id ? updated : medication,
    ];
    _notify();
    return updated;
  }

  Future<void> remove(String id) async {
    await _guard(() => _repository.delete(id), removeErrorMessage);
    final previousLength = _medications.length;
    _medications = [
      for (final medication in _medications)
        if (medication.id != id) medication,
    ];
    if (_medications.length != previousLength) {
      _notify();
    }
  }

  /// Descarta a cópia local, por exemplo ao encerrar a sessão.
  void clear() {
    _generation++;
    _loadInFlight = null;
    _medications = const [];
    _errorMessage = null;
    _status = MedicationLoadStatus.idle;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _performLoad() async {
    final generation = _generation;
    _status = MedicationLoadStatus.loading;
    _errorMessage = null;
    _notify();

    try {
      final medications = await _repository.fetchAll();
      if (generation != _generation) {
        return;
      }
      _medications = List.unmodifiable(medications);
      _status = MedicationLoadStatus.ready;
    } catch (error) {
      if (generation != _generation) {
        return;
      }
      _status = MedicationLoadStatus.failure;
      _errorMessage = error is MedicationRepositoryException
          ? error.message
          : loadErrorMessage;
    }
    _notify();
  }

  Future<T> _guard<T>(Future<T> Function() operation, String fallback) async {
    try {
      return await operation();
    } on MedicationRepositoryException {
      rethrow;
    } catch (_) {
      throw MedicationRepositoryException(fallback);
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
