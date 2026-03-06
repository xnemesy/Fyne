import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/fyne_theme.dart';
import '../../models/account.dart';
import '../../services/crypto_price_service.dart';

final cryptoPriceProvider = FutureProvider.family<double?, Map<String, String>>((ref, params) async {
  final service = CryptoPriceService();
  return service.getPrice(params['id']!, params['currency']!);
});

class CryptoAccountCard extends ConsumerWidget {
  final Account account;
  const CryptoAccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (account.isCorrupted) return _buildCorruptedPlaceholder(context);

    // account.providerId acts as the CoinGecko ID
    final priceAsync = ref.watch(cryptoPriceProvider({'id': account.providerId ?? 'bitcoin', 'currency': 'eur'}));
    
    final quantity = double.tryParse(account.decryptedBalance ?? '0') ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FyneColors.paper, FyneColors.paperDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: FyneColors.ink.withValues(alpha:0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.decryptedName ?? "Crypto Wallet",
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Icon(LucideIcons.coins, color: FyneColors.forest, size: 20),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "CONTROVALORE STIMATO",
            style: GoogleFonts.inter(
              letterSpacing: 2,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.3),
            ),
          ),
          const SizedBox(height: 4),
          priceAsync.when(
            data: (price) {
              final totalValue = price != null ? quantity * price : 0.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${totalValue.toStringAsFixed(2)} €",
                    style: GoogleFonts.lora(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$quantity ${account.providerId?.toUpperCase() ?? 'BTC'} @ ${price?.toStringAsFixed(2) ?? '---'} €",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: FyneColors.forest,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(strokeWidth: 2, color: FyneColors.forest)
            ),
            error: (_, __) => Text("Errore prezzi", style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(LucideIcons.zap, color: FyneColors.forest, size: 14),
              const SizedBox(width: 4),
              Text(
                "Real-time CoinGecko",
                style: GoogleFonts.inter(
                  color: FyneColors.forest,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCorruptedPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: FyneColors.rust.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.lock, color: FyneColors.rust, size: 20),
          const SizedBox(width: 12),
          Text(
            "Dati non leggibili",
            style: GoogleFonts.inter(color: FyneColors.rust, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
