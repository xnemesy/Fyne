import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/fyne_theme.dart';
import '../../providers/account_overview_provider.dart';
import '../../models/account.dart';

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
    // Refresh dati all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountOverviewProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = ref.watch(accountOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna dati',
            onPressed: () {
              ref.read(accountOverviewProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(accountOverviewProvider.notifier).refresh(),
        child: _selectedIndex == 0
            ? _buildHomeTab(overviewState)
            : _buildPlaceholderTab(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Conti',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analisi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Movimenti',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(AccountOverviewState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Caricamento dati...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: FyneColors.rust),
            const SizedBox(height: 16),
            Text(
              'Errore nel caricamento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(accountOverviewProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con saluto
          _buildGreetingHeader(context),
          const SizedBox(height: 24),

          // Card Overview Totale
          _buildTotalBalanceCard(state),
          const SizedBox(height: 24),

          // Cash Flow Card
          _buildCashFlowCard(state),
          const SizedBox(height: 24),

          // Accounts by Type
          _buildAccountsByTypeSection(state),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context) {
    final hour = DateTime.now().hour;
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
            color: FyneColors.forest.withOpacity(0.3),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
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
                state.netCashFlow >= 0 ? Icons.trending_up : Icons.trending_down,
                color: state.netCashFlow >= 0 ? FyneColors.gold : FyneColors.rust,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '${state.netCashFlow >= 0 ? '+' : ''}${_formatCurrency(state.netCashFlow)} questo mese',
                style: TextStyle(
                  color: state.netCashFlow >= 0 ? FyneColors.gold : FyneColors.rust,
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

  Widget _buildCashFlowItem(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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

  Widget _buildAccountsByTypeSection(AccountOverviewState state) {
    final groupedAccounts = <AccountType, List<AccountSummary>>{};
    
    for (final account in state.accounts) {
      groupedAccounts.putIfAbsent(account.type, () => []).add(account);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I Tuoi Conti',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...groupedAccounts.entries.map((entry) {
          final type = entry.key;
          final accounts = entry.value;
          final total = accounts.fold(0.0, (sum, a) => sum + a.balance);

          return _buildAccountTypeCard(type, accounts, total);
        }),
      ],
    );
  }

  Widget _buildAccountTypeCard(AccountType type, List<AccountSummary> accounts, double total) {
    final typeInfo = _getAccountTypeInfo(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: typeInfo['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(typeInfo['icon'], color: typeInfo['color']),
        ),
        title: Text(typeInfo['label']),
        subtitle: Text('${accounts.length} ${accounts.length == 1 ? 'conto' : 'conti'}'),
        trailing: Text(
          _formatCurrency(total),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: typeInfo['color'],
          ),
        ),
        children: accounts.map((acc) => _buildAccountListTile(acc)).toList(),
      ),
    );
  }

  Widget _buildAccountListTile(AccountSummary account) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(account.name),
      subtitle: Text(account.group),
      trailing: Text(
        _formatCurrency(account.balance),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: account.balance >= 0 ? FyneColors.forest : FyneColors.rust,
        ),
      ),
      onTap: () {
        // TODO: Navigate to account detail
      },
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
                  // TODO: Navigate to add transaction
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
                  // TODO: Navigate to backup
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildPlaceholderTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: FyneColors.inkLight),
          SizedBox(height: 16),
          Text('Sezione in costruzione'),
        ],
      ),
    );
  }

  Map<String, dynamic> _getAccountTypeInfo(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return {
          'label': 'Conti Correnti',
          'icon': Icons.account_balance,
          'color': FyneColors.forest,
        };
      case AccountType.savings:
        return {
          'label': 'Risparmi',
          'icon': Icons.savings_outlined,
          'color': FyneColors.gold,
        };
      case AccountType.credit:
        return {
          'label': 'Carte di Credito',
          'icon': Icons.credit_card,
          'color': FyneColors.rust,
        };
      case AccountType.investment:
        return {
          'label': 'Investimenti',
          'icon': Icons.trending_up,
          'color': FyneColors.amber,
        };
      case AccountType.loan:
        return {
          'label': 'Prestiti',
          'icon': Icons.attach_money,
          'color': FyneColors.rust,
        };
      case AccountType.cash:
        return {
          'label': 'Contanti',
          'icon': Icons.account_balance_wallet,
          'color': FyneColors.moss,
        };
      case AccountType.crypto:
        return {
          'label': 'Crypto',
          'icon': Icons.currency_bitcoin,
          'color': FyneColors.amber,
        };
    }
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
