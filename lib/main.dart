import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const HomeMaintenanceApp());
}

const _uuid = Uuid();
final _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: 'Rs ',
  decimalDigits: 0,
);
final _monthFormat = DateFormat('MMMM yyyy');
final _dateFormat = DateFormat('dd MMM yyyy');
final _decimal = NumberFormat.decimalPattern('en_IN');
final _percent = NumberFormat.percentPattern('en_IN');

const _paletteIndigo = Color(0xff453db2);
const _paletteBlue = Color(0xff007ad1);
const _paletteTeal = Color(0xff009f88);
const _paletteGreen = Color(0xff51b302);
const _paletteAmber = Color(0xffffa600);
const _appPrimary = _paletteBlue;
const _appSecondary = _paletteTeal;
const _appSurface = Color(0xfff5fbfa);
const _heroBackground = _paletteIndigo;
const _heroSoftText = Color(0xffe7e5ff);
const _heroMutedText = Color(0xfff0f8ff);

final ledgerProvider = AsyncNotifierProvider<LedgerController, LedgerState>(
  LedgerController.new,
);

class HomeMaintenanceApp extends StatelessWidget {
  const HomeMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Home Maintenance',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _appPrimary,
            brightness: Brightness.light,
          ).copyWith(primary: _appPrimary, secondary: _appSecondary),
          scaffoldBackgroundColor: _appSurface,
          cardTheme: const CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        home: const LedgerHomePage(),
      ),
    );
  }
}

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
    final activeHouses = state.houses.where((house) => house.active).toList();
    final allocations = state.allocations;

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
        onPressed: () => _showExpenseSheet(context),
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
                _HeroSummary(state: state),
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: _ExpensePanel(state: state)),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _HousePanel(
                          state: state,
                          allocations: allocations,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _ExpensePanel(state: state),
                  const SizedBox(height: 16),
                  _HousePanel(state: state, allocations: allocations),
                ],
                const SizedBox(height: 16),
                _SetupPanel(houses: activeHouses),
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
      builder: (_) => const ExpenseFormSheet(),
    );
  }
}

class _HeroSummary extends ConsumerWidget {
  const _HeroSummary({required this.state});

  final LedgerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = _monthFormat.format(state.selectedMonth);
    final activeHouseCount = state.houses.where((house) => house.active).length;
    final shared = state.sharedTotal;
    final perHouse = activeHouseCount == 0 ? 0.0 : shared / activeHouseCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _heroBackground,
        borderRadius: BorderRadius.circular(8),
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
                    Text(
                      month,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: _heroSoftText),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _money.format(state.monthTotal),
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
                onPressed: () =>
                    ref.read(ledgerProvider.notifier).downloadPdf(context),
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(
                label: 'Common',
                value: _money.format(state.sharedTotal),
              ),
              _MetricChip(
                label: 'Specific',
                value: _money.format(state.specificTotal),
              ),
              _MetricChip(
                label: 'Entries',
                value: '${state.monthExpenses.length}',
              ),
              _MetricChip(label: 'Water', value: state.waterReadingText),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
  const _ExpensePanel({required this.state});

