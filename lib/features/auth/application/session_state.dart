import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class SessionState extends Equatable {
  final AuthStatus status;
  final Session? session;
  final bool isLoading;
  final String? error;

  /// one-shot flag to show “Session expirée” on Login after redirect
  final bool expiredNotice;

  const SessionState({
    required this.status,
    this.session,
    this.isLoading = false,
    this.error,
    this.expiredNotice = false,
  });

  factory SessionState.unknown() => const SessionState(status: AuthStatus.unknown);
  factory SessionState.authenticated(Session s) =>
      SessionState(status: AuthStatus.authenticated, session: s);
  factory SessionState.unauthenticated({bool expiredNotice = false}) =>
      SessionState(status: AuthStatus.unauthenticated, expiredNotice: expiredNotice);

  SessionState copyWith({
    AuthStatus? status,
    Session? session,
    bool? isLoading,
    String? error,
    bool? expiredNotice,
  }) =>
      SessionState(
        status: status ?? this.status,
        session: session ?? this.session,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        expiredNotice: expiredNotice ?? this.expiredNotice,
      );

  @override
  List<Object?> get props => [status, session?.user.id, isLoading, error, expiredNotice];
}
