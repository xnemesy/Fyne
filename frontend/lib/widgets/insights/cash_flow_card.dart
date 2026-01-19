
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CashFlowCard extends StatelessWidget {
  final double income;
  final double expenses;
  final double savings;
  final double savingsRate;

  const CashFlowCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.savings,
    required this.savingsRate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("FLUSSO DI CASSA (MESE CORRENTE)", 
          style: GoogleFonts.inter(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A).withOpacity(0.3))),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF4A6741),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _cashFlowItem("Entrate", income, Colors.white.withOpacity(0.7)),
                  _cashFlowItem("Uscite", expenses, Colors.white.withOpacity(0.7)),
                ],
              ),
              const SizedBox(height: 24),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final total = income + expenses;
                      if (total == 0) return const SizedBox();
                      final incomeWidth = constraints.maxWidth * (income / total);
                      return Container(
                        height: 8,
                        width: incomeWidth,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Risparmio: ${savings.toStringAsFixed(2)} €", 
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(income > 0 ? "${(savingsRate * 100).toStringAsFixed(0)}%" : "0%", 
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cashFlowItem(String label, double amount, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.inter(letterSpacing: 2, fontSize: 9, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 4),
        Text("${amount.toStringAsFixed(2)} €", style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