  final LedgerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slices = state.categoryTotals.entries.toList();
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
                  ? const Center(
                      child: Text(
                        'Add the first expense to see the category mix.',
                      ),
                    )
                  : PieChart(
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
            const SizedBox(height: 8),
            for (final expense in state.monthExpenses.sortedByCompare(
              (e) => e.date,
              (a, b) => b.compareTo(a),
            ))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _categoryColor(
                    expense.category,
                  ).withValues(alpha: 0.16),
                  foregroundColor: _categoryColor(expense.category),
                  child: Icon(_categoryIcon(expense.category), size: 20),
                ),
                title: Text(expense.category),
                subtitle: Text(
                  '${_dateFormat.format(expense.date)} - ${expense.targetHouseId == null ? 'Shared' : state.houseName(expense.targetHouseId!)}',
                ),
                trailing: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      _money.format(expense.amount),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        builder: (_) => ExpenseFormSheet(expense: expense),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => ref
                          .read(ledgerProvider.notifier)
                          .deleteExpense(expense.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HousePanel extends ConsumerWidget {
  const _HousePanel({required this.state, required this.allocations});

  final LedgerState state;
  final Map<String, double> allocations;

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
            if (state.houses.isEmpty)
              const Text('Add house names below to calculate each share.')
            else
              for (final house in state.houses.where((house) => house.active))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.14),
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                    child: const Icon(Icons.home_outlined, size: 20),
                  ),
                  title: Text(house.name),
                  trailing: Text(
                    _money.format(allocations[house.id] ?? 0),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SetupPanel extends ConsumerStatefulWidget {
  const _SetupPanel({required this.houses});

  final List<House> houses;

  @override
  ConsumerState<_SetupPanel> createState() => _SetupPanelState();
}

class _SetupPanelState extends ConsumerState<_SetupPanel> {
  final _houseController = TextEditingController();

  @override
  void dispose() {
    _houseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelHeader(
              title: 'House setup',
              icon: Icons.maps_home_work_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _houseController,
                    decoration: const InputDecoration(
                      labelText: 'House name',
                      hintText: 'A1, Villa 3, Krishna Home',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () {
                    final name = _houseController.text.trim();
                    if (name.isEmpty) return;
                    ref.read(ledgerProvider.notifier).addHouse(name);
                    _houseController.clear();
                  },
                  icon: const Icon(Icons.add_home_outlined),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final house in widget.houses)
                  InputChip(
                    label: Text(house.name),
                    onDeleted: () =>
                        ref.read(ledgerProvider.notifier).removeHouse(house.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseFormSheet extends ConsumerStatefulWidget {
  const ExpenseFormSheet({super.key, this.expense});

  final ExpenseEntry? expense;

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final _amountController = TextEditingController();
  final _readingController = TextEditingController();
  final _noteController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _previousReadingControllers = <String, TextEditingController>{};
  final _currentReadingControllers = <String, TextEditingController>{};
  DateTime _date = DateTime.now();
  String _category = defaultCategories.first;
  String? _targetHouseId;
  bool _waterUsageBased = false;

  bool get _isEditing => widget.expense != null;

  String get _effectiveCategory {
    final customCategory = _customCategoryController.text.trim();
    return customCategory.isEmpty ? _category : customCategory;
  }

  bool get _isWaterEntry => _isWaterCategory(_effectiveCategory);

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense == null) {
      return;
    }
    _date = expense.date;
    _category = defaultCategories.contains(expense.category)
        ? expense.category
        : defaultCategories.last;
    _targetHouseId = expense.targetHouseId;
    _waterUsageBased = expense.waterUsageBased;
    _amountController.text = expense.amount.toStringAsFixed(
      expense.amount.truncateToDouble() == expense.amount ? 0 : 2,
    );
    _readingController.text = expense.waterMeterReading?.toString() ?? '';
    _noteController.text = expense.note;
    if (!defaultCategories.contains(expense.category)) {
      _customCategoryController.text = expense.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _readingController.dispose();
    _noteController.dispose();
    _customCategoryController.dispose();
    for (final controller in _previousReadingControllers.values) {
      controller.dispose();
    }
    for (final controller in _currentReadingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerProvider).value;
    final houses = state?.houses.where((house) => house.active).toList() ?? [];
    _ensureWaterReadingControllers(houses, state);
    final categories = {
      ...defaultCategories,
      ...?state?.customCategories,
    }.toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit maintenance entry' : 'Add maintenance entry',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in categories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) => setState(() {
                _category = value ?? _category;
                if (!_isWaterEntry) {
                  _waterUsageBased = false;
                }
              }),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customCategoryController,
              onChanged: (_) => setState(() {
                if (!_isWaterEntry) {
                  _waterUsageBased = false;
                }
              }),
              decoration: const InputDecoration(
                labelText: 'Custom category',
                hintText: 'Use this for misc expenses',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'Rs ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _readingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Water meter reading',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (_isWaterEntry) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('External source water'),
                subtitle: const Text(
                  'Split by each house meter usage instead of equally.',
                ),
                value: _waterUsageBased,
                onChanged: (value) => setState(() {
                  _waterUsageBased = value;
                  if (value) {
                    _targetHouseId = null;
                  }
                }),
              ),
              if (_waterUsageBased) ...[
                const SizedBox(height: 8),
                _WaterReadingInputs(
                  houses: houses,
                  previousReadingControllers: _previousReadingControllers,
                  currentReadingControllers: _currentReadingControllers,
                ),
                const SizedBox(height: 10),
              ],
            ],
            if (!_waterUsageBased)
              DropdownButtonFormField<String?>(
                initialValue: _targetHouseId,
                decoration: const InputDecoration(
                  labelText: 'Split type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Shared by all active houses'),
                  ),
                  for (final house in houses)
                    DropdownMenuItem<String?>(
                      value: house.id,
                      child: Text('Specific to ${house.name}'),
                    ),
                ],
                onChanged: (value) => setState(() => _targetHouseId = value),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _date = picked;
                    _populatePreviousReadings(houses, state, overwrite: true);
                  });
                }
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_dateFormat.format(_date)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isEditing ? 'Update entry' : 'Save entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;
    final category = _effectiveCategory;
    final waterPreviousReadings = _waterUsageBased
        ? _readHouseReadings(_previousReadingControllers)
        : <String, double>{};
    final waterCurrentReadings = _waterUsageBased
        ? _readHouseReadings(_currentReadingControllers)
        : <String, double>{};
    final entry = ExpenseEntry(
      id: widget.expense?.id ?? _uuid.v4(),
      category: category,
      amount: amount,
      date: _date,
      waterMeterReading: double.tryParse(_readingController.text.trim()),
      targetHouseId: _waterUsageBased ? null : _targetHouseId,
      waterUsageBased: _waterUsageBased,
      waterPreviousReadings: waterPreviousReadings,
      waterCurrentReadings: waterCurrentReadings,
      note: _noteController.text.trim(),
    );
    final controller = ref.read(ledgerProvider.notifier);
    if (_isEditing) {
      controller.updateExpense(entry);
    } else {
      controller.addExpense(entry);
    }
    Navigator.of(context).pop();
  }

  void _ensureWaterReadingControllers(List<House> houses, LedgerState? state) {
    for (final house in houses) {
      _previousReadingControllers.putIfAbsent(
        house.id,
        () => TextEditingController(
          text: _initialPreviousReadingText(house.id, state),
        ),
      );
      _currentReadingControllers.putIfAbsent(
        house.id,
        () => TextEditingController(text: _initialCurrentReadingText(house.id)),
      );
    }
  }

  String _initialPreviousReadingText(String houseId, LedgerState? state) {
    final expense = widget.expense;
    final value =
        expense?.waterPreviousReadings[houseId] ??
        state?.lastWaterCurrentReading(houseId, before: _date);
    return _readingText(value);
  }

  String _initialCurrentReadingText(String houseId) {
    return _readingText(widget.expense?.waterCurrentReadings[houseId]);
  }

  void _populatePreviousReadings(
    List<House> houses,
    LedgerState? state, {
    required bool overwrite,
  }) {
    if (state == null || _isEditing) {
      return;
    }
    for (final house in houses) {
      final controller = _previousReadingControllers[house.id];
      if (controller == null) {
        continue;
      }
      if (!overwrite && controller.text.trim().isNotEmpty) {
        continue;
      }
      controller.text = _readingText(
        state.lastWaterCurrentReading(house.id, before: _date),
      );
    }
  }

  Map<String, double> _readHouseReadings(
    Map<String, TextEditingController> controllers,
  ) {
    return {
      for (final entry in controllers.entries)
        if (double.tryParse(entry.value.text.trim()) != null)
          entry.key: double.parse(entry.value.text.trim()),
    };
  }
}

