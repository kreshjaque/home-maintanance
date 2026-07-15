part of '../../main.dart';

class LedgerHomePage extends ConsumerWidget {
  const LedgerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(ledgerProvider);
    return ledger.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Could not load data: $error'))),
      data: (state) => DashboardShell(state: state),
    );
  }
}

class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.state});

  final LedgerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(ledgerProvider.notifier);
    final report = MonthlyReport.from(state);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Maintenance'),
        actions: [
          IconButton(
            tooltip: 'Import backup',
            onPressed: () => controller.importBackup(context),
            icon: const Icon(Icons.upload_file_outlined),
          ),
          IconButton(
            tooltip: 'Export backup',
            onPressed: () => controller.exportBackup(context),
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Share PDF',
            onPressed: () => controller.sharePdf(context),
            icon: const Icon(Icons.ios_share_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.selectionClick();
          _showExpenseSheet(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                _HeroSummary(report: report),
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: _ExpensePanel(report: report)),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: _HousePanel(report: report)),
                    ],
                  )
                else ...[
                  _ExpensePanel(report: report),
                  const SizedBox(height: 16),
                  _HousePanel(report: report),
                ],
                const SizedBox(height: 16),
                _SetupPanel(houses: report.activeHouses),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showExpenseSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ExpenseFormSheet(),
    );
  }
}
