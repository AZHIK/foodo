import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// App-wide sealed [Failure] type used across all layers.
///
/// Every use-case or repository returns [Failure] instead of throwing
/// exceptions, ensuring that call sites handle errors explicitly via
/// pattern matching.
@freezed
sealed class Failure with _$Failure {
  const Failure._();

  const factory Failure.network({String? message, int? statusCode}) = _Network;
  const factory Failure.validation({String? message}) = _Validation;
  const factory Failure.auth({String? message}) = _Auth;
  const factory Failure.unknown({String? message, Object? error}) = _Unknown;
}