class _WaterReadingInputs extends StatelessWidget {
  const _WaterReadingInputs({
    required this.houses,
    required this.previousReadingControllers,
    required this.currentReadingControllers,
  });

  final List<House> houses;
  final Map<String, TextEditingController> previousReadingControllers;
  final Map<String, TextEditingController> currentReadingControllers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'House meter readings',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final house in houses) ...[
            Text(house.name, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: previousReadingControllers[house.id],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Previous',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: currentReadingControllers[house.id],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class LedgerController extends AsyncNotifier<LedgerState> {
  static const _storageKey = 'home_maintenance_ledger_v1';

  @override
  Future<LedgerState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return LedgerState.seed();
    return LedgerState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> addHouse(String name) async {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        houses: [
          ...current.houses,
          House(id: _uuid.v4(), name: name),
        ],
      ),
    );
    await _persist();
  }

  Future<void> removeHouse(String id) async {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        houses: [
          for (final house in current.houses)
            if (house.id != id) house,
        ],
      ),
    );
    await _persist();
  }

  Future<void> addExpense(ExpenseEntry expense) async {
    final current = state.requireValue;
    final customCategories = {...current.customCategories};
    if (!defaultCategories.contains(expense.category)) {
      customCategories.add(expense.category);
    }
    state = AsyncData(
      current.copyWith(
        expenses: [...current.expenses, expense],
        selectedMonth: DateTime(expense.date.year, expense.date.month),
        customCategories: customCategories.toList()..sort(),
      ),
    );
    await _persist();
  }

  Future<void> updateExpense(ExpenseEntry updatedExpense) async {
    final current = state.requireValue;
    final customCategories = {...current.customCategories};
    if (!defaultCategories.contains(updatedExpense.category)) {
      customCategories.add(updatedExpense.category);
    }
    state = AsyncData(
      current.copyWith(
        expenses: [
          for (final expense in current.expenses)
            if (expense.id == updatedExpense.id) updatedExpense else expense,
        ],
        selectedMonth: DateTime(
          updatedExpense.date.year,
          updatedExpense.date.month,
        ),
        customCategories: customCategories.toList()..sort(),
      ),
    );
    await _persist();
  }

  Future<void> deleteExpense(String id) async {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        expenses: [
          for (final expense in current.expenses)
            if (expense.id != id) expense,
        ],
      ),
    );
    await _persist();
  }

  Future<void> exportBackup(BuildContext context) async {
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(state.requireValue.toJson()),
    );
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'home-maintenance-backup.json',
    );
  }

  Future<void> importBackup(BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null) {
      return;
    }
    final imported = LedgerState.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
    state = AsyncData(imported);
    await _persist();
  }

  Future<void> downloadPdf(BuildContext context) async {
    final bytes = await _buildPdf(state.requireValue);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: _pdfName(state.requireValue),
    );
  }

  Future<void> sharePdf(BuildContext context) async {
    final bytes = await _buildPdf(state.requireValue);
    final file = XFile.fromData(
      bytes,
      mimeType: 'application/pdf',
      name: _pdfName(state.requireValue),
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        text:
            'Maintenance statement ${_monthFormat.format(state.requireValue.selectedMonth)}',
      ),
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.requireValue.toJson()));
  }
}

