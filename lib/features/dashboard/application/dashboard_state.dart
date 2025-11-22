import 'package:equatable/equatable.dart';
import '../../holdings/domain/holding.dart';

class DashboardState extends Equatable {
  final bool loading;
  final String? userEmail;
  final int holdingsCount;
  final int pendingOpsCount;
  final DateTime? lastUpdated;
  final String? error;
  final double? totalHoldingsCost;
  final double cryptoHoldingsCost;
  final double cashHoldingsCost;
  final int cryptoHoldingsCount;
  final int cashHoldingsCount;

  const DashboardState({
    required this.loading,
    this.userEmail,
    this.holdingsCount = 0,
    this.pendingOpsCount = 0,
    this.lastUpdated,
    this.error,
    this.totalHoldingsCost,
    this.cryptoHoldingsCost = 0,
    this.cashHoldingsCost = 0,
    this.cryptoHoldingsCount = 0,
    this.cashHoldingsCount = 0,
  });

  factory DashboardState.initial() => const DashboardState(loading: true);

  DashboardState copyWith({
    bool? loading,
    String? userEmail,
    int? holdingsCount,
    int? pendingOpsCount,
    DateTime? lastUpdated,
    String? error,
    double? totalHoldingsCost,
    double? cryptoHoldingsCost,
    double? cashHoldingsCost,
    int? cryptoHoldingsCount,
    int? cashHoldingsCount,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      userEmail: userEmail ?? this.userEmail,
      holdingsCount: holdingsCount ?? this.holdingsCount,
      pendingOpsCount: pendingOpsCount ?? this.pendingOpsCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error,
      totalHoldingsCost: totalHoldingsCost ?? this.totalHoldingsCost,
      cryptoHoldingsCost: cryptoHoldingsCost ?? this.cryptoHoldingsCost,
      cashHoldingsCost: cashHoldingsCost ?? this.cashHoldingsCost,
      cryptoHoldingsCount: cryptoHoldingsCount ?? this.cryptoHoldingsCount,
      cashHoldingsCount: cashHoldingsCount ?? this.cashHoldingsCount,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        userEmail,
        holdingsCount,
        pendingOpsCount,
        lastUpdated,
        error,
        totalHoldingsCost,
        cryptoHoldingsCost,
        cashHoldingsCost,
        cryptoHoldingsCount,
        cashHoldingsCount,
      ];
}
