import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/transaction.dart';

class FinancialInsightCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  const FinancialInsightCard({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    double incomings = 0;
    double outgoings = 0;
    final now = DateTime.now();

    for (var tx in transactions) {
      if (tx.bookingDate.month == now.month && tx.bookingDate.year == now.year) {
        if (tx.amount > 0) {
          incomings += tx.amount;
        } else {
          outgoings += tx.amount.abs();
        }
      }
    }

    final savingRate = incomings > 0 ? ((incomings - outgoings) / incomings * 100).toStringAsFixed(0) : "0";
    final isNegative = (incomings - outgoings) < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "REPORT MENSILE",
                style: GoogleFonts.inter(
                  letterSpacing: 1.5,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
              Icon(LucideIcons.sparkles, color: Colors.white.withOpacity(0.4), size: 14),
            ],
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem("Entrate", incomings),
              _infoItem("Uscite", outgoings),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isNegative ? "Scostamento rispetto al saldo ideale" : "Differenza del mese",
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${(incomings - outgoings).toStringAsFixed(2)} €",
                        style: GoogleFonts.lora(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$savingRate%",
                    style: GoogleFonts.inter(
                      color: isNegative ? const Color(0xFFD63031) : const Color(0xFF4A6741),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isNegative 
              ? "Questo mese le uscite superano le entrate. Controlla i tuoi budget per rientrare nei limiti."
              : "Ottimo lavoro! Stai risparmiando il $savingRate% delle tue entrate. Continua così.",
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.inter(letterSpacing: 1, fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.4))),
        const SizedBox(height: 4),
        Text("${amount.toStringAsFixed(2)} €", style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