class LedgerState {
  const LedgerState({
    required this.houses,
    required this.expenses,
    required this.customCategories,
    required this.selectedMonth,
  });

  final List<House> houses;
  final List<ExpenseEntry> expenses;
  final List<String> customCategories;
  final DateTime selectedMonth;

  factory LedgerState.seed() => LedgerState(
    houses: const [
      House(id: 'house-a', name: 'House A'),
      House(id: 'house-b', name: 'House B'),
      House(id: 'house-c', name: 'House C'),
    ],
    selectedMonth: DateTime(DateTime.now().year, DateTime.now().month),
    customCategories: const [],
    expenses: [
      ExpenseEntry(
        id: 'seed-1',
        category: 'Common electricity',
        amount: 2400,
        date: DateTime.now(),
      ),
      ExpenseEntry(
        id: 'seed-2',
        category: 'Watchman salary',
        amount: 9000,
        date: DateTime.now(),
      ),
      ExpenseEntry(
        id: 'seed-3',
        category: 'Drainage cleaning',
        amount: 1800,
        date: DateTime.now(),
      ),
    ],
  );

  List<ExpenseEntry> get monthExpenses => expenses
      .where(
        (expense) =>
            expense.date.year == selectedMonth.year &&
            expense.date.month == selectedMonth.month,
      )
      .toList();
  double get monthTotal =>
      monthExpenses.fold(0, (sum, expense) => sum + expense.amount);
  double get sharedTotal => monthExpenses
      .where((expense) => expense.targetHouseId == null)
      .fold(0, (sum, expense) => sum + expense.amount);
  double get specificTotal => monthExpenses
      .where((expense) => expense.targetHouseId != null)
      .fold(0, (sum, expense) => sum + expense.amount);
  String get waterReadingText {
    final usageBasedWater = monthExpenses
        .where((expense) => expense.waterUsageBased)
        .lastOrNull;
    if (usageBasedWater != null) {
      return '${_decimal.format(usageBasedWater.totalWaterUsage)} usage';
    }
    final reading = monthExpenses
        .map((expense) => expense.waterMeterReading)
        .nonNulls
        .lastOrNull;
    return reading == null
        ? 'Not set'
        : NumberFormat.decimalPattern('en_IN').format(reading);
  }

