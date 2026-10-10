import 'package:flutter/material.dart';

import '../../../core/platform/external_actions.dart';
import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/inline_notice.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../core/widgets/skeleton.dart';
import '../../medications/application/medication_store.dart';
import '../../medications/domain/medication.dart';
import '../../medications/presentation/widgets/medication_tile.dart';
import '../application/collection_points_controller.dart';
import '../domain/collection_point.dart';
import '../domain/location.dart';
import 'collection_point_detail_page.dart';
import 'collection_point_presentation.dart';
import 'collection_point_tile.dart';

/// Área "Descartar": itens vencidos separados e pontos de coleta próximos.
class CollectionPointsPage extends StatelessWidget {
  const CollectionPointsPage({
    required this.medicationStore,
    required this.externalActions,
    required this.onOpenMedication,
    required this.onOpenExpired,
    required this.onRegisterDisposal,
    this.controller,
    this.onBackToHome,
    super.key,
  });

  final MedicationStore medicationStore;

  /// Ausente quando o servidor Zelo não está configurado nesta execução.
  final CollectionPointsController? controller;
  final ExternalActions externalActions;
  final ValueChanged<String> onOpenMedication;
  final VoidCallback onOpenExpired;

  /// Abre o registro de descarte, com o ponto escolhido quando houver.
  final ValueChanged<CollectionPoint?> onRegisterDisposal;

  /// Presente quando a área foi aberta pelo atalho da Início.
  final VoidCallback? onBackToHome;

  static const previewLimit = 3;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: PageScrollView(
        children: [
          PageHeader(
            title: 'Descartar',
            subtitle:
                'Leve medicamentos vencidos ou sem uso a um ponto de coleta.',
            onBack: onBackToHome,
          ),
          const SizedBox(height: ZeloSpace.xl),
          const SectionHeader(title: 'Separados para descarte'),
          const SizedBox(height: ZeloSpace.xs),
          ListenableBuilder(
            listenable: medicationStore,
            builder: (context, _) => _ExpiredSection(
              store: medicationStore,
              onOpenMedication: onOpenMedication,
              onOpenExpired: onOpenExpired,
              onRegisterDisposal: () => onRegisterDisposal(null),
            ),
          ),
          const SizedBox(height: ZeloSpace.xxl),
          if (controller case final controller?)
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _PointsSection(
                controller: controller,
                externalActions: externalActions,
                onRegisterDisposal: onRegisterDisposal,
              ),
            )
          else
            const _UnconfiguredPoints(),
          const SizedBox(height: ZeloSpace.xl),
          const InlineNotice(
            icon: Icons.water_drop_outlined,
            message:
                'Evite descartar medicamentos no lixo comum, na pia ou no vaso '
                'sanitário.',
          ),
        ],
      ),
    );
  }
}

class _ExpiredSection extends StatelessWidget {
  const _ExpiredSection({
    required this.store,
    required this.onOpenMedication,
    required this.onOpenExpired,
    required this.onRegisterDisposal,
  });

  final MedicationStore store;
  final ValueChanged<String> onOpenMedication;
  final VoidCallback onOpenExpired;
  final VoidCallback onRegisterDisposal;

  @override
  Widget build(BuildContext context) {
    if (store.isLoading) {
      return const SkeletonList(count: 1, label: 'Carregando medicamentos');
    }
    final expired = store.medicationsWithStatus(MedicationStatus.expired);
    final registerButton = FilledButton.tonalIcon(
      key: const ValueKey('register-disposal-button'),
      onPressed: onRegisterDisposal,
      icon: const Icon(Icons.add_task),
      label: const Text('Registrar descarte'),
    );
    if (expired.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InlineNotice(
            tone: NoticeTone.positive,
            icon: Icons.check_circle_outline,
            message: 'Nenhum medicamento vencido na sua farmácia no momento.',
          ),
          if (store.totalCount > 0) ...[
            const SizedBox(height: ZeloSpace.sm),
            registerButton,
          ],
        ],
      );
    }

    final preview = expired.take(CollectionPointsPage.previewLimit);
    final remaining = expired.length - CollectionPointsPage.previewLimit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final medication in preview) ...[
          MedicationTile(
            medication: medication,
            referenceDate: store.today,
            onTap: () => onOpenMedication(medication.id),
          ),
          const SizedBox(height: ZeloSpace.xs),
        ],
        if (remaining > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onOpenExpired,
              child: Text(
                remaining == 1
                    ? 'Ver mais 1 vencido'
                    : 'Ver mais $remaining vencidos',
              ),
            ),
          ),
        const SizedBox(height: ZeloSpace.xs),
        registerButton,
      ],
    );
  }
}

