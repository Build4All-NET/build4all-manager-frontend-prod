import 'package:build4all_manager/features/auth/domain/repositories/i_auth_repository.dart';

class ForgotPasswordResetUseCase {
  final IAuthRepository repo;
  ForgotPasswordResetUseCase(this.repo);
  Future<void> call({
    required String resetToken,
    required String newPassword,
  }) =>
      repo.ownerForgotPasswordReset(
        resetToken: resetToken,
        newPassword: newPassword,
      );
}
