import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/brand_symbol.dart';
import '../../../core/widgets/inline_notice.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../core/widgets/skeleton.dart';
import '../../medications/application/medication_store.dart';
import '../../medications/domain/medication.dart';
import '../../medications/presentation/medication_scenes.dart';
import '../../medications/presentation/widgets/medication_tile.dart';
import '../../medications/presentation/widgets/pharmacy_overview.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    required this.medicationStore,
    required this.onAddMedication,
    required this.onOpenMedications,
    required this.onOpenMedication,
    required this.onOpenDisposal,
    this.storageNotice,
    this.greetingName,
    this.onScanPackage,
    super.key,
  });

  /// Quantidade máxima de itens na seção "Precisa de atenção".
  static const attentionPreviewLimit = 3;

  final MedicationStore medicationStore;
  final VoidCallback onAddMedication;
  final VoidCallback onOpenMedications;
  final ValueChanged<String> onOpenMedication;
  final VoidCallback onOpenDisposal;

  /// Aviso sobre onde os dados ficam guardados nesta configuração.
  final String? storageNotice;

  /// Nome da conta conectada, usado na saudação.
  final String? greetingName;

  /// Abre o cadastro já na leitura da embalagem; ausente sem a API.
  final VoidCallback? onScanPackage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: medicationStore,
      builder: (context, _) {
        final store = medicationStore;
        final hasMedications =
            store.status == MedicationLoadStatus.ready && store.totalCount > 0;

        return SafeArea(
          bottom: false,
          child: PageScrollView(
            children: [
              _HomeHeader(greetingName: greetingName),
              const SizedBox(height: ZeloSpace.xxl),
              SectionHeader(
                title: 'Sua farmácia doméstica',
                actionLabel: 'Ver todos',
                onAction: onOpenMedications,
              ),
              const SizedBox(height: ZeloSpace.xs),
              _OverviewArea(store: store),
              if (hasMedications) ...[
                const SizedBox(height: ZeloSpace.xxl),
                const SectionHeader(title: 'Precisa de atenção'),
                const SizedBox(height: ZeloSpace.xs),
                _AttentionList(
                  store: store,
                  onOpenMedication: onOpenMedication,
                  onOpenMedications: onOpenMedications,
                ),
              ],
              const SizedBox(height: ZeloSpace.xxl),
              const SectionHeader(title: 'Ações rápidas'),
              const SizedBox(height: ZeloSpace.sm),
              _QuickActions(
                onAddMedication: onAddMedication,
                onOpenDisposal: onOpenDisposal,
                onScanPackage: onScanPackage,
              ),
              if (storageNotice case final notice?) ...[
                const SizedBox(height: ZeloSpace.xl),
                InlineNotice(message: notice),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({this.greetingName});

  final String? greetingName;

  String get _title {
    final first = greetingName?.trim().split(RegExp(r'\s+')).first ?? '';
    return first.isEmpty ? 'Zelo' : 'Olá, $first';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        const BrandSymbol(size: 44, decorative: true),
        const SizedBox(width: ZeloSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(_title, style: textTheme.headlineMedium),
              ),
              Text(
                'Cuide. Organize. Descarte certo.',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewArea extends StatelessWidget {
  const _OverviewArea({required this.store});

  final MedicationStore store;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (store.isLoading) {
      return Semantics(
        container: true,
        label: 'Carregando resumo da farmácia',
        child: const ExcludeSemantics(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(ZeloSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 72, height: 36),
                  SizedBox(height: ZeloSpace.md),
                  SkeletonBlock(height: 10),
                  SizedBox(height: ZeloSpace.md),
                  SkeletonBlock(width: 180),
                  SizedBox(height: ZeloSpace.xs),
                  SkeletonBlock(width: 150),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (store.status == MedicationLoadStatus.failure) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(ZeloSpace.lg),
          child: Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Não foi possível carregar seus medicamentos',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: ZeloSpace.xxs),
                Text(
                  store.errorMessage ?? MedicationStore.loadErrorMessage,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: ZeloSpace.md),
                OutlinedButton.icon(
                  key: const ValueKey('home-retry-button'),
                  onPressed: store.retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (store.totalCount == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(ZeloSpace.lg),
          child: Column(
            children: [
              const EmptyShelfScene(),
              const SizedBox(height: ZeloSpace.lg),
              Text(
                'Nenhum medicamento por aqui',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: ZeloSpace.xxs),
              Text(
                'Cadastre o primeiro medicamento para acompanhar a validade '
                'de tudo o que você guarda em casa.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return PharmacyOverview(
      referenceDate: store.today,
      validCount: store.countByStatus(MedicationStatus.valid),
      expiringCount: store.countByStatus(MedicationStatus.expiringSoon),
      expiredCount: store.countByStatus(MedicationStatus.expired),
    );
  }
}

class _AttentionList extends StatelessWidget {
  const _AttentionList({
    required this.store,
    required this.onOpenMedication,
    required this.onOpenMedications,
  });

  final MedicationStore store;
  final ValueChanged<String> onOpenMedication;
  final VoidCallback onOpenMedications;

  @override
  Widget build(BuildContext context) {
    final items = store.needingAttention;
    if (items.isEmpty) {
      return const InlineNotice(
        tone: NoticeTone.positive,
        icon: Icons.check_circle_outline,
        title: 'Tudo em dia',
        message:
            'Nenhum medicamento vencido ou vencendo nos próximos '
            '$defaultExpirationWarningDays dias.',
      );
    }

    final preview = items.take(HomePage.attentionPreviewLimit).toList();
    final remaining = items.length - preview.length;
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
              onPressed: onOpenMedications,
              child: Text(
                remaining == 1
                    ? 'Mais 1 item precisa de atenção'
                    : 'Mais $remaining itens precisam de atenção',
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddMedication,
    required this.onOpenDisposal,
    this.onScanPackage,
  });

  final VoidCallback onAddMedication;
  final VoidCallback onOpenDisposal;
  final VoidCallback? onScanPackage;

  @override
  Widget build(BuildContext context) {
    final add = _ActionTile(
      icon: Icons.add,
      label: 'Cadastrar medicamento',
      emphasized: true,
      onTap: onAddMedication,
    );
    final scan = onScanPackage;
    final disposal = _ActionTile(
      icon: Icons.recycling,
      label: 'Encontrar ponto de descarte',
      onTap: onOpenDisposal,
      horizontal: scan != null,
    );
    // Com a leitura disponível, cadastro e leitura dividem a linha e o
    // descarte ocupa a largura toda logo abaixo.
    final partner = scan == null
        ? disposal
        : _ActionTile(
            key: const ValueKey('home-scan-action'),
            icon: Icons.document_scanner_outlined,
            label: 'Escanear embalagem',
            onTap: scan,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 340 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final pair = stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  add,
                  const SizedBox(height: ZeloSpace.sm),
                  partner,
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: add),
                    const SizedBox(width: ZeloSpace.sm),
                    Expanded(child: partner),
                  ],
                ),
              );
        if (scan == null) {
          return pair;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            pair,
            const SizedBox(height: ZeloSpace.sm),
            disposal,
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
    this.horizontal = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  /// Ícone e texto lado a lado, para a ação de largura total.
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final foreground = emphasized ? ZeloColors.paper : ZeloColors.ink;
    final iconBackground = emphasized
        ? ZeloColors.paper.withValues(alpha: 0.14)
        : ZeloColors.greenTint;
    final iconColor = emphasized ? ZeloColors.paper : ZeloColors.onGreenTint;
    final badge = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
    final text = Text(
      label,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
    );

    return Material(
      color: emphasized ? ZeloColors.petroleumBlue : ZeloColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ZeloRadii.card),
        side: emphasized
            ? BorderSide.none
            : const BorderSide(color: ZeloColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          child: Padding(
            padding: const EdgeInsets.all(ZeloSpace.md),
            child: horizontal
                ? Row(
                    children: [
                      badge,
                      const SizedBox(width: ZeloSpace.sm),
                      Expanded(child: text),
                      const Icon(
                        Icons.chevron_right,
                        color: ZeloColors.inkMuted,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      badge,
                      const SizedBox(height: ZeloSpace.lg),
                      text,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
