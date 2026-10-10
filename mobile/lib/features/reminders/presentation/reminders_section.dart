import 'package:flutter/material.dart';

import '../../../core/formatting/dates.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/inline_notice.dart';
import '../../../core/widgets/page_layout.dart';
import '../application/reminder_controller.dart';
import '../domain/expiration_reminder_plan.dart';
import '../domain/reminder_service.dart';

/// Bloco "Lembretes" da Conta: avisos de validade (RF06).
class RemindersSection extends StatefulWidget {
  const RemindersSection({required this.controller, super.key});

  final ReminderController controller;

  static const offDescription =
      'Um aviso 30 dias antes, 7 dias antes e no dia do vencimento, às 9h.';
  static const onDescription =
      '30 dias antes, 7 dias antes e no dia, às 9h. Os avisos são gerados no '
      'próprio aparelho.';
  static const unsupportedDescription = 'Disponíveis no aplicativo Android.';
  static const blockedMessage =
      'As notificações do Zelo estão bloqueadas neste aparelho. Ative-as nas '
      'configurações para receber os avisos.';

  @override
  State<RemindersSection> createState() => _RemindersSectionState();
}

class _RemindersSectionState extends State<RemindersSection>
    with WidgetsBindingObserver {
  ReminderController get _controller => widget.controller;

  /// A permissão foi recusada agora há pouco (e não só bloqueada antes).
  var _justDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Voltar das configurações do sistema pode ter mudado a permissão.
    if (state == AppLifecycleState.resumed) {
      _controller.refreshPermission();
    }
  }

  Future<void> _toggle(bool value) async {
    final result = await _controller.setEnabled(value);
    if (!mounted) {
      return;
    }
    setState(() => _justDenied = value && result == ReminderPermission.denied);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (!_controller.isLoaded) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: 'Lembretes'),
            const SizedBox(height: ZeloSpace.xs),
            Card(
              child: _controller.isUnsupported
                  ? const ListTile(
                      key: ValueKey('reminders-unsupported'),
                      leading: Icon(Icons.notifications_off_outlined),
                      title: Text('Lembretes de validade'),
                      subtitle: Text(RemindersSection.unsupportedDescription),
                    )
                  : _Active(
                      controller: _controller,
                      showBlocked: _controller.isBlocked || _justDenied,
                      onToggle: _toggle,
                    ),
            ),
            const SizedBox(height: ZeloSpace.xxl),
          ],
        );
      },
    );
  }
}

class _Active extends StatelessWidget {
  const _Active({
    required this.controller,
    required this.showBlocked,
    required this.onToggle,
  });

  final ReminderController controller;
  final bool showBlocked;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final on = controller.isActive;
    final next = controller.next;

    return Column(
      children: [
        SwitchListTile(
          key: const ValueKey('reminders-switch'),
          secondary: const Icon(Icons.notifications_active_outlined),
          title: const Text('Avisar antes de vencer'),
          subtitle: Text(
            on
                ? RemindersSection.onDescription
                : RemindersSection.offDescription,
          ),
          value: on,
          onChanged: controller.isBusy ? null : onToggle,
        ),
        if (showBlocked)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ZeloSpace.md,
              0,
              ZeloSpace.md,
              ZeloSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const InlineNotice(
                  key: ValueKey('reminders-blocked'),
                  tone: NoticeTone.attention,
                  icon: Icons.notifications_off_outlined,
                  message: RemindersSection.blockedMessage,
                ),
                const SizedBox(height: ZeloSpace.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('reminders-open-settings'),
                    onPressed: controller.openSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Abrir configurações'),
                  ),
                ),
              ],
            ),
          ),
        if (on) ...[
          const Divider(indent: 56),
          ListTile(
            key: const ValueKey('reminders-next'),
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('Próximo aviso'),
            subtitle: Text(
              next == null
                  ? 'Nenhum aviso agendado. Cadastre medicamentos com '
                        'validade futura.'
                  : _describe(next),
            ),
          ),
          const Divider(indent: 56),
          ListTile(
            key: const ValueKey('reminders-test'),
            leading: const Icon(Icons.send_outlined),
            title: const Text('Enviar aviso de teste'),
            subtitle: const Text(
              'Mostra agora como o aviso aparece neste aparelho.',
            ),
            onTap: controller.sendTest,
          ),
        ],
      ],
    );
  }

  static String _describe(PlannedReminder reminder) {
    final hour = reminder.at.hour;
    return '${formatLongDate(reminder.at)}, às ${hour}h · '
        '${reminder.title.toLowerCase()}: ${reminder.body}';
  }
}