  Map<String, double> get allocations {
    final active = houses.where((house) => house.active).toList();
    final values = {for (final house in active) house.id: 0.0};
    for (final expense in monthExpenses) {
      for (final house in active) {
        values.update(
          house.id,
          (value) => value + allocationForExpense(expense, house.id),
          ifAbsent: () => allocationForExpense(expense, house.id),
        );
      }
    }
    return values;
  }

  double allocationForExpense(ExpenseEntry expense, String houseId) {
    final activeCount = houses.where((house) => house.active).length;
    if (expense.targetHouseId != null) {
      return expense.targetHouseId == houseId ? expense.amount : 0;
    }
    if (expense.waterUsageBased) {
      return expense.waterShareForHouse(houseId, activeCount);
    }
    return activeCount == 0 ? 0 : expense.amount / activeCount;
  }

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (final expense in monthExpenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  String houseName(String id) =>
      houses.firstWhereOrNull((house) => house.id == id)?.name ??
      'Unknown house';

  double? lastWaterCurrentReading(String houseId, {required DateTime before}) {
    final previousWaterEntries = expenses
        .where(
          (expense) =>
              expense.waterUsageBased &&
              expense.date.isBefore(before) &&
              expense.waterCurrentReadings.containsKey(houseId),
        )
        .sortedBy((expense) => expense.date);
    return previousWaterEntries.lastOrNull?.waterCurrentReadings[houseId];
  }

  LedgerState copyWith({
    List<House>? houses,
    List<ExpenseEntry>? expenses,
    List<String>? customCategories,
    DateTime? selectedMonth,
  }) {
    return LedgerState(
      houses: houses ?? this.houses,
      expenses: expenses ?? this.expenses,
      customCategories: customCategories ?? this.customCategories,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }

  Map<String, dynamic> toJson() => {
    'houses': houses.map((house) => house.toJson()).toList(),
    'expenses': expenses.map((expense) => expense.toJson()).toList(),
    'customCategories': customCategories,
    'selectedMonth': selectedMonth.toIso8601String(),
  };

  factory LedgerState.fromJson(Map<String, dynamic> json) => LedgerState(
    houses: (json['houses'] as List<dynamic>? ?? [])
        .map((item) => House.fromJson(item as Map<String, dynamic>))
        .toList(),
    expenses: (json['expenses'] as List<dynamic>? ?? [])
        .map((item) => ExpenseEntry.fromJson(item as Map<String, dynamic>))
        .toList(),
    customCategories: (json['customCategories'] as List<dynamic>? ?? [])
        .cast<String>(),
    selectedMonth:
        DateTime.tryParse(json['selectedMonth'] as String? ?? '') ??
        DateTime(DateTime.now().year, DateTime.now().month),
  );
}

class House {
  const House({required this.id, required this.name, this.active = true});

  final String id;
  final String name;
  final bool active;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'active': active};
  factory House.fromJson(Map<String, dynamic> json) => House(
    id: json['id'] as String,
    name: json['name'] as String,
    active: json['active'] as bool? ?? true,
  );
}

class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.waterMeterReading,
    this.targetHouseId,
    this.waterUsageBased = false,
    this.waterPreviousReadings = const {},
    this.waterCurrentReadings = const {},
    this.note = '',
  });

  final String id;
  final String category;
  final double amount;
  final DateTime date;
  final double? waterMeterReading;
  final String? targetHouseId;
  final bool waterUsageBased;
  final Map<String, double> waterPreviousReadings;
  final Map<String, double> waterCurrentReadings;
  final String note;

  double waterUsageForHouse(String houseId) {
    final previous = waterPreviousReadings[houseId];
    final current = waterCurrentReadings[houseId];
    if (previous == null || current == null) {
      return 0;
    }
    final usage = current - previous;
    return usage <= 0 ? 0 : usage;
  }

  double get totalWaterUsage {
    return waterCurrentReadings.keys.fold(
      0,
      (sum, houseId) => sum + waterUsageForHouse(houseId),
    );
  }

  double waterUsagePercentForHouse(String houseId) {
    final total = totalWaterUsage;
    if (total <= 0) {
      return 0;
    }
    return waterUsageForHouse(houseId) / total;
  }

  double waterShareForHouse(String houseId, int activeHouseCount) {
    final total = totalWaterUsage;
    if (total <= 0) {
      return activeHouseCount == 0 ? 0 : amount / activeHouseCount;
    }
    return amount * waterUsagePercentForHouse(houseId);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'waterMeterReading': waterMeterReading,
    'targetHouseId': targetHouseId,
    'waterUsageBased': waterUsageBased,
    'waterPreviousReadings': waterPreviousReadings,
    'waterCurrentReadings': waterCurrentReadings,
    'note': note,
  };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) => ExpenseEntry(
    id: json['id'] as String,
    category: json['category'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    waterMeterReading: (json['waterMeterReading'] as num?)?.toDouble(),
    targetHouseId: json['targetHouseId'] as String?,
    waterUsageBased: json['waterUsageBased'] as bool? ?? false,
    waterPreviousReadings: _readDoubleMap(json['waterPreviousReadings']),
    waterCurrentReadings: _readDoubleMap(json['waterCurrentReadings']),
    note: json['note'] as String? ?? '',
  );
}

