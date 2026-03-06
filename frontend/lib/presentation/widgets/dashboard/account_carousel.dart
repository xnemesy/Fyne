import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/fyne_theme.dart';
import '../../../models/account.dart';
import '../../../providers/account_overview_provider.dart';
import '../fyne_shimmer.dart';

/// Carousel orizzontale con PageView snapping che mostra una Card per ogni conto.
/// Gestisce i tre stati Riverpod: caricamento (Shimmer), errore e dati.
class AccountCarousel extends ConsumerStatefulWidget {
  const AccountCarousel({super.key});

  @override
  ConsumerState<AccountCarousel> createState() => _AccountCarouselState();
}

class _AccountCarouselState extends ConsumerState<AccountCarousel> {
  // viewportFraction < 1 lascia intravedere la card successiva (effetto peek)
  final PageController _controller = PageController(viewportFraction: 0.82);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountOverviewProvider);

    if (state.isLoading) {
      return _buildShimmer(context);
    }

    if (state.error != null) {
      return _buildError(context);
    }

    if (state.accounts.isEmpty) {
      return _buildEmpty(context);
    }

    return SizedBox(
      height: 195,
      child: PageView.builder(
        controller: _controller,
        // Fisica che simula lo snap elastico tipico delle app premium
        physics: const BouncingScrollPhysics(),
        itemCount: state.accounts.length,
        itemBuilder: (context, index) {
          return Padding(
            // Margine asimmetrico: crea separazione visiva tra le card
            padding: EdgeInsets.only(
              right: index < state.accounts.length - 1 ? 12 : 0,
            ),
            child: _AccountCard(account: state.accounts[index]),
          );
        },
      ),
    );
  }

  /// Placeholder Shimmer durante il caricamento dati
  Widget _buildShimmer(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.78;
    return SizedBox(
      height: 195,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          FyneShimmer(
            width: cardWidth,
            height: 195,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(width: 12),
          FyneShimmer(
            width: cardWidth * 0.25, // Peek parziale della seconda card
            height: 195,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }

  /// Messaggio di errore inline, non blocca l'intera Dashboard
  Widget _buildError(BuildContext context) {
    return Container(
      height: 195,
      decoration: BoxDecoration(
        color: FyneColors.rust.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FyneColors.rust.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, color: FyneColors.rust, size: 28),
            const SizedBox(height: 8),
            Text(
              'Impossibile caricare i conti',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: FyneColors.rust,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stato vuoto quando l'utente non ha ancora creato conti
  Widget _buildEmpty(BuildContext context) {
    return Container(
      height: 195,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FyneColors.forest.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.wallet, color: FyneColors.forest, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Nessun conto presente',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card singola del Carousel ────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final AccountSummary account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    // Placeholder per account con decifratura fallita
    if (account.isCorrupted) {
      return _buildLockedCard(context);
    }

    final info = _accountTypeInfo(account.type);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: info.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: info.gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Riga superiore: icona tipo + badge valuta
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FyneColors.paper.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(info.icon, color: FyneColors.paper, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FyneColors.paper.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  account.currency,
                  style: GoogleFonts.inter(
                    color: FyneColors.paper,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Etichetta tipo conto
          Text(
            info.label,
            style: GoogleFonts.inter(
              color: FyneColors.paper.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),

          // Nome del conto
          Text(
            account.name,
            style: GoogleFonts.inter(
              color: FyneColors.paper,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Saldo: font Lora per eleganza tipografica finanziaria
          Text(
            _formatCurrency(account.balance, account.currency),
            style: GoogleFonts.lora(
              color: FyneColors.paper,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Formatta il saldo con simbolo e locale italiani
  String _formatCurrency(double amount, String currency) {
    final symbol = currency == 'EUR' ? '€' : currency;
    return NumberFormat.currency(
      locale: 'it_IT',
      symbol: symbol,
      decimalDigits: 2,
    ).format(amount);
  }

  /// Placeholder per account con decifratura fallita (HMAC mismatch / vault locked).
  Widget _buildLockedCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FyneColors.rust.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FyneColors.rust.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.lock, color: FyneColors.rust, size: 28),
          const SizedBox(height: 12),
          Text(
            'Dato protetto\no non disponibile',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: FyneColors.rust,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Metadati per tipo di conto ───────────────────────────────────────────────

class _AccountTypeInfo {
  final String label;
  final IconData icon;
  final List<Color> gradientColors;

  const _AccountTypeInfo({
    required this.label,
    required this.icon,
    required this.gradientColors,
  });
}

_AccountTypeInfo _accountTypeInfo(AccountType type) {
  switch (type) {
    case AccountType.checking:
      return const _AccountTypeInfo(
        label: 'Conto Corrente',
        icon: LucideIcons.landmark,
        gradientColors: [FyneColors.forest, FyneColors.forestDark],
      );
    case AccountType.savings:
      return _AccountTypeInfo(
        label: 'Risparmi',
        icon: LucideIcons.piggyBank,
        gradientColors: [FyneColors.gold, FyneColors.goldDark],
      );
    case AccountType.credit:
      return const _AccountTypeInfo(
        label: 'Carta di Credito',
        icon: LucideIcons.creditCard,
        gradientColors: [FyneColors.rust, FyneColors.rustDark],
      );
    case AccountType.investment:
      return const _AccountTypeInfo(
        label: 'Investimenti',
        icon: LucideIcons.trendingUp,
        gradientColors: [FyneColors.amber, FyneColors.goldDark],
      );
    case AccountType.loan:
      return const _AccountTypeInfo(
        label: 'Prestito',
        icon: LucideIcons.receipt,
        gradientColors: [FyneColors.rustDark, FyneColors.maroon],
      );
    case AccountType.cash:
      return const _AccountTypeInfo(
        label: 'Contanti',
        icon: LucideIcons.banknote,
        gradientColors: [FyneColors.moss, FyneColors.forestDark],
      );
    case AccountType.crypto:
      return const _AccountTypeInfo(
        label: 'Crypto',
        icon: LucideIcons.bitcoin,
        gradientColors: [FyneColors.amber, FyneColors.amberDark],
      );
  }
}
