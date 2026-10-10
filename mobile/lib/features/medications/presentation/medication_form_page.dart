import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/inline_notice.dart';
import '../domain/medication.dart';
import '../domain/medication_repository.dart';
import '../domain/medication_scan.dart';
import 'medication_presentation.dart';
import 'medication_saved_overlay.dart';

typedef MedicationSave = Future<Medication> Function(MedicationDraft draft);

class MedicationFormPage extends StatefulWidget {
  const MedicationFormPage({
    required this.onSave,
    this.medication,
    this.referenceDate,
    this.scanner,
    this.startWithScan = false,
    super.key,
  });

  final Medication? medication;

  /// Leitura da embalagem; ausente sem a API Zelo.
  final MedicationScanner? scanner;

  /// Abre a escolha da foto assim que a página aparece.
  final bool startWithScan;

  /// Persiste o rascunho; a página só fecha depois do sucesso.
  final MedicationSave onSave;

  /// Data usada na prévia da situação; o padrão é hoje.
  final DateTime? referenceDate;

  @override
  State<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _expirationController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  late DateTime _expirationDate;
  var _isSaving = false;
  String? _errorMessage;
  var _isScanning = false;
  var _nameFromScan = false;
  MedicationScanResult? _scan;
  String? _scanError;

  bool get _isEditing => widget.medication != null;

  DateTime get _referenceDate =>
      dateOnly(widget.referenceDate ?? DateTime.now());

