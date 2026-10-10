import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/collection_point.dart';
import '../domain/location.dart';

enum CollectionPointsPhase { idle, locating, loading, loaded, failure }

/// Estado da busca de pontos: pede a localização somente após a ação da
/// pessoa, arredonda as coordenadas antes do envio e ignora respostas
/// obsoletas ou posteriores ao descarte.
class CollectionPointsController extends ChangeNotifier {
  CollectionPointsController({
    required this.repository,
    required this.locationProvider,
    this.locationTimeout = const Duration(seconds: 30),
  });

  static const genericFailureMessage =
      'Não foi possível consultar os pontos agora. Tente novamente.';
  static const locationTimeoutMessage =
      'A localização demorou demais para responder. Em computadores sem '
      'Wi-Fi ou GPS isso é comum: escolha uma região.';

  final CollectionPointsRepository repository;
  final LocationProvider locationProvider;

  /// Limite final da leitura de localização, para a tela nunca ficar presa.
  final Duration locationTimeout;

  var _phase = CollectionPointsPhase.idle;
  NearbyCollectionPoints? _result;
  String? _failureMessage;
  String? _queryLabel;
  GeoPosition? _lastPosition;
  var _lastFailureWasLocation = false;
  var _generation = 0;
  var _disposed = false;

  CollectionPointsPhase get phase => _phase;
  NearbyCollectionPoints? get result => _result;
  String? get failureMessage => _failureMessage;

  /// "Perto de você" ou o nome da região escolhida.
  String? get queryLabel => _queryLabel;

  bool get isBusy =>
      _phase == CollectionPointsPhase.locating ||
      _phase == CollectionPointsPhase.loading;

  Future<void> searchNearMe() async {
    final generation = ++_generation;
    _queryLabel = 'Perto de você';
    _update(CollectionPointsPhase.locating);
    try {
      final position = await locationProvider.currentPosition().timeout(
        locationTimeout,
      );
      if (generation != _generation) {
        return;
      }
      await _search(position, generation);
    } on LocationException catch (error) {
      if (generation == _generation) {
        _lastFailureWasLocation = true;
        _fail(error.message);
      }
    } on TimeoutException {
      if (generation == _generation) {
        _lastFailureWasLocation = true;
        _fail(locationTimeoutMessage);
      }
    }
  }

  Future<void> searchRegion(ReferenceRegion region) {
    final generation = ++_generation;
    _queryLabel = region.name;
    return _search(region.position, generation);
  }

  Future<void> retry() {
    final position = _lastPosition;
    if (_lastFailureWasLocation || position == null) {
      return searchNearMe();
    }
    final generation = ++_generation;
    return _search(position, generation);
  }

  void reset() {
    _generation++;
    _result = null;
    _failureMessage = null;
    _queryLabel = null;
    _update(CollectionPointsPhase.idle);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _search(GeoPosition position, int generation) async {
    final rounded = position.rounded();
    _lastPosition = rounded;
    _lastFailureWasLocation = false;
    _update(CollectionPointsPhase.loading);
    try {
      final result = await repository.findNearby(rounded);
      if (generation != _generation) {
        return;
      }
      _result = result;
      _failureMessage = null;
      _update(CollectionPointsPhase.loaded);
    } on CollectionPointsException catch (error) {
      if (generation == _generation) {
        _fail(error.message);
      }
    } catch (_) {
      if (generation == _generation) {
        _fail(genericFailureMessage);
      }
    }
  }

  void _fail(String message) {
    _result = null;
    _failureMessage = message;
    _update(CollectionPointsPhase.failure);
  }

  void _update(CollectionPointsPhase phase) {
    _phase = phase;
    if (!_disposed) {
      notifyListeners();
    }
  }
}
