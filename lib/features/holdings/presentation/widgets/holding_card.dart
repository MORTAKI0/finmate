import 'package:flutter/material.dart';
import '../../../holdings/domain/holding.dart';

const kCoralRed = Color(0xFFE63C3A);
const kBeige = Color(0xFFD6D4CE);
const kDarkBG = Color(0xFF1C1C1E);
const kMidGray = Color(0xFF91908D);
const kWhite = Colors.white;

class HoldingCard extends StatelessWidget {
  final Holding holding;
  final VoidCallback? onTap;
  const HoldingCard({super.key, required this.holding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
          ],
          border: Border.all(color: kDarkBG.withValues(alpha: 0.06)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E6E2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(holding.symbol.substring(0, 1), style: const TextStyle(color: kDarkBG, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${holding.type.toUpperCase()} · ${holding.symbol.toUpperCase()}',
                      style: const TextStyle(color: kDarkBG, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Qty ${holding.quantity} · Cost ${holding.costBasis}',
                      style: const TextStyle(color: kMidGray, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('—', style: TextStyle(color: kDarkBG, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                if (holding.pending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kCoralRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('Pending…', style: TextStyle(color: kCoralRed, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
