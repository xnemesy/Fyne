import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class SubscriptionList extends StatelessWidget {
  final List<TransactionModel> transactions;

  const SubscriptionList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Filter for recurring subscriptions (mocking detection based on category)
    final subs = transactions
        .where((tx) => tx.categoryName == 'Abbonamenti')
        .toList();

    // Unique by description to avoid showing the same sub multiple times if we're just predicting
    final distinctSubs = <String, TransactionModel>{};
    for (var tx in subs) {
      if (tx.decryptedDescription != null) {
        distinctSubs[tx.decryptedDescription!] = tx;
      }
    }

    final displaySubs = distinctSubs.values.take(3).toList();

    if (displaySubs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            "ABBONAMENTI IN SCADENZA",
            style: GoogleFonts.inter(
              letterSpacing: 1.5,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A).withOpacity(0.3),
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: displaySubs.length,
            itemBuilder: (context, index) {
              final sub = displaySubs[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withOpacity(0.03)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.refreshCw, size: 14, color: Color(0xFF4A6741)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.decryptedDescription ?? "Subscription",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Previsto il 27", // Mocking prediction
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF1A1A1A).withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${sub.amount.abs().toStringAsFixed(2)} €",
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
