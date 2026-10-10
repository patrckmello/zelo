import 'package:image_picker/image_picker.dart';

import '../../../core/network/zelo_api_client.dart';
import '../domain/medication_scan.dart';
import 'api_medication_repository.dart';

/// Envia a foto para a leitura no servidor; a imagem não é guardada.
class ApiMedicationScanService implements MedicationScanService {
  ApiMedicationScanService(this.client);

  final ZeloApiClient client;

  @override
  Future<MedicationScanResult> scan(CapturedImage image) async {
    try {
      final json = await client.upload(
        '/v1/ocr/medication',
        field: 'image',
        bytes: image.bytes,
        filename: image.filename,
        contentType: image.contentType,
      ) as Map<String, dynamic>;
      final expiration = json['expiration_date'] as String?;
      return MedicationScanResult(
        nameCandidates: [
          for (final name in json['name_candidates'] as List<dynamic>)
            name as String,
        ],
        expirationDate: expiration == null ? null : parseIsoDate(expiration),
        expirationText: json['expiration_text'] as String?,
        expirationHasDay: json['expiration_has_day'] as bool? ?? false,
        quantity: json['quantity'] as int?,
        text: json['text'] as String? ?? '',
      );
    } on ApiException catch (error) {
      throw MedicationScanException(error.message);
    }
  }
}

/// Câmera ou galeria pelo `image_picker`, com a foto reduzida antes do envio.
class ImagePickerCapture implements ImageCapture {
  ImagePickerCapture({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<CapturedImage?> pick(ImageSourceKind source) async {
    final file = await _picker.pickImage(
      source: source == ImageSourceKind.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 85,
    );
    if (file == null) {
      return null;
    }
    final name = file.name.isEmpty ? 'embalagem.jpg' : file.name;
    return CapturedImage(
      bytes: await file.readAsBytes(),
      filename: name,
      contentType: file.mimeType ?? _contentTypeFor(name),
    );
  }

  static String _contentTypeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
