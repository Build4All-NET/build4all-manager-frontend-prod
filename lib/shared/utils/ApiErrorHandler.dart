import '../../core/network/dio_error_mapper.dart';
import '../../core/exceptions/auth_failure.dart';

class ApiErrorHandler {
  static String message(Object error) {
    // Repositories wrap backend errors into AuthFailure (which already
    // carries the resolved backend message). DioErrorMapper only understands
    // DioException and would otherwise fall back to a generic message, so
    // surface the AuthFailure message directly.
    if (error is AuthFailure && error.message.trim().isNotEmpty) {
      return error.message.trim();
    }
    return DioErrorMapper.toUserMessage(error);
  }
}