import 'package:flutter/material.dart';

import '../../../core/formatting/dates.dart';
import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/inline_notice.dart';
import '../../../core/widgets/page_layout.dart';
import '../../medications/application/medication_store.dart';
import '../../medications/domain/medication.dart';
import '../../medications/presentation/medication_presentation.dart';
import '../application/disposal_store.dart';
import '../domain/disposal.dart';

/// Registra a entrega de medicamentos em um ponto de coleta (RF11).
class RegisterDisposalPage extends StatefulWidget {
  const RegisterDisposalPage({
    required this.medicationStore,
    required this.disposalStore,
    this.point,
    this.onRegistered,
    super.key,
  });

  final MedicationStore medicationStore;
  final DisposalStore disposalStore;

  /// Recebe o registro e o centro do botão de confirmar (coordenadas
  /// globais), de onde parte a celebração. Sem ele, a página fecha
  /// devolvendo o registro.
  final void Function(DisposalRecord record, Offset? origin)? onRegistered;

  /// Ponto escolhido na busca; sem ele, a pessoa pode descrever o local.
  final DisposalPoint? point;

  @override
  State<RegisterDisposalPage> createState() => _RegisterDisposalPageState();
}

class _RegisterDisposalPageState extends State<RegisterDisposalPage> {
  late final Set<String> _selected;
  late final TextEditingController _placeController;
  late DateTime _disposedOn;
  var _isSaving = false;
  String? _errorMessage;
  final _confirmKey = GlobalKey();

  /// Lista do momento em que a página abriu: depois de salvar, a farmácia é
  /// recarregada, mas esta tela não muda sob a celebração.
  late final List<Medication> _medications = _store.medications;

  MedicationStore get _store => widget.medicationStore;

  @override
  void initState() {
    super.initState();
    // Vencidos vêm marcados; os demais podem ser incluídos se estiverem sem uso.
    _selected = {
      for (final medication in _store.medicationsWithStatus(
        MedicationStatus.expired,
      ))
        medication.id,
    };
    _placeController = TextEditingController();
    _disposedOn = _store.today;
  }

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final medications = _medications;
    final point = widget.point;

    return PopScope<Object?>(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrar descarte')),
        body: SafeArea(
          top: false,
          child: PageScrollView(
            padding: const EdgeInsets.fromLTRB(
              ZeloSpace.gutter,
              ZeloSpace.xs,
              ZeloSpace.gutter,
              ZeloSpace.xxl,
            ),
            children: [
              Text(
                'Marque o que você entregou no ponto de coleta.',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: ZeloSpace.xxs),
              Text(
                'Os itens saem da sua farmácia e ficam registrados no '
                'histórico.',
                style: textTheme.bodyMedium?.copyWith(
                  color: ZeloColors.inkMuted,
                ),
              ),
              const SizedBox(height: ZeloSpace.xl),
              if (_errorMessage case final message?) ...[
                Semantics(
                  liveRegion: true,
                  child: InlineNotice(
                    key: const ValueKey('disposal-error'),
                    tone: NoticeTone.attention,
                    icon: Icons.error_outline,
                    message: message,
                  ),
                ),
                const SizedBox(height: ZeloSpace.md),
              ],
              const SectionHeader(title: 'Medicamentos'),
              const SizedBox(height: ZeloSpace.xs),
              if (medications.isEmpty)
                Text(
                  'Nenhum medicamento na sua farmácia.',
                  style: textTheme.bodyMedium,
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (final (index, medication)
                          in medications.indexed) ...[
                        if (index > 0) const Divider(indent: 56),
                        _MedicationCheckTile(
                          medication: medication,
                          referenceDate: _store.today,
                          selected: _selected.contains(medication.id),
                          enabled: !_isSaving,
                          onChanged: (value) => setState(() {
                            value
                                ? _selected.add(medication.id)
                                : _selected.remove(medication.id);
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: ZeloSpace.xl),
              const SectionHeader(title: 'Onde'),
              const SizedBox(height: ZeloSpace.xs),
              if (point != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(point.name),
                    subtitle: point.address == null
                        ? null
                        : Text(point.address!),
                  ),
                )
              else
                TextField(
                  key: const ValueKey('disposal-place-field'),
                  controller: _placeController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Local do descarte (opcional)',
                    hintText: 'Ex.: farmácia do bairro',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              const SizedBox(height: ZeloSpace.xl),
              const SectionHeader(title: 'Quando'),
              const SizedBox(height: ZeloSpace.xs),
              Card(
                child: ListTile(
                  key: const ValueKey('disposal-date-tile'),
                  leading: const Icon(Icons.event_outlined),
                  title: Text(formatFullDate(_disposedOn)),
                  subtitle: Text(formatLongDate(_disposedOn).split(',').first),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _isSaving ? null : _pickDate,
                ),
              ),
              const SizedBox(height: ZeloSpace.xl),
              KeyedSubtree(
                key: _confirmKey,
                child: FilledButton.icon(
                  key: const ValueKey('confirm-disposal-button'),
                  onPressed: _selected.isEmpty || _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _selected.length == 1
                        ? 'Registrar 1 item'
                        : 'Registrar ${_selected.length} itens',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final today = _store.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _disposedOn,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: today,
      helpText: 'Data do descarte',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null && mounted) {
      setState(() => _disposedOn = dateOnly(picked));
    }
  }

  Future<void> _submit() async {
    final place = _placeController.text.trim();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final record = await widget.disposalStore.register(
        DisposalRequest(
          medicationIds: [
            for (final medication in _medications)
              if (_selected.contains(medication.id)) medication.id,
          ],
          disposedOn: _disposedOn,
          point:
              widget.point ??
              (place.isEmpty ? null : DisposalPoint(name: place)),
        ),
      );
      // Sincroniza a farmácia: os itens descartados deixam de estar ativos.
      await _store.load();
      if (!mounted) {
        return;
      }
      final onRegistered = widget.onRegistered;
      if (onRegistered == null) {
        Navigator.of(context).pop(record);
        return;
      }
      final box = _confirmKey.currentContext?.findRenderObject() as RenderBox?;
      onRegistered(
        record,
        box == null || !box.hasSize
            ? null
            : box.localToGlobal(box.size.center(Offset.zero)),
      );
    } on DisposalRepositoryException catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = error.message;
        });
      }
    }
  }
}

class _MedicationCheckTile extends StatelessWidget {
  const _MedicationCheckTile({
    required this.medication,
    required this.referenceDate,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final Medication medication;
  final DateTime referenceDate;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final status = medication.statusAt(referenceDate);
    return CheckboxListTile(
      key: ValueKey('disposal-item-${medication.id}'),
      value: selected,
      enabled: enabled,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (value) => onChanged(value ?? false),
      title: Text(medication.name),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: status.label,
              style: TextStyle(color: status.ink, fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text:
                  ' · ${formatQuantity(medication.quantity)} · VAL '
                  '${formatDate(medication.expirationDate)}',
            ),
          ],
        ),
      ),
    );
  }
}
