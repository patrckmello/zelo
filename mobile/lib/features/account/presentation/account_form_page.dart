import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/inline_notice.dart';
import '../../../core/widgets/page_layout.dart';
import '../domain/account_service.dart';

/// Campo de um formulário de conta.
class AccountFormField {
  const AccountFormField({
    required this.id,
    required this.label,
    this.initialValue,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.helperText,
    this.icon,
    this.validator,
  });

  final String id;
  final String label;
  final String? initialValue;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final String? helperText;
  final IconData? icon;

  /// Recebe o valor do campo e todos os valores do formulário.
  final String? Function(String value, Map<String, String> values)? validator;
}

/// Formulário curto de conta: valida, envia e só fecha depois do sucesso.
class AccountFormPage extends StatefulWidget {
  const AccountFormPage({
    required this.title,
    required this.description,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String description;
  final List<AccountFormField> fields;
  final String submitLabel;
  final bool destructive;
  final Future<void> Function(Map<String, String> values) onSubmit;

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.fields)
      field.id: TextEditingController(text: field.initialValue),
  };
  var _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _values => {
    for (final entry in _controllers.entries) entry.key: entry.value.text,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lastField = widget.fields.last;

    return PopScope<Object?>(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: PageScrollView(
              padding: const EdgeInsets.fromLTRB(
                ZeloSpace.gutter,
                ZeloSpace.xs,
                ZeloSpace.gutter,
                ZeloSpace.xxl,
              ),
              children: [
                Text(
                  widget.description,
                  style: textTheme.bodyLarge?.copyWith(
                    color: ZeloColors.inkSoft,
                  ),
                ),
                const SizedBox(height: ZeloSpace.xl),
                if (_errorMessage case final message?) ...[
                  Semantics(
                    liveRegion: true,
                    child: InlineNotice(
                      key: const ValueKey('account-form-error'),
                      tone: NoticeTone.attention,
                      icon: Icons.error_outline,
                      message: message,
                    ),
                  ),
                  const SizedBox(height: ZeloSpace.md),
                ],
                for (final field in widget.fields) ...[
                  TextFormField(
                    key: ValueKey('account-field-${field.id}'),
                    controller: _controllers[field.id],
                    enabled: !_isSaving,
                    obscureText: field.obscure,
                    keyboardType: field.keyboardType,
                    autofillHints: field.autofillHints,
                    textInputAction: identical(field, lastField)
                        ? TextInputAction.done
                        : TextInputAction.next,
                    onFieldSubmitted: identical(field, lastField)
                        ? (_) => _submit()
                        : null,
                    decoration: InputDecoration(
                      labelText: field.label,
                      helperText: field.helperText,
                      prefixIcon: field.icon == null ? null : Icon(field.icon),
                    ),
                    validator: (value) =>
                        field.validator?.call(value ?? '', _values),
                  ),
                  const SizedBox(height: ZeloSpace.md),
                ],
                const SizedBox(height: ZeloSpace.xs),
                FilledButton(
                  key: const ValueKey('account-form-submit'),
                  style: widget.destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: ZeloColors.expiredRed,
                        )
                      : null,
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.submitLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      await widget.onSubmit(_values);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AccountException catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = error.message;
        });
      }
    }
  }
}

String? requiredField(String value, String message) =>
    value.trim().isEmpty ? message : null;
