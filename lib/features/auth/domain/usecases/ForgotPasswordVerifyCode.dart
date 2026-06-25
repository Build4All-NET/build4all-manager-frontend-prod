import 'package:build4all_manager/features/auth/domain/repositories/i_auth_repository.dart';

class ForgotPasswordVerifyCodeUseCase {
  final IAuthRepository repo;
  ForgotPasswordVerifyCodeUseCase(this.repo);
  Future<String> call(String email, String code) =>
      repo.ownerForgotPasswordVerifyCode(email: email, code: code);
}
