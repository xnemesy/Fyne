import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/account_provider.dart';
import '../models/account.dart';

import 'package:lucide_icons/lucide_icons.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        title: Text("Il mio Portafoglio", style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: accountsAsync.when(
        data: (accounts) => accounts.isEmpty 
            ? _buildEmptyState(context)
            : _buildAccountList(accounts),
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4A6741))),
        error: (err, stack) => Center(child: Text("Errore: $err", style: const TextStyle(color: Color(0xFFD63031)))),
      ),
    );
  }

  Widget _buildAccountList(List<Account> accounts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return _buildBentoCard(context, account);
      },
    );
  }

  Widget _buildBentoCard(BuildContext context, Account account) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
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
                account.decryptedName ?? "Conto Bancario",
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const Icon(LucideIcons.landmark, color: Color(0xFF4A6741), size: 20),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            "SALDO DISPONIBILE",
            style: GoogleFonts.inter(
              letterSpacing: 2,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A).withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${account.decryptedBalance ?? "0.00"} ${account.currency}",
            style: GoogleFonts.lora(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Text(
                "ID CONTO: **** ${account.id.substring(account.id.length - 4)}",
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A1A1A).withOpacity(0.2),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(LucideIcons.checkCircle2, color: Color(0xFF4A6741), size: 14),
              const SizedBox(width: 4),
              Text(
                "Sincronizzato",
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.wallet, size: 64, color: const Color(0xFF1A1A1A).withOpacity(0.05)),
          const SizedBox(height: 24),
          Text(
            "Il tuo wallet è vuoto",
            style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A).withOpacity(0.4)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A6741),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text("COLLEGA ISTITUTO", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
}
