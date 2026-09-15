import 'package:flutter/material.dart';

import '../domain/authentication_service.dart';
import 'auth_page_frame.dart';
import 'auth_validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.authenticationService,
    required this.onAuthenticated,
    required this.onRegister,
    required this.onRecoverPassword,
    super.key,
  });

  final AuthenticationService authenticationService;
  final VoidCallback onAuthenticated;
  final VoidCallback onRegister;
  final VoidCallback onRecoverPassword;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageFrame(
      title: 'Entre no Zelo',
      subtitle: 'Acesse sua farmácia doméstica.',
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
              key: const ValueKey('login-email-field'),
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('login-password-field'),
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  key: const ValueKey('login-password-visibility'),
                  onPressed: _isLoading
                      ? null
                      : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  tooltip: _obscurePassword ? 'Exibir senha' : 'Ocultar senha',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => validateRequired(value, 'Informe a senha.'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('recover-password-link'),
                onPressed: _isLoading ? null : widget.onRecoverPassword,
                child: const Text('Esqueci minha senha'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const ValueKey('login-submit-button'),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('demo-login-button'),
              onPressed: _isLoading ? null : _signInAsDemo,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Entrar como demonstração'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(child: Text('Ainda não tem uma conta?')),
                TextButton(
                  key: const ValueKey('register-link'),
                  onPressed: _isLoading ? null : widget.onRegister,
                  child: const Text('Cadastre-se'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await _runAuthentication(
      () => widget.authenticationService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _signInAsDemo() =>
      _runAuthentication(widget.authenticationService.signInAsDemo);

  Future<void> _runAuthentication(Future<void> Function() operation) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await operation();
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
          () =>
              _errorMessage = 'Não foi possível entrar agora. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
