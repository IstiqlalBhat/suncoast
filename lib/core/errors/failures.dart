sealed class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

final class AiFailure extends Failure {
  const AiFailure(super.message, {super.code});
}
