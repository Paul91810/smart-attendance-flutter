abstract class Result<L, R> {
  const Result();

  const factory Result.success(R value) = Success<L, R>;
  const factory Result.failure(L error) = FailureResult<L, R>;

  bool get isSuccess => this is Success<L, R>;
  bool get isFailure => this is FailureResult<L, R>;

  R? get data => isSuccess ? (this as Success<L, R>).value : null;
  L? get error => isFailure ? (this as FailureResult<L, R>).errorValue : null;

  T fold<T>(T Function(L failure) onFailure, T Function(R data) onSuccess) {
    final self = this;
    if (self is Success<L, R>) {
      return onSuccess(self.value);
    } else if (self is FailureResult<L, R>) {
      return onFailure(self.errorValue);
    }
    throw StateError('Unreachable: Result must be Success or FailureResult');
  }
}

class Success<L, R> extends Result<L, R> {
  final R value;
  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<L, R> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Result.success($value)';
}

class FailureResult<L, R> extends Result<L, R> {
  final L errorValue;
  const FailureResult(this.errorValue);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FailureResult<L, R> &&
          runtimeType == other.runtimeType &&
          errorValue == other.errorValue;

  @override
  int get hashCode => errorValue.hashCode;

  @override
  String toString() => 'Result.failure($errorValue)';
}
