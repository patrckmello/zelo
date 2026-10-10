import 'package:flutter/material.dart';

import '../../../core/platform/external_actions.dart';
import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/inline_notice.dart';
import '../../../core/widgets/page_layout.dart';
import '../domain/collection_point.dart';
import 'collection_point_presentation.dart';

class CollectionPointDetailPage extends StatelessWidget {
  const CollectionPointDetailPage({
    required this.point,
    required this.attribution,
    required this.externalActions,
    this.onRegisterDisposal,
    super.key,
  });

  final CollectionPoint point;
  final String attribution;
  final ExternalActions externalActions;

  /// Registra no histórico a entrega feita neste ponto.
  final VoidCallback? onRegisterDisposal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final phone = point.phone;
    final distance = point.distanceMeters;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: PageScrollView(
          padding: const EdgeInsets.fromLTRB(
            ZeloSpace.gutter,
            ZeloSpace.xxs,
            ZeloSpace.gutter,
            ZeloSpace.xxl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(point.name, style: textTheme.headlineSmall),
            ),
            const SizedBox(height: ZeloSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: CollectionPointOriginBadge(point: point),
            ),
            const SizedBox(height: ZeloSpace.lg),
            Card(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.place_outlined,
                    label: 'Endereço',
                    value: [
                      point.address,
                      point.locality,
                    ].where((part) => part.isNotEmpty).join('\n'),
                  ),
                  if (distance != null) ...[
                    const Divider(indent: 56),
                    _InfoRow(
                      icon: Icons.near_me_outlined,
                      label: 'Distância aproximada',
                      value: formatDistance(distance),
                    ),
                  ],
                  if (phone != null) ...[
                    const Divider(indent: 56),
                    _InfoRow(
                      icon: Icons.call_outlined,
                      label: 'Telefone',
                      value: phone,
                    ),
                  ],
                  if (point.residueTypes.isNotEmpty) ...[
                    const Divider(indent: 56),
                    _InfoRow(
                      icon: Icons.recycling,
                      label: 'Recebe',
                      value: point.residueTypes.map(residueLabel).join(', '),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: ZeloSpace.md),
            if (point.requiresConfirmation)
              const InlineNotice(
                tone: NoticeTone.attention,
                icon: Icons.call_outlined,
                message:
                    'Este ponto não pertence ao programa LogMed e pode ser uma '
                    'unidade pública que não recebe medicamentos trazidos pela '
                    'população. Ligue antes do deslocamento.',
              )
            else
              const InlineNotice(
                tone: NoticeTone.positive,
                icon: Icons.verified_outlined,
                title: 'Farmácia do programa LogMed',
                message:
                    'Ponto declarado no programa de logística reversa de '
                    'medicamentos LogMed.',
              ),
            const SizedBox(height: ZeloSpace.sm),
            Text(
              'Horário de funcionamento não informado. Confirme o atendimento '
              'antes de sair de casa.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: ZeloSpace.xl),
            FilledButton.icon(
              key: const ValueKey('open-map-button'),
              onPressed: () => _openMap(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Abrir no mapa'),
            ),
            if (phone != null) ...[
              const SizedBox(height: ZeloSpace.sm),
              OutlinedButton.icon(
                key: const ValueKey('call-point-button'),
                onPressed: () => _call(context, phone),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Ligar para o ponto'),
              ),
            ],
            if (onRegisterDisposal case final register?) ...[
              const SizedBox(height: ZeloSpace.sm),
              FilledButton.tonalIcon(
                key: const ValueKey('register-disposal-here-button'),
                onPressed: register,
                icon: const Icon(Icons.add_task),
                label: const Text('Registrar descarte aqui'),
              ),
            ],
            const SizedBox(height: ZeloSpace.xl),
            Text(attribution, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(BuildContext context) async {
    final opened = await _safely(
      () => externalActions.openInMaps(
        latitude: point.latitude,
        longitude: point.longitude,
        label: point.name,
      ),
    );
    if (!opened && context.mounted) {
      _showFailure(context, 'Não foi possível abrir o mapa neste aparelho.');
    }
  }

  Future<void> _call(BuildContext context, String phone) async {
    final opened = await _safely(() => externalActions.dial(phone));
    if (!opened && context.mounted) {
      _showFailure(context, 'Não foi possível iniciar a ligação.');
    }
  }

  Future<bool> _safely(Future<bool> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return false;
    }
  }

  void _showFailure(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.all(ZeloSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(icon, color: ZeloColors.inkMuted, size: 22),
            ),
            const SizedBox(width: ZeloSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: textTheme.bodyLarge?.copyWith(
                      color: ZeloColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
