import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/medication.dart';
import 'medication_presentation.dart';

class MedicationFormPage extends StatefulWidget {
  const MedicationFormPage({this.medication, super.key});

  final Medication? medication;

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

  bool get _isEditing => widget.medication != null;

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
        dateOnly(DateTime.now()).add(const Duration(days: 90));
    _expirationController = TextEditingController(
      text: formatDate(_expirationDate),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar medicamento' : 'Novo medicamento'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                'Informe os dados da embalagem.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'O Zelo organiza informações e não oferece orientação médica.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const ValueKey('medication-name-field'),
                controller: _nameController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome do medicamento',
                  hintText: 'Ex.: Dipirona',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do medicamento.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('medication-expiration-field'),
                readOnly: true,
                controller: _expirationController,
                decoration: const InputDecoration(
                  labelText: 'Data de validade',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_outlined),
                  suffixIcon: Icon(Icons.edit_calendar_outlined),
                ),
                onTap: _selectExpirationDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('medication-quantity-field'),
                controller: _quantityController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  hintText: 'Ex.: 8',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('medication-notes-field'),
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Ex.: Guardado no armário da cozinha',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('save-medication-button'),
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(_isEditing ? 'Salvar alterações' : 'Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectExpirationDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 20, 12, 31),
      helpText: 'Selecione a data de validade',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (selectedDate != null) {
      setState(() {
        _expirationDate = dateOnly(selectedDate);
        _expirationController.text = formatDate(_expirationDate);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      MedicationDraft(
        name: _nameController.text.trim(),
        expirationDate: _expirationDate,
        quantity: int.parse(_quantityController.text),
        notes: _notesController.text.trim(),
      ),
    );
  }
}
