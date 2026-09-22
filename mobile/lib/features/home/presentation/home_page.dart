import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../medications/application/medication_store.dart';
import '../../medications/domain/medication.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    required this.medicationStore,
    required this.onAddMedication,
    required this.onOpenMedications,
    required this.onOpenDisposal,
    super.key,
  });

  final MedicationStore medicationStore;
  final VoidCallback onAddMedication;
  final VoidCallback onOpenMedications;
  final VoidCallback onOpenDisposal;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: medicationStore,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Zelo',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cuide. Organize. Descarte certo.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sua farmácia doméstica',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: onOpenMedications,
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SummaryGrid(store: medicationStore),
                  const SizedBox(height: 24),
                  Text(
                    'Ações rápidas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onAddMedication,
                    icon: const Icon(Icons.add),
                    label: const Text('Cadastrar medicamento'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onOpenDisposal,
                    icon: const Icon(Icons.location_searching),
                    label: const Text('Encontrar ponto de descarte'),
                  ),
                  const SizedBox(height: 24),
                  const _NoticeCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.store});

  final MedicationStore store;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 520
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              width: cardWidth,
              icon: Icons.inventory_2_outlined,
              value: store.totalCount.toString(),
              label: 'medicamentos cadastrados',
              color: ZeloColors.petroleumBlue,
            ),
            _SummaryCard(
              width: cardWidth,
              icon: Icons.schedule,
              value: store
                  .countByStatus(MedicationStatus.expiringSoon)
                  .toString(),
              label: 'próximos do vencimento',
              color: ZeloColors.warningAmber,
            ),
            _SummaryCard(
              width: cardWidth,
              icon: Icons.error_outline,
              value: store.countByStatus(MedicationStatus.expired).toString(),
              label: 'medicamento vencido',
              color: ZeloColors.expiredRed,
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final double width;
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: color),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: color),
                    ),
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: ZeloColors.petroleumBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Os medicamentos desta versão ficam somente na memória e são '
                'apagados quando o aplicativo é encerrado.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
