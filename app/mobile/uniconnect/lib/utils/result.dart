sealed class Result<T> {
  const Result();

  const factory Result.ok(T data) = Ok._;

  const factory Result.error(Object error, [StackTrace? stackTrace]) = Err._;

  R fold<R>(
    R Function(T data) onOk,
    R Function(Object error, StackTrace? stackTrace) onError,
  ) {
    return switch (this) {
      Ok(data: final value) => onOk(value),
      Err(error: final e, stackTrace: final s) => onError(e, s),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok._(this.data);

  final T data;
}

final class Err<T> extends Result<T> {
  const Err._(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return '$error\n';
  }
}
