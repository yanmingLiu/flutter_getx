import 'vortex.dart';

sealed class VortexResult<T> {
  const VortexResult();
}

class Success<T> extends VortexResult<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends VortexResult<T> {
  final VortexException exception;
  const Failure(this.exception);
}
