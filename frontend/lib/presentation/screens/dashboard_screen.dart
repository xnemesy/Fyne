import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/fyne_theme.dart';
import '../../providers/account_overview_provider.dart';
import 'wallet_screen.dart';
import 'insights_screen.dart';
import 'transactions_screen.dart';
import 'backup_screen.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/dashboard/account_carousel.dart';
import '../widgets/dashboard/balance_chart.dart';
import '../../providers/sync_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/master_key_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/storage_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Refresh dati e auto-sync all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountOverviewProvider.notifier).refresh();
      ref.read(syncProvider.notifier).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = ref.watch(accountOverviewProvider);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(overviewState),
          const WalletScreen(),
          const InsightsScreen(),
          const TransactionsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        
        
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.wallet),
            label: 'Conti',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.pieChart),
            label: 'Analisi',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.list),
            label: 'Movimenti',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(AccountOverviewState state) {
    if (state.error != null) {
      // Translate technical errors to user-friendly messages
      String userMessage;
      if (state.error!.contains('Master key') ||
          state.error!.contains('Vault')) {
        userMessage =
            'Il vault è in fase di inizializzazione. Riprova tra un momento.';
      } else if (state.error!.contains('repository') ||
          state.error!.contains('inizializzato')) {
        userMessage =
            'Il sistema si sta preparando. Riprova tra qualche secondo.';
      } else {
        userMessage = 'Si è verificato un problema nel caricamento dei dati.';
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty_rounded,
                  size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(
                userMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ref.read(accountOverviewProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    // SafeArea top: sì — protegge la notch iOS.
    // SafeArea bottom: no — gestiamo noi il padding con SliverPadding finale.
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Intestazione con saluto e pulsante sync ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildGreetingHeader(context),
            ),
          ),

          // ── Card patrimonio totale ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: _buildTotalBalanceCard(state),
            ),
          ),

          // ── Titolo sezione conti ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'I Tuoi Conti',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),

          // ── Carousel orizzontale dei conti (AccountCarousel) ─────────────
          // padding solo a sinistra: la card si affaccia sul bordo destro
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: AccountCarousel(),
            ),
          ),

          // ── Titolo sezione grafico ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: BalanceChart(),
            ),
          ),

          // ── Cash Flow mensile ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _buildCashFlowCard(state),
            ),
          ),

          // ── Azioni rapide ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _buildQuickActions(context),
            ),
          ),

          // ── Padding inferiore: home indicator iOS + margine extra ─────────
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    final syncState = ref.watch(syncProvider);
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Buongiorno';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 18) {
      greeting = 'Buon pomeriggio';
      greetingIcon = Icons.wb_cloudy_outlined;
    } else {
      greeting = 'Buonasera';
      greetingIcon = Icons.nights_stay_outlined;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(greetingIcon, color: FyneColors.forest, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  DateFormat('EEEE d MMMM', 'it_IT').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        // Pulsante di Sync
        IconButton(
          onPressed: syncState.isSyncing
              ? null
              : () => ref.read(syncProvider.notifier).sync(),
          icon: syncState.isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: FyneColors.forest),
                )
              : const Icon(LucideIcons.rotateCcw,
                  color: FyneColors.forest, size: 24),
          tooltip: 'Sincronizza ora',
        ),
        // DEBUG P0: Check Storage Button (ALWAYS VISIBLE)
        IconButton(
          icon: const Icon(Icons.bug_report, color: FyneColors.rust),
          onPressed: () async {
            final storage = ref.read(secureStorageProvider);
            final packageInfo = await PackageInfo.fromPlatform();
            final pass = await storage.read(key: 'fyne_auto_passphrase');
            final hash = await storage.read(key: 'fyne_seed_hash');
            final salt = await storage.read(key: 'fyne_vault_salt');
            final rsa = await storage.read(key: 'fyne_rsa_private_key');
            final allKeys = await storage.readAll();
            final masterKey = ref.read(masterKeyProvider);
            final mode =
                kDebugMode ? 'debug' : (kProfileMode ? 'profile' : 'release');
            final authStatus = ref.read(authProvider).status;

            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: FyneColors.ink,
                  title: Text('Storage & RAM Debug',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                    child: Text(
                      'RAM Status:\n'
                      '- MasterKey (RAM): ${masterKey != null ? '✅ LOADED' : '❌ NULL'}\n'
                      '- Is Unlocked (RAM): ${authStatus == AuthStatus.authenticated ? '✅ YES' : '❌ NO'}\n\n'
                      'Build Fingerprint:\n'
                      '- App: ${packageInfo.version}+${packageInfo.buildNumber}\n'
                      '- Mode: $mode\n'
                      '- Fingerprint: $_buildFingerprint\n\n'
                      'Secure Storage Keys:\n'
                      '- fyne_auto_passphrase: ${pass != null ? '✅ FOUND' : '❌ MISSING'}\n'
                      '- fyne_seed_hash: ${hash != null ? '✅ FOUND' : '❌ MISSING'}\n'
                      '- fyne_vault_salt: ${salt != null ? '✅ FOUND' : '❌ MISSING'}\n'
                      '- fyne_rsa_private_key: ${rsa != null ? '✅ FOUND' : '❌ MISSING'}\n\n'
                      'All Storage Keys:\n${allKeys.keys.join(', ')}',
                      style: GoogleFonts.sourceCodePro(
                          fontSize: 12, color: Colors.white70),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CHIUDI',
                          style: TextStyle(color: FyneColors.forest)),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTotalBalanceCard(AccountOverviewState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FyneColors.forest, FyneColors.forestDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FyneColors.forest.withValues(alpha: 0.3),
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
              const Text(
                'Patrimonio Totale',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${state.accounts.length} Conti',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatCurrency(state.totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                state.netCashFlow >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                color:
                    state.netCashFlow >= 0 ? FyneColors.gold : FyneColors.rust,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '${state.netCashFlow >= 0 ? '+' : ''}${_formatCurrency(state.netCashFlow)} questo mese',
                style: TextStyle(
                  color: state.netCashFlow >= 0
                      ? FyneColors.gold
                      : FyneColors.rust,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowCard(AccountOverviewState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync_alt, color: FyneColors.forest),
                const SizedBox(width: 12),
                Text(
                  'Cash Flow - ${DateFormat('MMMM yyyy', 'it_IT').format(DateTime.now())}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildCashFlowItem(
                    'Entrate',
                    state.monthlyIncome,
                    FyneColors.forest,
                    Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCashFlowItem(
                    'Uscite',
                    state.monthlyExpenses,
                    FyneColors.rust,
                    Icons.arrow_upward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowItem(
      String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Azioni Rapide',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Nuova Transazione',
                Icons.add_circle_outline,
                FyneColors.forest,
                () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddTransactionSheet(),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Backup',
                Icons.backup_outlined,
                FyneColors.amber,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BackupScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'it_IT',
      symbol: '€',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}