  @override
  void initState() {
    super.initState();
    final medication = widget.medication;
    _nameController = TextEditingController(text: medication?.name);
    _quantityController = TextEditingController(
      text: medication?.quantity.toString() ?? '1',
    );
    _notesController = TextEditingController(text: medication?.notes);
    _expirationDate =
        medication?.expirationDate ??
        _referenceDate.add(const Duration(days: 90));
    _expirationController = TextEditingController(
      text: formatDate(_expirationDate),
    );
    if (widget.startWithScan && widget.scanner != null && !_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _chooseSourceAndScan();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expirationController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope<Object?>(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar medicamento' : 'Novo medicamento'),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                ZeloSpace.gutter,
                ZeloSpace.xs,
                ZeloSpace.gutter,
                ZeloSpace.xxl,
              ),
              children: [
                Text(
                  'Informe os dados da embalagem.',
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: ZeloSpace.xxs),
                Text(
                  'O Zelo organiza informações e não oferece orientação médica.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: ZeloColors.inkMuted,
                  ),
                ),
                const SizedBox(height: ZeloSpace.xl),
                if (widget.scanner != null && !_isEditing) ...[
                  _ScanCard(
                    isScanning: _isScanning,
                    result: _scan,
                    error: _scanError,
                    currentName: _nameController.text,
                    onScan: _isSaving ? null : _chooseSourceAndScan,
                    onPickName: (name) => setState(() {
                      _nameController.text = name;
                      _nameFromScan = true;
                    }),
                  ),
                  const SizedBox(height: ZeloSpace.xl),
                ],
                if (_errorMessage case final message?) ...[
                  Semantics(
                    liveRegion: true,
                    child: InlineNotice(
                      key: const ValueKey('medication-form-error'),
                      icon: Icons.error_outline,
                      tone: NoticeTone.attention,
                      message: message,
                    ),
                  ),
                  const SizedBox(height: ZeloSpace.md),
                ],
                TextFormField(
                  key: const ValueKey('medication-name-field'),
                  controller: _nameController,
                  enabled: !_isSaving,
                  // Vindo do atalho de leitura, o teclado não abre sobre a
                  // escolha da foto.
                  autofocus: !_isEditing && !widget.startWithScan,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome do medicamento',
                    hintText: 'Ex.: Dipirona',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome do medicamento.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ZeloSpace.md),
                TextFormField(
                  key: const ValueKey('medication-expiration-field'),
                  readOnly: true,
                  enabled: !_isSaving,
                  controller: _expirationController,
                  decoration: const InputDecoration(
                    labelText: 'Data de validade',
                    prefixIcon: Icon(Icons.event_outlined),
                    suffixIcon: Icon(Icons.edit_calendar_outlined),
                  ),
                  onTap: _selectExpirationDate,
                ),
                const SizedBox(height: ZeloSpace.xs),
                _StatusPreview(
                  daysUntilExpiration: civilDaysBetween(
                    _referenceDate,
                    _expirationDate,
                  ),
                ),
                const SizedBox(height: ZeloSpace.md),
                TextFormField(
                  key: const ValueKey('medication-quantity-field'),
                  controller: _quantityController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    hintText: 'Ex.: 8',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    final quantity = int.tryParse(value ?? '');
                    if (quantity == null || quantity <= 0) {
                      return 'Informe uma quantidade maior que zero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: ZeloSpace.md),
                TextFormField(
                  key: const ValueKey('medication-notes-field'),
                  controller: _notesController,
                  enabled: !_isSaving,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                    hintText: 'Ex.: Guardado no armário da cozinha',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 44),
                      child: Icon(Icons.notes_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: ZeloSpace.xl),
                FilledButton.icon(
                  key: const ValueKey('save-medication-button'),
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ZeloColors.inkMuted,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isEditing ? 'Salvar alterações' : 'Cadastrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _chooseSourceAndScan() async {
    final scanner = widget.scanner;
    if (scanner == null || _isScanning) {
      return;
    }
    final source = await showModalBottomSheet<ImageSourceKind>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ZeloSpace.gutter,
                0,
                ZeloSpace.gutter,
                ZeloSpace.xs,
              ),
              child: Text(
                'Foto da embalagem',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            ListTile(
              key: const ValueKey('scan-source-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              subtitle: const Text(
                'Enquadre o nome e a validade, com boa luz.',
              ),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSourceKind.camera),
            ),
            ListTile(
              key: const ValueKey('scan-source-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher imagem'),
              subtitle: const Text('Use uma foto já salva no aparelho.'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(ImageSourceKind.gallery),
            ),
            const SizedBox(height: ZeloSpace.md),
          ],
        ),
      ),
    );
    if (source == null || !mounted) {
      return;
    }

    setState(() {
      _isScanning = true;
      _scanError = null;
    });
    try {
      final result = await scanner.scan(source);
      if (!mounted || result == null) {
        return;
      }
      setState(() => _apply(result));
    } on MedicationScanException catch (error) {
      if (mounted) {
        setState(() => _scanError = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _scanError =
              'Não foi possível usar esta foto. Tente outra imagem ou '
              'preencha manualmente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  /// Preenche só o que foi lido; a pessoa confere antes de salvar.
  void _apply(MedicationScanResult result) {
    _scan = result;
    final name = result.nameCandidates.firstOrNull;
    if (name != null &&
        (_nameController.text.trim().isEmpty || _nameFromScan)) {
      _nameController.text = name;
      _nameFromScan = true;
    }
    if (result.expirationDate case final expiration?) {
      _expirationDate = dateOnly(expiration);
      _expirationController.text = formatDate(_expirationDate);
    }
    if (result.quantity case final quantity?) {
      _quantityController.text = '$quantity';
    }
  }

  Future<void> _selectExpirationDate() async {
    if (_isSaving) {
      return;
    }
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(_referenceDate.year + 20, 12, 31),
      helpText: 'Selecione a data de validade',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _expirationDate = dateOnly(selectedDate);
        _expirationController.text = formatDate(_expirationDate);
      });
    }
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final saved = await widget.onSave(
        MedicationDraft(
          name: _nameController.text.trim(),
          expirationDate: _expirationDate,
          quantity: int.parse(_quantityController.text),
          notes: _notesController.text.trim(),
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } on MedicationRepositoryException catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = error.message;
        });
      }
    }
  }
}

/// Prévia da situação que o medicamento terá ao ser salvo.
class _StatusPreview extends StatelessWidget {
  const _StatusPreview({required this.daysUntilExpiration});

  final int daysUntilExpiration;

