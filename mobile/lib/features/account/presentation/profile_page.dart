import 'package:flutter/material.dart';

import '../../../core/formatting/dates.dart';
import '../../../core/theme/zelo_colors.dart';
import '../../../core/theme/zelo_tokens.dart';
import '../../../core/widgets/inline_notice.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../core/widgets/skeleton.dart';
import '../../authentication/presentation/auth_validators.dart';
import '../domain/account_service.dart';
import 'account_form_page.dart';

/// Meu perfil: dados pessoais, segurança, resumo dos dados e exclusão.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.service,
    required this.onProfileChanged,
    required this.onAccountDeleted,
    super.key,
  });

  final AccountService service;
  final ValueChanged<AccountProfile> onProfileChanged;
  final Future<void> Function() onAccountDeleted;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AccountProfile? _profile;
  String? _errorMessage;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: SafeArea(
        top: false,
        child: switch ((profile, _loading)) {
          (_, true) => const Padding(
            padding: EdgeInsets.all(ZeloSpace.gutter),
            child: SkeletonList(count: 2, label: 'Carregando perfil'),
          ),
          (null, false) => _LoadError(
            message: _errorMessage ?? 'Não foi possível carregar o perfil.',
            onRetry: _load,
          ),
          (final profile?, false) => _ProfileContent(
            profile: profile,
            onEditName: _editName,
            onChangeEmail: _changeEmail,
            onChangePassword: _changePassword,
            onDeleteAccount: _deleteAccount,
          ),
        },
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final profile = await widget.service.fetchProfile();
      if (mounted) {
        setState(() => _profile = profile);
      }
    } on AccountException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _apply(AccountProfile profile) {
    setState(() => _profile = profile);
    widget.onProfileChanged(profile);
  }

  Future<void> _editName() async {
    final saved = await _openForm(
      AccountFormPage(
        title: 'Alterar nome',
        description: 'Este é o nome exibido no Zelo.',
        submitLabel: 'Salvar nome',
        fields: [
          AccountFormField(
            id: 'name',
            label: 'Nome',
            initialValue: _profile?.name,
            icon: Icons.badge_outlined,
            autofillHints: const [AutofillHints.name],
            validator: (value, _) => requiredField(value, 'Informe o nome.'),
          ),
        ],
        onSubmit: (values) async =>
            _apply(await widget.service.updateName(values['name']!)),
      ),
    );
    _confirm(saved, 'Nome atualizado.');
  }

  Future<void> _changeEmail() async {
    final saved = await _openForm(
      AccountFormPage(
        title: 'Alterar e-mail',
        description:
            'O novo e-mail passa a ser usado para entrar e para recuperar o '
            'acesso. Confirme com a sua senha atual.',
        submitLabel: 'Salvar e-mail',
        fields: [
          AccountFormField(
            id: 'email',
            label: 'Novo e-mail',
            initialValue: _profile?.email,
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (value, _) => validateEmail(value),
          ),
          AccountFormField(
            id: 'password',
            label: 'Senha atual',
            obscure: true,
            icon: Icons.lock_outline,
            autofillHints: const [AutofillHints.password],
            validator: (value, _) =>
                requiredField(value, 'Informe a senha atual.'),
          ),
        ],
        onSubmit: (values) async => _apply(
          await widget.service.changeEmail(
            newEmail: values['email']!,
            currentPassword: values['password']!,
          ),
        ),
      ),
    );
    _confirm(saved, 'E-mail atualizado.');
  }

  Future<void> _changePassword() async {
    final saved = await _openForm(
      AccountFormPage(
        title: 'Alterar senha',
        description:
            'Depois da troca, as outras sessões abertas com esta conta são '
            'encerradas; este aparelho continua conectado.',
        submitLabel: 'Salvar nova senha',
        fields: [
          AccountFormField(
            id: 'current',
            label: 'Senha atual',
            obscure: true,
            icon: Icons.lock_outline,
            autofillHints: const [AutofillHints.password],
            validator: (value, _) =>
                requiredField(value, 'Informe a senha atual.'),
          ),
          AccountFormField(
            id: 'new',
            label: 'Nova senha',
            obscure: true,
            icon: Icons.lock_reset_outlined,
            helperText: 'Use pelo menos 8 caracteres.',
            autofillHints: const [AutofillHints.newPassword],
            validator: (value, values) {
              if (value.length < 8) {
                return 'A senha deve ter pelo menos 8 caracteres.';
              }
              return value == values['current']
                  ? 'A nova senha precisa ser diferente da atual.'
                  : null;
            },
          ),
          AccountFormField(
            id: 'confirmation',
            label: 'Confirme a nova senha',
            obscure: true,
            icon: Icons.lock_reset_outlined,
            validator: (value, values) =>
                value == values['new'] ? null : 'As senhas não coincidem.',
          ),
        ],
        onSubmit: (values) => widget.service.changePassword(
          currentPassword: values['current']!,
          newPassword: values['new']!,
        ),
      ),
    );
    _confirm(saved, 'Senha alterada. As outras sessões foram encerradas.');
  }

  Future<void> _deleteAccount() async {
    final deleted = await _openForm(
      AccountFormPage(
        title: 'Excluir conta',
        description:
            'Esta ação remove definitivamente sua conta, seus medicamentos e '
            'o histórico de descartes do Zelo. Não é possível desfazer.',
        submitLabel: 'Excluir conta e dados',
        destructive: true,
        fields: [
          AccountFormField(
            id: 'password',
            label: 'Senha atual',
            obscure: true,
            icon: Icons.lock_outline,
            autofillHints: const [AutofillHints.password],
            validator: (value, _) =>
                requiredField(value, 'Informe a senha para confirmar.'),
          ),
        ],
        onSubmit: (values) =>
            widget.service.deleteAccount(currentPassword: values['password']!),
      ),
    );
    if (deleted == true && mounted) {
      await widget.onAccountDeleted();
    }
  }

  Future<bool?> _openForm(Widget page) =>
      Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => page));

  void _confirm(bool? saved, String message) {
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onEditName,
    required this.onChangeEmail,
    required this.onChangePassword,
    required this.onDeleteAccount,
  });

  final AccountProfile profile;
  final VoidCallback onEditName;
  final VoidCallback onChangeEmail;
  final VoidCallback onChangePassword;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final medications = profile.medicationsCount == 1
        ? '1 medicamento ativo'
        : '${profile.medicationsCount} medicamentos ativos';
    final disposals = profile.disposalsCount == 1
        ? '1 descarte registrado'
        : '${profile.disposalsCount} descartes registrados';

    return PageScrollView(
      padding: const EdgeInsets.fromLTRB(
        ZeloSpace.gutter,
        ZeloSpace.xs,
        ZeloSpace.gutter,
        ZeloSpace.xxl,
      ),
      children: [
        Center(child: ProfileAvatar(name: profile.name, size: 72)),
        const SizedBox(height: ZeloSpace.md),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: ZeloSpace.xxs),
        Text(
          'No Zelo desde ${formatFullDate(profile.createdAt)}',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: ZeloSpace.xxl),
        const SectionHeader(title: 'Dados pessoais'),
        const SizedBox(height: ZeloSpace.xs),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('profile-name-tile'),
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Nome'),
                subtitle: Text(profile.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: onEditName,
              ),
              const Divider(indent: 56),
              ListTile(
                key: const ValueKey('profile-email-tile'),
                leading: const Icon(Icons.alternate_email),
                title: const Text('E-mail'),
                subtitle: Text(profile.email),
                trailing: const Icon(Icons.chevron_right),
                onTap: onChangeEmail,
              ),
            ],
          ),
        ),
        const SizedBox(height: ZeloSpace.xl),
        const SectionHeader(title: 'Segurança'),
        const SizedBox(height: ZeloSpace.xs),
        Card(
          child: ListTile(
            key: const ValueKey('profile-password-tile'),
            leading: const Icon(Icons.lock_outline),
            title: const Text('Senha'),
            subtitle: const Text('Altere a senha e encerre outras sessões.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onChangePassword,
          ),
        ),
        const SizedBox(height: ZeloSpace.xl),
        const SectionHeader(title: 'Seus dados'),
        const SizedBox(height: ZeloSpace.xs),
        InlineNotice(
          icon: Icons.inventory_2_outlined,
          title: '$medications · $disposals',
          message:
              'Ficam guardados na sua conta Zelo e são excluídos junto com '
              'ela.',
        ),
        const SizedBox(height: ZeloSpace.xxl),
        OutlinedButton.icon(
          key: const ValueKey('delete-account-button'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ZeloColors.expiredInk,
            side: const BorderSide(color: Color(0xFFE5C3C3)),
          ),
          onPressed: onDeleteAccount,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Excluir conta e dados'),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PageScrollView(
      children: [
        InlineNotice(
          tone: NoticeTone.attention,
          icon: Icons.error_outline,
          message: message,
        ),
        const SizedBox(height: ZeloSpace.md),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}

/// Iniciais do nome em um círculo, sem foto nem dados inventados.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.name, this.size = 48, super.key});

  final String? name;
  final double size;

  String get _initials {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '';
    }
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: ZeloColors.petroleumTint,
          shape: BoxShape.circle,
        ),
        child: initials.isEmpty
            ? Icon(
                Icons.person_outline,
                color: ZeloColors.onPetroleumTint,
                size: size * 0.5,
              )
            : Text(
                initials,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ZeloColors.onPetroleumTint,
                  fontSize: size * 0.36,
                ),
              ),
      ),
    );
  }
}
