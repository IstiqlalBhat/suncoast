sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(String message, {String? code}) = Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, String? code) failure,
  });

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>() => null,
  };
}

final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, String? code) failure,
  }) => success(data);
}

final class Failure<T> extends Result<T> {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, String? code) failure,
  }) => failure(message, code);
}
