import 'package:flutter/material.dart';

import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/inline_notice.dart';
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
                  child: InlineNotice(
                    key: const ValueKey('recovery-success-message'),
                    tone: NoticeTone.positive,
                    icon: Icons.mark_email_read_outlined,
                    title: widget.authenticationService.isSimulated
                        ? 'Solicitação registrada'
                        : 'Verifique seu e-mail',
                    message: widget.authenticationService.isSimulated
                        ? 'Se houver uma conta para este e-mail, as instruções '
                              'de recuperação serão apresentadas pelo serviço '
                              'real quando ele estiver disponível.'
                        : 'Se houver uma conta para este e-mail, enviaremos '
                              'as instruções de recuperação.',
                  ),
                ),
                const SizedBox(height: ZeloSpace.md),
              ],
              if (_errorMessage case final message?) ...[
                AuthErrorMessage(message),
                const SizedBox(height: ZeloSpace.md),
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
              const SizedBox(height: ZeloSpace.lg),
              FilledButton(
                key: const ValueKey('recovery-submit-button'),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Solicitar recuperação'),
              ),
              const SizedBox(height: ZeloSpace.sm),
              if (widget.authenticationService.isSimulated)
                Text(
                  'Nenhum e-mail real será enviado nesta versão simulada.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (_requestCompleted &&
                  !widget.authenticationService.isSimulated)
                _ResetCodeForm(
                  authenticationService: widget.authenticationService,
                  onBackToLogin: widget.onBack,
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

/// Segunda etapa da recuperação: código recebido e nova senha.
class _ResetCodeForm extends StatefulWidget {
  const _ResetCodeForm({
    required this.authenticationService,
    required this.onBackToLogin,
  });

  final AuthenticationService authenticationService;
  final VoidCallback onBackToLogin;

  @override
  State<_ResetCodeForm> createState() => _ResetCodeFormState();
}

class _ResetCodeFormState extends State<_ResetCodeForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  var _isLoading = false;
  var _completed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return Padding(
        padding: const EdgeInsets.only(top: ZeloSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: const InlineNotice(
                key: ValueKey('reset-completed-message'),
                tone: NoticeTone.positive,
                icon: Icons.lock_reset_outlined,
                title: 'Senha alterada',
                message:
                    'Entre com a nova senha. Sessões anteriores foram '
                    'encerradas.',
              ),
            ),
            const SizedBox(height: ZeloSpace.md),
            FilledButton(
              onPressed: widget.onBackToLogin,
              child: const Text('Voltar para o login'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ZeloSpace.xl),
          const Divider(),
          const SizedBox(height: ZeloSpace.lg),
          Text(
            'Já recebeu o código?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ZeloSpace.md),
          if (_errorMessage case final message?) ...[
            AuthErrorMessage(message),
            const SizedBox(height: ZeloSpace.md),
          ],
          TextFormField(
            key: const ValueKey('reset-code-field'),
            controller: _codeController,
            enabled: !_isLoading,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Código de recuperação',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
            validator: (value) =>
                validateRequired(value, 'Informe o código recebido.'),
          ),
          const SizedBox(height: ZeloSpace.md),
          TextFormField(
            key: const ValueKey('reset-password-field'),
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Nova senha',
              helperText: 'Use pelo menos 8 caracteres.',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              final requiredError = validateRequired(
                value,
                'Informe a nova senha.',
              );
              if (requiredError != null) {
                return requiredError;
              }
              return value!.length < 8
                  ? 'A senha deve ter pelo menos 8 caracteres.'
                  : null;
            },
          ),
          const SizedBox(height: ZeloSpace.lg),
          FilledButton.tonal(
            key: const ValueKey('reset-confirm-button'),
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Criar nova senha'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await widget.authenticationService.confirmPasswordReset(
        code: _codeController.text,
        newPassword: _passwordController.text,
      );
      if (mounted) {
        setState(() => _completed = true);
      }
    } on AuthenticationFailure catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
