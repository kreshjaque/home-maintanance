part of '../../main.dart';

class _HeroSummary extends ConsumerWidget {
  const _HeroSummary({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = _monthFormat.format(report.state.selectedMonth);
    final activeHouseCount = report.activeHouses.length;
    final shared = report.sharedTotal;
    final perHouse = activeHouseCount == 0 ? 0.0 : shared / activeHouseCount;
    final controller = ref.read(ledgerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_heroBackground, _paletteBlue, _paletteTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _paletteBlue.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Previous month',
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            controller.previousMonth();
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          month,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Next month',
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            controller.nextMonth();
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _money.format(report.monthTotal),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$activeHouseCount houses - ${_money.format(perHouse)} common share each',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: _heroMutedText),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Download PDF',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref.read(ledgerProvider.notifier).downloadPdf(context);
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MetricGrid(
            children: [
              _MetricChip(
                label: 'Common',
                value: _money.format(report.sharedTotal),
                icon: Icons.groups_2_outlined,
              ),
              _MetricChip(
                label: 'Specific',
                value: _money.format(report.specificTotal),
                icon: Icons.home_outlined,
              ),
              _MetricChip(
                label: 'Entries',
                value: '${report.monthExpenses.length}',
                icon: Icons.receipt_long_outlined,
              ),
              _MetricChip(
                label: 'Water',
                value: report.waterReadingText,
                icon: Icons.water_drop_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const spacing = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        final tileWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: _heroSoftText),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensePanel extends ConsumerWidget {
  const _ExpensePanel({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slices = report.categoryTotals.entries.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelHeader(
              title: 'Monthly expenses',
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              child: slices.isEmpty
                  ? const _EmptyState(
                      icon: Icons.add_chart_outlined,
                      title: 'No expenses this month',
                      message: 'Add an entry to build the monthly split.',
                    )
                  : RepaintBoundary(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 48,
                          sections: [
                            for (final entry in slices)
                              PieChartSectionData(
                                color: _categoryColor(entry.key),
                                value: entry.value,
                                radius: 56,
                                title: '',
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            for (final expense in report.monthExpensesSorted)
              Padding(
                key: ValueKey(expense.id),
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: _categoryColor(
                    expense.category,
                  ).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 12, right: 4),
                    leading: CircleAvatar(
                      backgroundColor: _categoryColor(
                        expense.category,
                      ).withValues(alpha: 0.16),
                      foregroundColor: _categoryColor(expense.category),
                      child: Icon(_categoryIcon(expense.category), size: 20),
                    ),
                    title: Text(
                      expense.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${_dateFormat.format(expense.date)} - ${expense.targetHouseId == null ? 'Shared' : report.state.houseName(expense.targetHouseId!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 2,
                      children: [
                        Text(
                          _money.format(expense.amount),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            showModalBottomSheet<void>(
                              context: context,
                              showDragHandle: true,
                              isScrollControlled: true,
                              useSafeArea: true,
                              backgroundColor: _appSurface,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (_) =>
                                  ExpenseFormSheet(expense: expense),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _confirmDeleteExpense(context, ref, expense);
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HousePanel extends ConsumerWidget {
  const _HousePanel({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelHeader(
              title: 'House-wise dues',
              icon: Icons.home_work_outlined,
            ),
            const SizedBox(height: 12),
            if (report.state.houses.isEmpty)
              const _EmptyState(
                icon: Icons.add_home_work_outlined,
                title: 'No houses yet',
                message: 'Add house names below to calculate each share.',
              )
            else
              for (final house in report.activeHouses) ...[
                _HouseDueTile(
                  house: house,
                  amount: report.allocations[house.id] ?? 0,
                  maxAmount: report.maxAllocation,
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _HouseDueTile extends StatelessWidget {
  const _HouseDueTile({
    required this.house,
    required this.amount,
    required this.maxAmount,
  });

  final House house;
  final double amount;
  final double maxAmount;

  @override
  Widget build(BuildContext context) {
    final progress = maxAmount <= 0
        ? 0.0
        : (amount / maxAmount).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _paletteTeal.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _paletteTeal.withValues(alpha: 0.14),
            foregroundColor: _paletteTeal,
            child: const Icon(Icons.holiday_village_outlined, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        house.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      _money.format(amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _paletteIndigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: _paletteTeal.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(_paletteTeal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _paletteBlue.withValues(alpha: 0.1),
            foregroundColor: _paletteBlue,
            child: Icon(icon),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _appMuted),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteExpense(
  BuildContext context,
  WidgetRef ref,
  ExpenseEntry expense,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete expense?'),
      content: Text(
        'Remove ${expense.category} (${_money.format(expense.amount)}) from this month?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref.read(ledgerProvider.notifier).deleteExpense(expense.id);
  }
}