const defaultCategories = [
  'Water meter',
  'Common electricity',
  'Watchman salary',
  'Drainage cleaning',
  'Miscellaneous',
];

bool _isWaterCategory(String category) =>
    category.toLowerCase().contains('water');

String _readingText(double? value) {
  if (value == null) {
    return '';
  }
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
}

Map<String, double> _readDoubleMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return {
    for (final entry in value.entries)
      if (entry.value is num)
        entry.key.toString(): (entry.value as num).toDouble(),
  };
}

Color _categoryColor(String category) {
  final colors = [
    _paletteBlue,
    _paletteTeal,
    _paletteGreen,
    _paletteAmber,
    _paletteIndigo,
  ];
  return colors[category.hashCode.abs() % colors.length];
}

IconData _categoryIcon(String category) {
  if (category.toLowerCase().contains('water')) {
    return Icons.water_drop_outlined;
  }
  if (category.toLowerCase().contains('electric')) return Icons.bolt_outlined;
  if (category.toLowerCase().contains('watchman')) {
    return Icons.security_outlined;
  }
  if (category.toLowerCase().contains('drain')) {
    return Icons.cleaning_services_outlined;
  }
  return Icons.category_outlined;
}

String _pdfName(LedgerState state) =>
    'maintenance-${DateFormat('yyyy-MM').format(state.selectedMonth)}.pdf';

