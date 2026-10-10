import 'package:flutter/material.dart';

import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/brand_symbol.dart';
import '../../../core/widgets/page_layout.dart';
import '../../authentication/domain/authentication_service.dart';
import '../../reminders/application/reminder_controller.dart';
import '../../reminders/presentation/reminders_section.dart';
import 'profile_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({
    required this.onLogout,
    this.account = const SessionAccount.simulated(),
    this.isLoggingOut = false,
    this.onOpenProfile,
    this.reminders,
    super.key,
  });

  final Future<void> Function() onLogout;
  final SessionAccount account;
  final bool isLoggingOut;

  /// Abre o perfil; ausente no modo demonstração.
  final VoidCallback? onOpenProfile;

  /// Lembretes de validade; ausentes no modo demonstração.
  final ReminderController? reminders;

  static const simulatedDescription =
      'Esta versão demonstra a navegação e não representa uma conta real. '
      'Nenhum dado pessoal é exibido aqui.';
  static const connectedDescription =
      'Seus medicamentos e descartes ficam guardados na sua conta Zelo.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = account.simulated
        ? 'Sessão simulada'
        : (account.name ?? 'Conta Zelo');
    final detail = account.simulated ? null : account.email;

    return SafeArea(
      bottom: false,
      child: PageScrollView(
        children: [
          const PageHeader(title: 'Conta'),
          const SizedBox(height: ZeloSpace.xl),
          Card(
            child: InkWell(
              key: const ValueKey('open-profile'),
              onTap: onOpenProfile,
              child: Padding(
                padding: const EdgeInsets.all(ZeloSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileAvatar(
                      name: account.simulated ? null : account.name,
                      size: 52,
                    ),
                    const SizedBox(height: ZeloSpace.md),
                    Text(title, style: textTheme.titleLarge),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: textTheme.bodyMedium?.copyWith(
                          color: ZeloColors.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: ZeloSpace.xs),
                    Text(
                      account.simulated
                          ? simulatedDescription
                          : connectedDescription,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: ZeloSpace.md),
                    const Divider(),
                    const SizedBox(height: ZeloSpace.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            onOpenProfile == null
                                ? 'Meu perfil fica disponível ao entrar com '
                                      'uma conta Zelo.'
                                : 'Meu perfil',
                            style: onOpenProfile == null
                                ? textTheme.bodySmall
                                : textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          ),
                        ),
                        if (onOpenProfile != null)
                          const Icon(
                            Icons.chevron_right,
                            color: ZeloColors.inkMuted,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: ZeloSpace.xxl),
          if (reminders case final controller?)
            RemindersSection(controller: controller),
          const SectionHeader(title: 'Sobre'),
          const SizedBox(height: ZeloSpace.xs),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Sobre o Zelo'),
                  subtitle: Text(
                    'Projeto acadêmico da CESUCA para organizar medicamentos '
                    'e apoiar o descarte responsável.',
                  ),
                ),
                const Divider(indent: 56),
                const ListTile(
                  leading: Icon(Icons.health_and_safety_outlined),
                  title: Text('Aviso importante'),
                  subtitle: Text(
                    'O Zelo organiza informações e não substitui orientação '
                    'médica ou farmacêutica.',
                  ),
                ),
                const Divider(indent: 56),
                ListTile(
                  key: const ValueKey('licenses-tile'),
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Licenças de código aberto'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Zelo',
                    applicationIcon: const Padding(
                      padding: EdgeInsets.all(ZeloSpace.xs),
                      child: BrandSymbol(size: 48),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ZeloSpace.xxl),
          OutlinedButton.icon(
            key: const ValueKey('logout-button'),
            onPressed: isLoggingOut ? null : onLogout,
            icon: isLoggingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: const Text('Sair da conta'),
          ),
        ],
      ),
    );
  }
}
