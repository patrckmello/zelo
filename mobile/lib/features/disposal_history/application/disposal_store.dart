import 'package:flutter/foundation.dart';

import '../domain/disposal.dart';

enum DisposalLoadStatus { idle, loading, ready, failure }

/// Histórico de descartes da sessão atual.
class DisposalStore extends ChangeNotifier {
  DisposalStore({required this._repository});

  static const loadErrorMessage =
      'Não foi possível carregar o histórico. Tente novamente.';
  static const registerErrorMessage =
      'Não foi possível registrar o descarte. Tente novamente.';

  final DisposalRepository _repository;

  var _status = DisposalLoadStatus.idle;
  var _records = const <DisposalRecord>[];
  String? _errorMessage;
  Future<void>? _loadInFlight;
  var _generation = 0;
  var _disposed = false;

  DisposalLoadStatus get status => _status;
  List<DisposalRecord> get records => _records;
  String? get errorMessage => _errorMessage;

  bool get isLoading =>
      _status == DisposalLoadStatus.idle ||
      _status == DisposalLoadStatus.loading;

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
    return _loadInFlight = operation;
  }

  Future<DisposalRecord> register(DisposalRequest request) async {
    final DisposalRecord record;
    try {
      record = await _repository.register(request);
    } on DisposalRepositoryException {
      rethrow;
    } catch (_) {
      throw const DisposalRepositoryException(registerErrorMessage);
    }
    _records = [record, ..._records]
      ..sort((a, b) => b.disposedOn.compareTo(a.disposedOn));
    _status = DisposalLoadStatus.ready;
    _notify();
    return record;
  }

  void clear() {
    _generation++;
    _loadInFlight = null;
    _records = const [];
    _errorMessage = null;
    _status = DisposalLoadStatus.idle;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _performLoad() async {
    final generation = _generation;
    _status = DisposalLoadStatus.loading;
    _errorMessage = null;
    _notify();
    try {
      final records = await _repository.fetchAll();
      if (generation != _generation) {
        return;
      }
      _records = List.unmodifiable(records);
      _status = DisposalLoadStatus.ready;
    } catch (error) {
      if (generation != _generation) {
        return;
      }
      _status = DisposalLoadStatus.failure;
      _errorMessage = error is DisposalRepositoryException
          ? error.message
          : loadErrorMessage;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
