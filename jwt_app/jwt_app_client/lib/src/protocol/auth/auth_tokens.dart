/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// Pair of tokens returned on successful login.
abstract class AuthTokens implements _i1.SerializableModel {
  AuthTokens._({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens({
    required String accessToken,
    required String refreshToken,
  }) = _AuthTokensImpl;

  factory AuthTokens.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthTokens(
      accessToken: jsonSerialization['accessToken'] as String,
      refreshToken: jsonSerialization['refreshToken'] as String,
    );
  }

  /// Short-lived JWT used to authenticate API calls.
  String accessToken;

  /// Long-lived JWT used to obtain a fresh access token without re-logging in.
  String refreshToken;

  /// Returns a shallow copy of this [AuthTokens]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthTokens',
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AuthTokensImpl extends AuthTokens {
  _AuthTokensImpl({
    required String accessToken,
    required String refreshToken,
  }) : super._(
         accessToken: accessToken,
         refreshToken: refreshToken,
       );

  /// Returns a shallow copy of this [AuthTokens]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}
