import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';

void main() {
  group('Result', () {
    test('Result.success returns data and folds correctly', () {
      const result = Result<Failure, String>.success('hello');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, 'hello');
      expect(result.error, isNull);

      final folded = result.fold(
        (failure) => 'failed',
        (data) => 'success: $data',
      );
      expect(folded, 'success: hello');
    });

    test('Result.failure returns error and folds correctly', () {
      const failure = ServerFailure('Server unreachable');
      const result = Result<Failure, String>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.data, isNull);
      expect(result.error, failure);

      final folded = result.fold(
        (f) => 'caught: ${f.message}',
        (data) => 'success',
      );
      expect(folded, 'caught: Server unreachable');
    });
  });
}
