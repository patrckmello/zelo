import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/collection_point.dart';
import '../domain/location.dart';

/// Localização aproximada (precisão baixa) obtida pelo `geolocator`.
///
/// Toda leitura tem limite de tempo: em computadores sem Wi-Fi nem GPS o
/// navegador pode nunca responder, e a busca não pode ficar presa.
class GeolocatorLocationProvider implements LocationProvider {
  const GeolocatorLocationProvider({
    this.timeout = const Duration(seconds: 15),
  });

  final Duration timeout;

  static const _deniedMessage =
      'Sem permissão de localização. Você pode escolher uma região ou '
      'permitir o acesso nas configurações.';
  static const _unavailableMessage =
      'Não foi possível obter sua localização agora. Em computadores sem '
      'Wi-Fi ou GPS isso é comum: escolha uma região.';

  @override
  Future<GeoPosition> currentPosition() async {
    try {
      // Na Web o navegador pede a permissão na própria leitura; o
      // `requestPermission` do plugin faria uma leitura extra sem limite.
      if (!kIsWeb) {
        await _ensurePermission();
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: timeout,
        ),
      ).timeout(timeout + const Duration(seconds: 2));
      return GeoPosition(position.latitude, position.longitude);
    } on LocationException {
      rethrow;
    } on PermissionDeniedException {
      throw const LocationException(
        LocationFailure.permissionDenied,
        _deniedMessage,
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        LocationFailure.serviceDisabled,
        'A localização do aparelho está desligada. Ative-a ou escolha uma '
        'região.',
      );
    } catch (_) {
      throw const LocationException(
        LocationFailure.unavailable,
        _unavailableMessage,
      );
    }
  }

  Future<void> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled().timeout(timeout)) {
      throw const LocationServiceDisabledException();
    }
    var permission = await Geolocator.checkPermission().timeout(timeout);
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission().timeout(
        const Duration(minutes: 2),
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationFailure.permissionDenied,
        _deniedMessage,
      );
    }
  }
}
