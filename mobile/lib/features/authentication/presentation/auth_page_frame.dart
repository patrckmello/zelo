import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/brand_symbol.dart';
import '../../../core/widgets/inline_notice.dart';

/// Quadro das telas de entrada: símbolo, título alinhado à esquerda e
/// formulário com largura máxima legível.
class AuthPageFrame extends StatelessWidget {
  const AuthPageFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: onBack == null
          ? null
          : AppBar(
              leading: IconButton(
                onPressed: onBack,
                tooltip: 'Voltar',
                icon: const Icon(Icons.arrow_back),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            ZeloSpace.xl,
            onBack == null ? ZeloSpace.xxxl : ZeloSpace.xs,
            ZeloSpace.xl,
            ZeloSpace.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BrandSymbol(size: 56),
                  ),
                  const SizedBox(height: ZeloSpace.xl),
                  Semantics(
                    header: true,
                    child: Text(title, style: textTheme.headlineLarge),
                  ),
                  const SizedBox(height: ZeloSpace.xs),
                  Text(
                    subtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: ZeloColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: ZeloSpace.xxl),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: InlineNotice(
        key: const ValueKey('auth-error-message'),
        tone: NoticeTone.attention,
        icon: Icons.error_outline,
        message: message,
      ),
    );
  }
}

/// Divisor "ou" entre formas alternativas de entrada.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ZeloSpace.sm),
          child: Text('ou', style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
