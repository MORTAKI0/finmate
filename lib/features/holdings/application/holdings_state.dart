import 'package:equatable/equatable.dart';
import '../../holdings/domain/holding.dart';

enum HoldingsStatus { initial, loading, loaded, saving, error }
enum HoldingsErrorKind { none, unauthorized, forbidden, duplicate, other }

class HoldingsState extends Equatable {
  final HoldingsStatus status;
  final List<Holding> items;
  final String? error;
  final HoldingsErrorKind errorKind;
  final String? conflictType;
  final String? conflictSymbol;

  const HoldingsState({
    required this.status,
    required this.items,
    this.error,
    this.errorKind = HoldingsErrorKind.none,
    this.conflictType,
    this.conflictSymbol,
  });

  factory HoldingsState.initial() => const HoldingsState(status: HoldingsStatus.initial, items: []);

  HoldingsState copyWith({
    HoldingsStatus? status,
    List<Holding>? items,
    String? error,
    HoldingsErrorKind? errorKind,
    String? conflictType,
    String? conflictSymbol,
  }) {
    return HoldingsState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error,
      errorKind: errorKind ?? this.errorKind,
      conflictType: conflictType,
      conflictSymbol: conflictSymbol,
    );
  }

  @override
  List<Object?> get props => [status, items, error, errorKind, conflictType, conflictSymbol];
}

