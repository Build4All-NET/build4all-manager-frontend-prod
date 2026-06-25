import 'package:build4all_manager/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/forgot_password/forgot_password_event.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/forgot_password/forgot_password_state.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/app_button.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _emailNode = FocusNode();

  bool _submitted = false;

  @override
  void dispose() {
    _email.dispose();
    _emailNode
      ..unfocus()
      ..dispose();
    super.dispose();
  }

  void _goBackToLogin() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/owner/login');
  }

  String? _emailValidator(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return l10n.errEmailRequired;
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
    if (!ok) return l10n.errEmailInvalid;
    return null;
  }

  void _submit(AppLocalizations l10n) {
    final form = _form.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _submitted = true);

    context
        .read<ForgotPasswordBloc>()
        .add(ForgotPasswordSendOtp(_email.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (p, c) => p.loading != c.loading || p.error != c.error,
      listener: (context, state) {
        if (state.error != null && state.error!.isNotEmpty) {
          AppToast.error(context, state.error!);
          return;
        }

        if (_submitted && state.loading == false) {
          _submitted = false;

          AppToast.success(context, l10n.msgCodeSent);

          context.push('/owner/forgot-password/otp', extra: {
            'email': _email.text.trim(),
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.forgotPasswordTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: _goBackToLogin,
              tooltip: l10n.common_back,
            ),
          ),
          body: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.forgotPasswordEmailSubtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: cs.outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _email,
                        focusNode: _emailNode,
                        label: l10n.lblEmail,
                        hint: l10n.hintEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        prefix: const Icon(Icons.mail_outline),
                        autofillHints: const [AutofillHints.email],
                        validator: (v) => _emailValidator(v, l10n),
                        onSubmitted: (_) => _submit(l10n),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: l10n.btnSendCode,
                        expand: true,
                        isBusy: state.loading,
                        trailing: const Icon(Icons.send_rounded),
                        onPressed: state.loading ? null : () => _submit(l10n),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
