import 'dart:typed_data';

/// Sugestões lidas da embalagem. Nada é salvo sem a confirmação da pessoa.
class MedicationScanResult {
  const MedicationScanResult({
    this.nameCandidates = const [],
    this.expirationDate,
    this.expirationText,
    this.expirationHasDay = false,
    this.quantity,
    this.text = '',
  });

  final List<String> nameCandidates;
  final DateTime? expirationDate;

  /// Trecho lido, como "VAL 03/2027".
  final String? expirationText;

  /// Falso quando a embalagem traz só mês e ano (vale até o fim do mês).
  final bool expirationHasDay;
  final int? quantity;
  final String text;

  bool get isEmpty =>
      nameCandidates.isEmpty && expirationDate == null && quantity == null;
}

/// Foto escolhida pela pessoa, ainda não enviada.
class CapturedImage {
  const CapturedImage({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

enum ImageSourceKind { camera, gallery }

/// Obtém a foto da câmera ou da galeria; `null` quando a pessoa desiste.
abstract interface class ImageCapture {
  Future<CapturedImage?> pick(ImageSourceKind source);
}

/// Lê a embalagem; disponível somente com a API Zelo.
abstract interface class MedicationScanService {
  Future<MedicationScanResult> scan(CapturedImage image);
}

class MedicationScanException implements Exception {
  const MedicationScanException(this.message);

  final String message;

  @override
  String toString() => 'MedicationScanException: $message';
}

/// Junta a captura e a leitura em uma única ação.
class MedicationScanner {
  const MedicationScanner({required this.capture, required this.service});

  final ImageCapture capture;
  final MedicationScanService service;

  /// `null` quando nenhuma foto foi escolhida.
  Future<MedicationScanResult?> scan(ImageSourceKind source) async {
    final image = await capture.pick(source);
    return image == null ? null : service.scan(image);
  }
}
