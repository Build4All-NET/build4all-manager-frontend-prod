import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';

import 'package:build4all_manager/features/auth/domain/usecases/ForgotPasswordSendCode.dart';
import 'package:build4all_manager/features/auth/domain/usecases/ForgotPasswordVerifyCode.dart';
import 'package:build4all_manager/features/auth/domain/usecases/ForgotPasswordReset.dart';

import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ForgotPasswordSendCodeUseCase sendCode;
  final ForgotPasswordVerifyCodeUseCase verifyCode;
  final ForgotPasswordResetUseCase resetPassword;

  ForgotPasswordBloc(
    this.sendCode,
    this.verifyCode,
    this.resetPassword,
  ) : super(ForgotPasswordInitial) {
    on<ForgotPasswordSendOtp>(_onSendOtp);
    on<ForgotPasswordVerifyOtp>(_onVerifyOtp);
    on<ForgotPasswordSubmitNew>(_onSubmitNew);
  }

  Future<void> _onSendOtp(
      ForgotPasswordSendOtp e, Emitter<ForgotPasswordState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await sendCode(e.email);
      emit(state.copyWith(loading: false, error: null));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }

  Future<void> _onVerifyOtp(
      ForgotPasswordVerifyOtp e, Emitter<ForgotPasswordState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final token = await verifyCode(e.email, e.code);
      emit(state.copyWith(
        loading: false,
        resetToken: token,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }

  Future<void> _onSubmitNew(
      ForgotPasswordSubmitNew e, Emitter<ForgotPasswordState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await resetPassword(
        resetToken: e.resetToken,
        newPassword: e.newPassword,
      );
      emit(state.copyWith(
        loading: false,
        completed: true,
        error: null,
      ));
    } catch (err) {
      emit(state.copyWith(
        loading: false,
        error: ApiErrorHandler.message(err),
      ));
    }
  }
}
