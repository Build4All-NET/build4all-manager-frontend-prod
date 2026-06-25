import 'package:equatable/equatable.dart';

class ForgotPasswordState extends Equatable {
  final bool loading;
  final String? error; // toast this on UI if present
  final String? resetToken; // set after the OTP is verified
  final bool completed; // true after the password is reset

  const ForgotPasswordState({
    this.loading = false,
    this.error,
    this.resetToken,
    this.completed = false,
  });

  // Sentinel to allow "set to null" vs "don't change"
  static const Object _unset = Object();

  ForgotPasswordState copyWith({
    bool? loading,
    Object? error = _unset,
    Object? resetToken = _unset,
    bool? completed,
  }) {
    return ForgotPasswordState(
      loading: loading ?? this.loading,
      error: identical(error, _unset) ? this.error : error as String?,
      resetToken: identical(resetToken, _unset)
          ? this.resetToken
          : resetToken as String?,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [loading, error, resetToken, completed];
}

const ForgotPasswordInitial = ForgotPasswordState();