Future<Uint8List> _buildPdf(LedgerState state) async {
  final doc = pw.Document();
  final activeHouses = state.houses.where((house) => house.active).toList();
  final commonExpenses = state.monthExpenses
      .where((expense) => expense.targetHouseId == null)
      .toList();
  final houseCount = activeHouses.length;
  final generatedAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(18),
          decoration: pw.BoxDecoration(
            color: _pdfColor(0x453db2),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Home Maintenance Statement',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _monthFormat.format(state.selectedMonth),
                        style: pw.TextStyle(
                          color: _pdfColor(0xe7e5ff),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _pdfColor(0xffa600),
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      'PDF',
                      style: pw.TextStyle(
                        color: _pdfColor(0x453db2),
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pdfMetric(
                    'Total expense',
                    _money.format(state.monthTotal),
                    _pdfColor(0xffffff),
                    _pdfColor(0xf0f8ff),
                  ),
                  _pdfMetric(
                    'Shared total',
                    _money.format(state.sharedTotal),
                    _pdfColor(0xffffff),
                    _pdfColor(0xf0f8ff),
                  ),
                  _pdfMetric(
                    'Houses',
                    '$houseCount',
                    _pdfColor(0xffffff),
                    _pdfColor(0xf0f8ff),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 18),
        _pdfSectionTitle('Category summary'),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in state.categoryTotals.entries)
              _pdfCategoryChip(state, entry.key, _money.format(entry.value)),
          ],
        ),
        pw.SizedBox(height: 18),
        _pdfSectionTitle('House-wise detailed split'),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            for (final house in activeHouses)
              _pdfHouseSplit(state, house, commonExpenses),
          ],
        ),
        pw.Divider(color: _pdfColor(0xb7cbc6)),
        pw.Text(
          'Generated on $generatedAt. Share this PDF directly on WhatsApp or save it for monthly records.',
          style: pw.TextStyle(color: _pdfColor(0x52635f), fontSize: 9),
        ),
      ],
    ),
  );
  return doc.save();
}

