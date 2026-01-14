import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/account.dart';
import '../services/crypto_price_service.dart';

final cryptoPriceProvider = FutureProvider.family<double?, Map<String, String>>((ref, params) async {
  final service = CryptoPriceService();
  return service.getPrice(params['id']!, params['currency']!);
});

class CryptoAccountCard extends ConsumerWidget {
  final Account account;
  const CryptoAccountCard({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // account.providerId acts as the CoinGecko ID
    final priceAsync = ref.watch(cryptoPriceProvider({'id': account.providerId ?? 'bitcoin', 'currency': 'eur'}));
    
    final quantity = double.tryParse(account.decryptedBalance ?? '0') ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFF1F4F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const Icon(LucideIcons.coins, color: Color(0xFF4A6741), size: 20),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "CONTROVALORE STIMATO",
            style: GoogleFonts.inter(
              letterSpacing: 2,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A).withOpacity(0.3),
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
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$quantity ${account.providerId?.toUpperCase() ?? 'BTC'} @ ${price?.toStringAsFixed(2) ?? '---'} €",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF4A6741),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A6741))
            ),
            error: (_, __) => Text("Errore prezzi", style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(LucideIcons.zap, color: Color(0xFF4A6741), size: 14),
              const SizedBox(width: 4),
              Text(
                "Real-time CoinGecko",
                style: GoogleFonts.inter(
                  color: const Color(0xFF4A6741),
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
}
