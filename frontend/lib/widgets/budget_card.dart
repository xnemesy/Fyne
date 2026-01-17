import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart'; // Add this import
import 'decrypted_value.dart';

class BudgetCard extends StatelessWidget {
  final Budget? budget;
  final BudgetStatus? status; // Add status support

  const BudgetCard({super.key, this.budget, this.status});

  @override
  Widget build(BuildContext context) {
    final effectiveBudget = budget ?? status?.budget;
    final spent = status?.spent ?? effectiveBudget?.currentSpent ?? 0.0;
    final progress = status?.progress ?? (effectiveBudget != null && effectiveBudget.limitAmount > 0 ? (effectiveBudget.currentSpent / effectiveBudget.limitAmount) : 0.0);
    final isOver = status?.isOverBudget ?? (effectiveBudget != null && effectiveBudget.currentSpent > effectiveBudget.limitAmount);
    final remaining = status?.remaining ?? (effectiveBudget != null ? effectiveBudget.limitAmount - effectiveBudget.currentSpent : 0.0);

    if (effectiveBudget == null) return const SizedBox();

    final progressColor = isOver 
        ? const Color(0xFFD63031) // Terracotta-ish Red
        : const Color(0xFF4A6741); // Sage Green

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
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
                effectiveBudget.decryptedCategoryName ?? "Caricamento...",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              Text(
                "Limite: ${effectiveBudget.limitAmount.toStringAsFixed(0)} €",
                style: TextStyle(
                  color: Colors.black.withOpacity(0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF2F2F0),
              color: progressColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Spesi",
                    style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  DecryptedValue(
                    value: spent.toStringAsFixed(2),
                    style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOver ? "Eccesso" : "Disponibili",
                    style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  DecryptedValue(
                    value: remaining.abs().toStringAsFixed(2),
                    style: TextStyle(
                      color: isOver ? const Color(0xFFD63031) : const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