class _UnconfiguredPoints extends StatelessWidget {
  const _UnconfiguredPoints();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ZeloSpace.lg),
        child: Column(
          children: [
            const DisposalPathScene(),
            const SizedBox(height: ZeloSpace.lg),
            Text(
              'Pontos de descarte',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: ZeloSpace.xxs),
            Text(
              'A consulta de pontos será disponibilizada quando a integração '
              'com a EcoMed estiver configurada no servidor do Zelo.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsSection extends StatelessWidget {
  const _PointsSection({
    required this.controller,
    required this.externalActions,
    required this.onRegisterDisposal,
  });

  final CollectionPointsController controller;
  final ExternalActions externalActions;
  final ValueChanged<CollectionPoint?> onRegisterDisposal;

  @override
  Widget build(BuildContext context) {
    final label = controller.queryLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Pontos de coleta',
          actionLabel:
              controller.phase == CollectionPointsPhase.idle ||
                  controller.isBusy
              ? null
              : 'Nova busca',
          actionKey: const ValueKey('points-new-search-button'),
          onAction: controller.reset,
        ),
        if (label != null && controller.phase != CollectionPointsPhase.idle)
          Padding(
            padding: const EdgeInsets.only(bottom: ZeloSpace.xs),
            child: Text(
              controller.result == null
                  ? label
                  : '$label · raio de '
                        '${formatDistance(controller.result!.radiusMeters)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          const SizedBox(height: ZeloSpace.xs),
        switch (controller.phase) {
          CollectionPointsPhase.idle => _SearchPrompt(controller: controller),
          CollectionPointsPhase.locating => _LocatingCard(
            controller: controller,
          ),
          CollectionPointsPhase.loading => const SkeletonList(
            count: 3,
            label: 'Buscando pontos de coleta',
          ),
          CollectionPointsPhase.failure => _SearchFailure(
            controller: controller,
          ),
          CollectionPointsPhase.loaded => _Results(
            result: controller.result!,
            externalActions: externalActions,
            onRegisterDisposal: onRegisterDisposal,
          ),
        },
      ],
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({required this.controller});

  final CollectionPointsController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ZeloSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: DisposalPathScene()),
            const SizedBox(height: ZeloSpace.lg),
            Text('Encontre onde descartar', style: textTheme.titleMedium),
            const SizedBox(height: ZeloSpace.xxs),
            Text(
              'Para mostrar pontos próximos, o Zelo usa sua localização '
              'aproximada somente nesta busca. Ela não é salva.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: ZeloSpace.lg),
            FilledButton.icon(
              key: const ValueKey('points-use-location-button'),
              onPressed: controller.searchNearMe,
              icon: const Icon(Icons.my_location),
              label: const Text('Usar minha localização'),
            ),
            const SizedBox(height: ZeloSpace.sm),
            OutlinedButton.icon(
              key: const ValueKey('points-choose-region-button'),
              onPressed: () => _chooseRegion(context, controller),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Escolher uma região'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre a lista de municípios e busca a partir da sede escolhida.
Future<void> _chooseRegion(
  BuildContext context,
  CollectionPointsController controller,
) async {
  final region = await showModalBottomSheet<ReferenceRegion>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _RegionSheet(),
  );
  if (region != null) {
    await controller.searchRegion(region);
  }
}

/// Espera da localização com saída: a pessoa nunca fica presa aqui.
class _LocatingCard extends StatelessWidget {
  const _LocatingCard({required this.controller});

  final CollectionPointsController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Card(
        key: const ValueKey('points-locating'),
        child: Padding(
          padding: const EdgeInsets.all(ZeloSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: ZeloSpace.sm),
                  Expanded(
                    child: Text(
                      'Obtendo sua localização…',
                      style: textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ZeloSpace.xs),
              Text(
                'Confirme a permissão, se o aparelho pedir. Em computadores sem '
                'Wi-Fi ou GPS a localização pode não estar disponível.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: ZeloSpace.md),
              OutlinedButton.icon(
                key: const ValueKey('points-locating-region-button'),
                onPressed: () {
                  controller.reset();
                  _chooseRegion(context, controller);
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Escolher uma região'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionSheet extends StatelessWidget {
  const _RegionSheet();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: ZeloSpace.xl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ZeloSpace.gutter,
              0,
              ZeloSpace.gutter,
              ZeloSpace.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Escolha uma região', style: textTheme.titleLarge),
                const SizedBox(height: ZeloSpace.xxs),
                Text(
                  'A busca usa o centro do município como referência.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          for (final region in referenceRegions)
            ListTile(
              key: ValueKey('region-${region.name}'),
              leading: const Icon(Icons.location_city_outlined),
              title: Text(region.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pop(region),
            ),
        ],
      ),
    );
  }
}

class _SearchFailure extends StatelessWidget {
  const _SearchFailure({required this.controller});

  final CollectionPointsController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(ZeloSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Não foi possível concluir a busca',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: ZeloSpace.xxs),
              Text(
                controller.failureMessage ??
                    CollectionPointsController.genericFailureMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: ZeloSpace.md),
              OutlinedButton.icon(
                key: const ValueKey('points-retry-button'),
                onPressed: controller.retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
              const SizedBox(height: ZeloSpace.xs),
              TextButton(
                key: const ValueKey('points-failure-region-button'),
                onPressed: () {
                  controller.reset();
                  _chooseRegion(context, controller);
                },
                child: const Text('Escolher uma região'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.result,
    required this.externalActions,
    required this.onRegisterDisposal,
  });

  final NearbyCollectionPoints result;
  final ExternalActions externalActions;
  final ValueChanged<CollectionPoint?> onRegisterDisposal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (result.points.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(ZeloSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nenhum ponto encontrado neste raio',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: ZeloSpace.xxs),
              Text(
                'Tente outra região. Não exibimos pontos sem confirmação da '
                'fonte de dados.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: ZeloSpace.md),
              Text(result.attribution, style: textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    final pharmacies = result.pharmacies;
    final others = result.others;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pharmacies.isNotEmpty) ...[
          _GroupLabel('Farmácias do programa LogMed', count: pharmacies.length),
          for (final point in pharmacies) _tile(context, point),
        ],
        if (others.isNotEmpty) ...[
          if (pharmacies.isNotEmpty) const SizedBox(height: ZeloSpace.md),
          _GroupLabel('Outros pontos', count: others.length),
          const InlineNotice(
            tone: NoticeTone.attention,
            icon: Icons.call_outlined,
            message:
                'Podem incluir unidades públicas que não recebem medicamentos '
                'da população. Confirme por telefone antes de ir.',
          ),
          const SizedBox(height: ZeloSpace.xs),
          for (final point in others) _tile(context, point),
        ],
        const SizedBox(height: ZeloSpace.sm),
        Text(
          result.attribution,
          key: const ValueKey('points-attribution'),
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, CollectionPoint point) => Padding(
    padding: const EdgeInsets.only(bottom: ZeloSpace.xs),
    child: CollectionPointTile(
      point: point,
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CollectionPointDetailPage(
            point: point,
            attribution: result.attribution,
            externalActions: externalActions,
            onRegisterDisposal: () => onRegisterDisposal(point),
          ),
        ),
      ),
    ),
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text, {required this.count});

  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ZeloSpace.xs),
      child: Text(
        '$text · $count',
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: ZeloColors.inkSoft, fontSize: 13),
      ),
    );
  }
}
