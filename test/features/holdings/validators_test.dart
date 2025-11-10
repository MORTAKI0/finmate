import 'package:flutter_test/flutter_test.dart';

bool _isNonNegative(String? s) {
  final v = (s ?? '').trim();
  if (v.isEmpty) return false;
  final n = num.tryParse(v);
  return n != null && n >= 0;
}

bool _isSymbolValid(String? s) {
  final v = (s ?? '').trim();
  return v.isNotEmpty;
}

void main() {
  test('quantity/costBasis must be >= 0', () {
    expect(_isNonNegative('0'), true);
    expect(_isNonNegative('12.34'), true);
    expect(_isNonNegative('-1'), false);
    expect(_isNonNegative(''), false);
  });

  test('symbol must be non-empty', () {
    expect(_isSymbolValid('BTC'), true);
    expect(_isSymbolValid(' usd '), true);
    expect(_isSymbolValid(''), false);
  });
}

