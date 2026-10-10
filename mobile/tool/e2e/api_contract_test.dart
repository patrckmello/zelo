// Contrato entre o aplicativo e a API Zelo real (opcional).
//
// Com o backend em execução (docker compose up), na pasta mobile/:
//   ZELO_E2E_API_URL=http://localhost:8000 flutter test tool/e2e/api_contract_test.dart
// Cria uma conta descartável e exercita autenticação, perfil, medicamentos,
// descartes, pontos e leitura de embalagem; ao final, a conta é excluída.
// Sem a variável, os testes são ignorados. Para ler uma foto de verdade,
// aponte ZELO_E2E_OCR_IMAGE para um arquivo JPEG; sem ela, uma imagem em
// branco valida só o contrato (resultado vazio).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/core/network/zelo_api_client.dart';
import 'package:zelo/core/storage/token_store.dart';
import 'package:zelo/features/account/data/api_account_service.dart';
import 'package:zelo/features/authentication/data/api_authentication_service.dart';
import 'package:zelo/features/collection_points/data/api_collection_points_repository.dart';
import 'package:zelo/features/collection_points/domain/collection_point.dart';
import 'package:zelo/features/disposal_history/data/disposal_repositories.dart';
import 'package:zelo/features/disposal_history/domain/disposal.dart';
import 'package:zelo/features/medications/data/api_medication_repository.dart';
import 'package:zelo/features/medications/data/medication_scan_services.dart';
import 'package:zelo/features/medications/domain/medication.dart';
import 'package:zelo/features/medications/domain/medication_scan.dart';

/// PNG 1×1 em branco: sem texto para ler.
const _blankPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAACklEQVR4nGP4DwABAQEAsTj2FAAAAABJRU5ErkJggg==';

void main() {
  final url = Platform.environment['ZELO_E2E_API_URL'];
  final ocrImage = Platform.environment['ZELO_E2E_OCR_IMAGE'];
  final skip = url == null ? 'Defina ZELO_E2E_API_URL para executar.' : null;

  test('fluxo completo contra a API real', () async {
    final tokens = InMemoryTokenStore();
    final client = ZeloApiClient(baseUrl: Uri.parse(url!), tokenStore: tokens);
    addTearDown(client.dispose);
    final auth = ApiAuthenticationService(client: client);
    final suffix = Random().nextInt(1 << 32).toRadixString(16);
    final email = 'contrato-$suffix@example.com';

    await auth.register(
      name: 'Contrato $suffix',
      email: email,
      password: 'senha-contrato-123',
    );
    expect(auth.currentAccount?.email, email);
    expect(await tokens.readRefreshToken(), isNotNull);

    final medications = ApiMedicationRepository(client);
    final today = DateTime.now();
    final expired = await medications.create(
      MedicationDraft(
        name: 'Soro',
        expirationDate: today.subtract(const Duration(days: 5)),
        quantity: 1,
      ).normalized(),
    );
    final valid = await medications.create(
      MedicationDraft(
        name: 'Dipirona',
        expirationDate: today.add(const Duration(days: 90)),
        quantity: 8,
        notes: 'Cozinha',
      ).normalized(),
    );
    final updated = await medications.update(
      valid.id,
      MedicationDraft(
        name: 'Dipirona gotas',
        expirationDate: valid.expirationDate,
        quantity: 2,
      ),
    );
    expect(updated.name, 'Dipirona gotas');
    expect((await medications.fetchAll()).map((m) => m.id), [
      expired.id,
      valid.id,
    ]);

    final disposals = ApiDisposalRepository(client);
    final record = await disposals.register(
      DisposalRequest(
        medicationIds: [expired.id],
        disposedOn: today,
        point: const DisposalPoint(name: 'Ponto do contrato'),
      ),
    );
    expect(record.items.single.name, 'Soro');
    expect((await disposals.fetchAll()).single.pointName, 'Ponto do contrato');
    expect((await medications.fetchAll()).single.id, valid.id);

    final points = ApiCollectionPointsRepository(client);
    try {
      final nearby = await points.findNearby(
        const GeoPosition(-30.033, -51.23),
      );
      expect(nearby.attribution, startsWith('Dados: EcoMed'));
      expect(nearby.radiusMeters, 5000);
    } on CollectionPointsException catch (error) {
      // Sem ECOMED_API_KEY, o servidor informa a configuração pendente.
      expect(error.failure, CollectionPointsFailure.notConfigured);
    }

    final account = ApiAccountService(client);
    final profile = await account.updateName('Contrato renomeado');
    expect(profile.name, 'Contrato renomeado');
    expect(profile.medicationsCount, 1);
    expect(profile.disposalsCount, 1);

    final scanner = ApiMedicationScanService(client);
    final image = ocrImage == null
        ? CapturedImage(
            bytes: base64Decode(_blankPng),
            filename: 'branco.png',
            contentType: 'image/png',
          )
        : CapturedImage(
            bytes: File(ocrImage).readAsBytesSync(),
            filename: 'embalagem.jpg',
            contentType: 'image/jpeg',
          );
    try {
      final scan = await scanner.scan(image);
      if (ocrImage == null) {
        expect(scan.isEmpty, isTrue);
      } else {
        // ignore: avoid_print
        print(
          'OCR: ${scan.nameCandidates} · ${scan.expirationDate} · '
          '${scan.quantity}',
        );
        expect(scan.isEmpty, isFalse);
      }
    } on MedicationScanException catch (error) {
      // Sem Tesseract no servidor, a leitura informa indisponibilidade.
      expect(error.message, contains('disponível'));
    }

    expect(
      await ApiAuthenticationService(client: client).restoreSession(),
      isTrue,
    );
    await auth.signOut();
    expect(await tokens.readRefreshToken(), isNull);

    await auth.signIn(email: email, password: 'senha-contrato-123');
    await account.deleteAccount(currentPassword: 'senha-contrato-123');
    expect(await tokens.readRefreshToken(), isNull);
    await expectLater(
      auth.signIn(email: email, password: 'senha-contrato-123'),
      throwsA(anything),
    );
  }, skip: skip);
}