pw.Widget _pdfMetric(
  String label,
  String value,
  PdfColor valueColor,
  PdfColor labelColor,
) {
  return pw.Container(
    width: 160,
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _pdfColor(0x007ad1),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(color: labelColor, fontSize: 9)),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _pdfSectionTitle(String title) {
  return pw.Row(
    children: [
      pw.Container(
        width: 7,
        height: 18,
        decoration: pw.BoxDecoration(
          color: _pdfColor(0x007ad1),
          borderRadius: pw.BorderRadius.circular(3),
        ),
      ),
      pw.SizedBox(width: 7),
      pw.Text(
        title,
        style: pw.TextStyle(
          color: _pdfColor(0x17211f),
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ],
  );
}

pw.Widget _pdfCategoryChip(LedgerState state, String category, String amount) {
  final color = _pdfCategoryColor(category);
  final expenses = state.monthExpenses
      .where((expense) => expense.category == category)
      .toList();
  final splitInfo = _pdfCategorySplitInfo(state, expenses);
  return pw.Container(
    width: 252,
    padding: const pw.EdgeInsets.all(9),
    decoration: pw.BoxDecoration(
      color: _pdfColor(0xf5fbfa),
      border: pw.Border.all(color: color, width: 0.8),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            _pdfIconBadge(_pdfCategoryIcon(category), color),
            pw.SizedBox(width: 7),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    category,
                    maxLines: 1,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: _pdfColor(0x52635f),
                    ),
                  ),
                  pw.Text(
                    amount,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _pdfColor(0x17211f),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 7),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            splitInfo,
            style: pw.TextStyle(fontSize: 8, color: _pdfColor(0x52635f)),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _pdfHouseSplit(
  LedgerState state,
  House house,
  List<ExpenseEntry> commonExpenses,
) {
  final specificExpenses = state.monthExpenses
      .where((expense) => expense.targetHouseId == house.id)
      .toList();
  final commonRows = [
    for (final expense in commonExpenses)
      [
        '${_pdfCategoryIcon(expense.category)} ${expense.category}',
        expense.waterUsageBased
            ? 'Usage ${_decimal.format(expense.waterUsageForHouse(house.id))} (${_percent.format(expense.waterUsagePercentForHouse(house.id))})'
            : 'Common split',
        _money.format(state.allocationForExpense(expense, house.id)),
      ],
  ];
  final specificRows = [
    for (final expense in specificExpenses)
      [
        '${_pdfCategoryIcon(expense.category)} ${expense.category}',
        'Specific charge',
        _money.format(expense.amount),
      ],
  ];
  final total = state.allocations[house.id] ?? 0;

  return pw.Container(
    width: 265,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _pdfColor(0xd6e9ec)),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _pdfColor(0xeef8f7),
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(8),
              topRight: pw.Radius.circular(8),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  _pdfIconBadge('H', _pdfColor(0x009f88)),
                  pw.SizedBox(width: 7),
                  pw.Text(
                    house.name,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: _pdfColor(0x453db2),
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: _pdfColor(0xfff4d6),
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Text(
                  _money.format(total),
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _pdfColor(0x453db2),
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.TableHelper.fromTextArray(
          border: null,
          headerDecoration: pw.BoxDecoration(color: _pdfColor(0xf5fbfa)),
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _pdfColor(0x52635f),
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.2),
            1: const pw.FlexColumnWidth(1.45),
            2: const pw.FlexColumnWidth(1),
          },
          headers: ['Expense', 'Type', 'This house'],
          data: [...commonRows, ...specificRows],
        ),
      ],
    ),
  );
}

pw.Widget _pdfIconBadge(String icon, PdfColor color) {
  return pw.Container(
    width: 22,
    height: 22,
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
    child: pw.Text(
      icon,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

PdfColor _pdfCategoryColor(String category) {
  final colors = [
    _pdfColor(0x453db2),
    _pdfColor(0x007ad1),
    _pdfColor(0x009f88),
    _pdfColor(0x51b302),
    _pdfColor(0xffa600),
  ];
  return colors[category.hashCode.abs() % colors.length];
}

String _pdfCategoryIcon(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('water')) return 'W';
  if (lower.contains('electric')) return 'E';
  if (lower.contains('watchman')) return 'S';
  if (lower.contains('drain')) return 'D';
  return 'M';
}

String _pdfCategorySplitInfo(LedgerState state, List<ExpenseEntry> expenses) {
  if (expenses.isEmpty) {
    return 'No entries';
  }
  final entryText = expenses.length == 1
      ? '1 entry'
      : '${expenses.length} entries';
  final hasUsageWater = expenses.any((expense) => expense.waterUsageBased);
  final hasSpecific = expenses.any((expense) => expense.targetHouseId != null);
  final hasShared = expenses.any(
    (expense) => expense.targetHouseId == null && !expense.waterUsageBased,
  );
  final parts = <String>[];
  if (hasShared) {
    parts.add('equal split');
  }
  if (hasUsageWater) {
    final totalUsage = expenses
        .where((expense) => expense.waterUsageBased)
        .fold(0.0, (sum, expense) => sum + expense.totalWaterUsage);
    parts.add('water usage ${_decimal.format(totalUsage)}');
  }
  if (hasSpecific) {
    final houseNames = expenses
        .map((expense) => expense.targetHouseId)
        .nonNulls
        .map(state.houseName)
        .toSet()
        .join(', ');
    parts.add('specific to $houseNames');
  }
  return '$entryText - ${parts.join(' - ')}';
}

PdfColor _pdfColor(int hex) {
  return PdfColor(
    ((hex >> 16) & 0xff) / 255,
    ((hex >> 8) & 0xff) / 255,
    (hex & 0xff) / 255,
  );
}
