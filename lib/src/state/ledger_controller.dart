part of '../../main.dart';

final ledgerProvider = AsyncNotifierProvider<LedgerController, LedgerState>(
  LedgerController.new,
);

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

  Future<void> previousMonth() async {
    final current = state.requireValue;
    await _setSelectedMonth(
      DateTime(current.selectedMonth.year, current.selectedMonth.month - 1),
    );
  }

  Future<void> nextMonth() async {
    final current = state.requireValue;
    await _setSelectedMonth(
      DateTime(current.selectedMonth.year, current.selectedMonth.month + 1),
    );
  }

  Future<void> _setSelectedMonth(DateTime month) async {
    final normalized = DateTime(month.year, month.month);
    final current = state.requireValue;
    state = AsyncData(current.copyWith(selectedMonth: normalized));
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
    final backup = XFile.fromData(
      Uint8List.fromList(bytes),
      mimeType: 'application/json',
      name: 'home-maintenance-backup.json',
    );
    await SharePlus.instance.share(
      ShareParams(files: [backup], text: 'Home maintenance backup'),
    );
  }

  Future<void> importBackup(BuildContext context) async {
    try {
      final picked = await FilePicker.pickFiles(
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
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup imported.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not import this backup file.')),
        );
      }
    }
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
