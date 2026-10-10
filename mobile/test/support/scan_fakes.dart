import 'dart:async';
import 'dart:typed_data';

import 'package:zelo/features/medications/domain/medication_scan.dart';

/// Captura falsa: devolve sempre a mesma "foto" ou `null` (desistência).
class FakeImageCapture implements ImageCapture {
  FakeImageCapture({this.cancel = false});

  bool cancel;
  final sources = <ImageSourceKind>[];

  @override
  Future<CapturedImage?> pick(ImageSourceKind source) async {
    sources.add(source);
    if (cancel) {
      return null;
    }
    return CapturedImage(
      bytes: Uint8List.fromList(const [0xff, 0xd8, 0xff, 0xe0, 0, 1, 2, 3]),
      filename: 'embalagem.jpg',
      contentType: 'image/jpeg',
    );
  }
}

/// Leitura falsa com resultado configurável; pode ficar pendente para
/// exibir o progresso.
class FakeScanService implements MedicationScanService {
  FakeScanService({this.result = const MedicationScanResult(), this.error});

  MedicationScanResult result;
  Object? error;
  Completer<void>? gate;
  var calls = 0;

  @override
  Future<MedicationScanResult> scan(CapturedImage image) async {
    calls++;
    await gate?.future;
    if (error case final failure?) {
      throw failure;
    }
    return result;
  }
}