  @override
  Widget build(BuildContext context) {
    final status = statusForDaysUntilExpiration(daysUntilExpiration);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ZeloSpace.xxs),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: status.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: ZeloSpace.xs),
            Expanded(
              child: Text(
                '${status.label} · ${expirationDetail(daysUntilExpiration)}',
                key: const ValueKey('medication-status-preview'),
                style: textTheme.bodySmall?.copyWith(
                  color: status.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre o formulário e confirma o resultado: o cadastro novo ganha o
/// carimbo de validade e um atalho para cadastrar outro.
Future<void> openMedicationForm(
  BuildContext context, {
  required MedicationSave onSave,
  Medication? medication,
  DateTime? referenceDate,
  MedicationScanner? scanner,
  bool startWithScan = false,
}) async {
  final saved = await Navigator.of(context).push<Medication>(
    MaterialPageRoute(
      builder: (_) => MedicationFormPage(
        medication: medication,
        onSave: onSave,
        referenceDate: referenceDate,
        scanner: scanner,
        startWithScan: startWithScan,
      ),
    ),
  );
  if (saved == null || !context.mounted) {
    return;
  }
  if (medication != null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Medicamento atualizado.')));
    return;
  }

  await showMedicationSaved(
    context,
    medication: saved,
    referenceDate: referenceDate ?? DateTime.now(),
  );
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('${saved.name} foi cadastrado.'),
        // Com ação, o Flutter mantém o aviso aberto por padrão; aqui ele some
        // sozinho (exceto com leitor de tela, que o Flutter preserva).
        persist: false,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Cadastrar outro',
          onPressed: () => openMedicationForm(
            context,
            onSave: onSave,
            referenceDate: referenceDate,
            scanner: scanner,
          ),
        ),
      ),
    );
}

/// Leitura da embalagem: convite, progresso e resultado para conferência.
class _ScanCard extends StatelessWidget {
  const _ScanCard({
    required this.isScanning,
    required this.result,
    required this.error,
    required this.currentName,
    required this.onScan,
    required this.onPickName,
  });

  final bool isScanning;
  final MedicationScanResult? result;
  final String? error;
  final String currentName;
  final VoidCallback? onScan;
  final ValueChanged<String> onPickName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (isScanning) {
      return Semantics(
        liveRegion: true,
        child: Card(
          key: const ValueKey('scan-progress'),
          child: Padding(
            padding: const EdgeInsets.all(ZeloSpace.lg),
            child: Row(
              children: [
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: ZeloSpace.sm),
                Expanded(
                  child: Text(
                    'Lendo a embalagem…',
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final scan = result;
    final children = <Widget>[];
    if (error case final message?) {
      children.add(
        InlineNotice(
          tone: NoticeTone.attention,
          icon: Icons.error_outline,
          message: message,
        ),
      );
    } else if (scan != null && scan.isEmpty) {
      children.add(
        const InlineNotice(
          key: ValueKey('scan-empty'),
          tone: NoticeTone.attention,
          icon: Icons.image_search_outlined,
          message:
              'Não encontramos nome nem validade nesta foto. Aproxime a câmera '
              'do texto, com boa luz, ou preencha manualmente.',
        ),
      );
    } else if (scan != null) {
      final expiration = scan.expirationDate;
      final details = <String>[
        if (expiration != null)
          'Validade lida: ${scan.expirationText ?? formatDate(expiration)}'
              '${scan.expirationHasDay ? '' : ' (vale até o último dia do mês)'}.',
        if (scan.quantity != null) 'Quantidade lida: ${scan.quantity}.',
      ];
      children.add(
        Semantics(
          liveRegion: true,
          child: InlineNotice(
            key: const ValueKey('scan-result'),
            tone: NoticeTone.positive,
            icon: Icons.fact_check_outlined,
            title: 'Confira os dados lidos antes de salvar',
            message: details.isEmpty
                ? 'Revise nome, validade e quantidade.'
                : details.join(' '),
          ),
        ),
      );
      final alternatives = scan.nameCandidates
          .where((name) => name != currentName)
          .toList();
      if (alternatives.isNotEmpty) {
        children.addAll([
          const SizedBox(height: ZeloSpace.sm),
          Text('Outras leituras do nome', style: textTheme.bodySmall),
          const SizedBox(height: ZeloSpace.xxs),
          Wrap(
            spacing: ZeloSpace.xs,
            runSpacing: ZeloSpace.xs,
            children: [
              for (final (index, name) in alternatives.indexed)
                ActionChip(
                  key: ValueKey('scan-name-option-$index'),
                  label: Text(name),
                  onPressed: () => onPickName(name),
                ),
            ],
          ),
        ]);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ZeloSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ZeloColors.greenTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    color: ZeloColors.onGreenTint,
                  ),
                ),
                const SizedBox(width: ZeloSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preencher pela embalagem',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fotografe o nome e a validade. A foto é lida e '
                        'descartada; você confere tudo antes de salvar.',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (children.isNotEmpty) ...[
              const SizedBox(height: ZeloSpace.md),
              ...children,
            ],
            const SizedBox(height: ZeloSpace.md),
            FilledButton.tonalIcon(
              key: const ValueKey('scan-package-button'),
              onPressed: onScan,
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(
                scan == null ? 'Escanear embalagem' : 'Escanear de novo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
