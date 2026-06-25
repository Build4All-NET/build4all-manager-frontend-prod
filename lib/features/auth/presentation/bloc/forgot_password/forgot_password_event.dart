import 'package:equatable/equatable.dart';

sealed class ForgotPasswordEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Step 1: send a reset code to the account email
class ForgotPasswordSendOtp extends ForgotPasswordEvent {
  final String email;
  ForgotPasswordSendOtp(this.email);

  @override
  List<Object?> get props => [email];
}

/// Step 2: verify the 6-digit code and get a short-lived reset token
class ForgotPasswordVerifyOtp extends ForgotPasswordEvent {
  final String email;
  final String code; // 6 digits
  ForgotPasswordVerifyOtp(this.email, this.code);

  @override
  List<Object?> get props => [email, code];
}

/// Step 3: set the new password using the reset token
class ForgotPasswordSubmitNew extends ForgotPasswordEvent {
  final String resetToken;
  final String newPassword;
  ForgotPasswordSubmitNew(this.resetToken, this.newPassword);

  @override
  List<Object?> get props => [resetToken, newPassword];
}
