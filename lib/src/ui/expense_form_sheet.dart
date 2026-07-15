part of '../../main.dart';

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
      final selectedMonth = ref.read(ledgerProvider).value?.selectedMonth;
      if (selectedMonth != null) {
        _date = _defaultEntryDateForMonth(selectedMonth);
      }
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
        left: 18,
        right: 18,
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'Rs ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _readingController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Water meter reading',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (_isWaterEntry) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.water_drop_outlined),
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
              const SizedBox(height: 8),
              _WaterReadingInputs(
                houses: houses,
                previousReadingControllers: _previousReadingControllers,
                currentReadingControllers: _currentReadingControllers,
              ),
              const SizedBox(height: 10),
            ],
            if (!_isWaterEntry)
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
                HapticFeedback.selectionClick();
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
    if (amount <= 0) {
      _showFormError('Enter an amount greater than zero.');
      return;
    }
    final category = _effectiveCategory;
    final waterPreviousReadings = _isWaterEntry
        ? _readHouseReadings(_previousReadingControllers)
        : <String, double>{};
    final waterCurrentReadings = _isWaterEntry
        ? _readHouseReadings(_currentReadingControllers)
        : <String, double>{};
    if (_waterUsageBased) {
      final totalUsage = waterCurrentReadings.keys.fold(
        0.0,
        (sum, houseId) =>
            sum +
            _waterUsage(houseId, waterPreviousReadings, waterCurrentReadings),
      );
      if (totalUsage <= 0) {
        _showFormError(
          'Enter current readings greater than previous readings.',
        );
        return;
      }
    }
    final entry = ExpenseEntry(
      id: widget.expense?.id ?? _uuid.v4(),
      category: category,
      amount: amount,
      date: _date,
      waterMeterReading: double.tryParse(_readingController.text.trim()),
      targetHouseId: _isWaterEntry ? null : _targetHouseId,
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

  void _showFormError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  double _waterUsage(
    String houseId,
    Map<String, double> previousReadings,
    Map<String, double> currentReadings,
  ) {
    final previous = previousReadings[houseId];
    final current = currentReadings[houseId];
    if (previous == null || current == null) {
      return 0;
    }
    final usage = current - previous;
    return usage <= 0 ? 0 : usage;
  }
}
