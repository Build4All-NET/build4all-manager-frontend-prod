import 'package:build4all_manager/features/auth/domain/repositories/i_auth_repository.dart';

class ForgotPasswordSendCodeUseCase {
  final IAuthRepository repo;
  ForgotPasswordSendCodeUseCase(this.repo);
  Future<void> call(String email) =>
      repo.ownerForgotPasswordSendCode(email: email);
}
