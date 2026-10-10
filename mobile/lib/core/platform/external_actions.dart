import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ações que deixam o aplicativo: abrir um local no mapa e telefonar.
abstract interface class ExternalActions {
  Future<bool> openInMaps({
    required double latitude,
    required double longitude,
    required String label,
  });

  Future<bool> dial(String phone);
}

/// No Android, o intent `geo:` deixa a pessoa escolher o aplicativo de mapas
/// (D008 segue sem fornecedor definido). Nas demais plataformas, abre o
/// OpenStreetMap no navegador.
class UrlLauncherExternalActions implements ExternalActions {
  const UrlLauncherExternalActions();

  @override
  Future<bool> openInMaps({
    required double latitude,
    required double longitude,
    required String label,
  }) {
    final coordinates = '$latitude,$longitude';
    final uri = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? Uri.parse(
            'geo:$coordinates?q=$coordinates(${Uri.encodeComponent(label)})',
          )
        : Uri.https('www.openstreetmap.org', '/', {
            'mlat': '$latitude',
            'mlon': '$longitude',
          }).replace(fragment: 'map=17/$latitude/$longitude');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<bool> dial(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return launchUrl(Uri(scheme: 'tel', path: digits));
  }
}
