import 'package:build4all_manager/features/auth/domain/entities/app_user.dart' show AppUser;
import 'package:build4all_manager/features/auth/domain/entities/auth_token.dart';

abstract class IAuthRepository {
  Future<(AuthToken, AppUser)> login({
    required String identifier,
    required String password,
  });

  Future<(AuthToken, AppUser)> reactivateAdminDeletion({
  required String identifier,
  required String password,
});

  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<String> getStoredRole();
  Future<bool> isSuperAdmin();

  Future<void> ownerSendOtp({required String email, required String password});

  Future<String> ownerVerifyOtp({
    required String email,
    required String password,
    required String code,
  });

  Future<void> ownerForgotPasswordSendCode({required String email});

  Future<String> ownerForgotPasswordVerifyCode({
    required String email,
    required String code,
  });

  Future<void> ownerForgotPasswordReset({
    required String resetToken,
    required String newPassword,
  });

  Future<(AuthToken, AppUser)> ownerCompleteProfile({
    required String registrationToken,
    required String username,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    int? countryId,
  });
}
