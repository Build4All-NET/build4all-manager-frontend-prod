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

class ForgotPasswordResetScreen extends StatefulWidget {
  final String resetToken;

  const ForgotPasswordResetScreen({
    super.key,
    required this.resetToken,
  });

  @override
  State<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends State<ForgotPasswordResetScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _pwNode = FocusNode();
  final _confirmNode = FocusNode();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _pwNode
      ..unfocus()
      ..dispose();
    _confirmNode
      ..unfocus()
      ..dispose();
    super.dispose();
  }

  void _goToLogin() => context.go('/owner/login');

  String? _passwordValidator(String? v, AppLocalizations l10n) {
    final val = (v ?? '').trim();
    if (val.isEmpty) return l10n.errPasswordRequired;
    // ONLY RULE: at least 6 characters (matches owner registration rule).
    if (val.length < 6) return l10n.hintPasswordRuleOwner;
    return null;
  }

  String? _confirmValidator(String? v, AppLocalizations l10n) {
    if (v == null || v.isEmpty) return l10n.errConfirmPasswordRequired;
    if (v != _password.text) return l10n.errPasswordsDoNotMatch;
    return null;
  }

  void _submit(AppLocalizations l10n) {
    final form = _form.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    FocusScope.of(context).unfocus();

    context.read<ForgotPasswordBloc>().add(
          ForgotPasswordSubmitNew(widget.resetToken, _password.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (p, c) => p.error != c.error || p.completed != c.completed,
      listener: (context, state) {
        if (state.error != null && state.error!.isNotEmpty) {
          AppToast.error(context, state.error!);
          return;
        }

        if (state.completed) {
          AppToast.success(context, l10n.msgPasswordResetSuccess);
          _goToLogin();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
          body: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppPasswordField(
                          controller: _password,
                          focusNode: _pwNode,
                          label: l10n.lblNewPassword,
                          hint: l10n.hintNewPassword,
                          prefix: const Icon(Icons.lock_outline),
                          textInputAction: TextInputAction.next,
                          validator: (v) => _passwordValidator(v, l10n),
                          onSubmitted: (_) => _confirmNode.requestFocus(),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.hintPasswordRuleOwner,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppPasswordField(
                          controller: _confirm,
                          focusNode: _confirmNode,
                          label: l10n.lblConfirmPassword,
                          hint: l10n.hintConfirmPassword,
                          prefix: const Icon(Icons.lock_outline),
                          textInputAction: TextInputAction.done,
                          validator: (v) => _confirmValidator(v, l10n),
                          onSubmitted: (_) => _submit(l10n),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: l10n.btnResetPassword,
                          isBusy: state.loading,
                          expand: true,
                          trailing: const Icon(Icons.check_circle_rounded),
                          onPressed:
                              state.loading ? null : () => _submit(l10n),
                        ),
                      ],
                    ),
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
