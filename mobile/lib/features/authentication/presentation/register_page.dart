import 'package:flutter/material.dart';

import '../domain/authentication_service.dart';
import 'auth_page_frame.dart';
import 'auth_validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    required this.authenticationService,
    required this.onAuthenticated,
    required this.onBack,
    super.key,
  });

  final AuthenticationService authenticationService;
  final VoidCallback onAuthenticated;
  final VoidCallback onBack;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
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
        title: 'Crie sua conta',
        subtitle: 'Nesta etapa, o cadastro é apenas uma simulação local.',
        onBack: _isLoading ? null : widget.onBack,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage case final message?) ...[
                AuthErrorMessage(message),
                const SizedBox(height: 16),
              ],
              TextFormField(
                key: const ValueKey('register-name-field'),
                controller: _nameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    validateRequired(value, 'Informe o nome.'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('register-email-field'),
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('register-password-field'),
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Senha',
                  helperText: 'Use pelo menos 8 caracteres.',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    tooltip: _obscurePassword
                        ? 'Exibir senha'
                        : 'Ocultar senha',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  final requiredError = validateRequired(
                    value,
                    'Informe a senha.',
                  );
                  if (requiredError != null) {
                    return requiredError;
                  }
                  if (value!.length < 8) {
                    return 'A senha deve ter pelo menos 8 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('register-confirmation-field'),
                controller: _confirmationController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirme a senha',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
                validator: (value) {
                  final requiredError = validateRequired(
                    value,
                    'Confirme a senha.',
                  );
                  if (requiredError != null) {
                    return requiredError;
                  }
                  if (value != _passwordController.text) {
                    return 'As senhas não coincidem.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                key: const ValueKey('register-terms-checkbox'),
                value: _acceptedTerms,
                enabled: !_isLoading,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Li e aceito os termos de uso e a política de privacidade.',
                ),
                subtitle: _showTermsError
                    ? Text(
                        'O aceite é obrigatório para continuar.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    : null,
                onChanged: (value) => setState(() {
                  _acceptedTerms = value ?? false;
                  _showTermsError = false;
                }),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('register-submit-button'),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final formIsValid = _formKey.currentState!.validate();
    setState(() => _showTermsError = !_acceptedTerms);
    if (!formIsValid || !_acceptedTerms) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await widget.authenticationService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        widget.onAuthenticated();
      }
    } on AuthenticationFailure catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Não foi possível criar a conta agora. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
