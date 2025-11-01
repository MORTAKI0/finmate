import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class SessionState extends Equatable {
  final AuthStatus status;
  final Session? session;
  final bool isLoading;
  final String? error;

  const SessionState({
    required this.status,
    this.session,
    this.isLoading = false,
    this.error,
  });

  factory SessionState.unknown() =>
      const SessionState(status: AuthStatus.unknown);
  factory SessionState.authenticated(Session s) =>
      SessionState(status: AuthStatus.authenticated, session: s);
  factory SessionState.unauthenticated() =>
      const SessionState(status: AuthStatus.unauthenticated);

  SessionState copyWith({
    AuthStatus? status,
    Session? session,
    bool? isLoading,
    String? error,
  }) =>
      SessionState(
        status: status ?? this.status,
        session: session ?? this.session,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  @override
  List<Object?> get props => [status, session?.user.id, isLoading, error];
}
