import 'package:flutter/material.dart';

import '../domain/authentication_service.dart';
import 'auth_page_frame.dart';
import 'auth_validators.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({
    required this.authenticationService,
    required this.onBack,
    super.key,
  });

  final AuthenticationService authenticationService;
  final VoidCallback onBack;

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _requestCompleted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isLoading) {
          widget.onBack();
        }
      },
      child: AuthPageFrame(
        title: 'Recupere seu acesso',
        subtitle: 'Informe seu e-mail para continuar.',
        onBack: _isLoading ? null : widget.onBack,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_requestCompleted) ...[
                Semantics(
                  liveRegion: true,
                  child: Card(
                    key: const ValueKey('recovery-success-message'),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Se houver uma conta para este e-mail, as instruções '
                        'de recuperação serão apresentadas pelo serviço real '
                        'quando ele estiver disponível.',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_errorMessage case final message?) ...[
                AuthErrorMessage(message),
                const SizedBox(height: 16),
              ],
              TextFormField(
                key: const ValueKey('recovery-email-field'),
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('recovery-submit-button'),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Solicitar recuperação'),
              ),
              const SizedBox(height: 12),
              Text(
                'Nenhum e-mail real será enviado nesta versão simulada.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _requestCompleted = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _requestCompleted = false;
      _errorMessage = null;
    });
    try {
      await widget.authenticationService.requestPasswordReset(
        _emailController.text.trim(),
      );
      if (mounted) {
        setState(() => _requestCompleted = true);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Não foi possível concluir a solicitação. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
