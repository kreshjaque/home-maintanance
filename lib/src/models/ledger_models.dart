part of '../../main.dart';

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
              _isWaterCategory(expense.category) &&
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

class MonthlyReport {
  MonthlyReport._({
    required this.state,
    required this.activeHouses,
    required this.monthExpenses,
    required this.monthExpensesSorted,
    required this.categoryTotals,
    required this.allocations,
    required this.maxAllocation,
    required this.monthTotal,
    required this.sharedTotal,
    required this.specificTotal,
    required this.waterReadingText,
  });

  factory MonthlyReport.from(LedgerState state) {
    final activeHouses = state.houses.where((house) => house.active).toList();
    final monthExpenses = state.expenses
        .where(
          (expense) =>
              expense.date.year == state.selectedMonth.year &&
              expense.date.month == state.selectedMonth.month,
        )
        .toList();
    final monthExpensesSorted = [...monthExpenses]
      ..sort((a, b) => b.date.compareTo(a.date));
    final categoryTotals = <String, double>{};
    for (final expense in monthExpenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final allocations = {for (final house in activeHouses) house.id: 0.0};
    for (final expense in monthExpenses) {
      for (final house in activeHouses) {
        allocations.update(
          house.id,
          (value) => value + state.allocationForExpense(expense, house.id),
          ifAbsent: () => state.allocationForExpense(expense, house.id),
        );
      }
    }
    final maxAllocation = allocations.values.isEmpty
        ? 0.0
        : allocations.values.reduce((a, b) => a > b ? a : b);
    final monthTotal = monthExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final sharedTotal = monthExpenses
        .where((expense) => expense.targetHouseId == null)
        .fold(0.0, (sum, expense) => sum + expense.amount);
    final specificTotal = monthExpenses
        .where((expense) => expense.targetHouseId != null)
        .fold(0.0, (sum, expense) => sum + expense.amount);

    return MonthlyReport._(
      state: state,
      activeHouses: activeHouses,
      monthExpenses: monthExpenses,
      monthExpensesSorted: monthExpensesSorted,
      categoryTotals: categoryTotals,
      allocations: allocations,
      maxAllocation: maxAllocation,
      monthTotal: monthTotal,
      sharedTotal: sharedTotal,
      specificTotal: specificTotal,
      waterReadingText: _waterReadingText(monthExpenses),
    );
  }

  final LedgerState state;
  final List<House> activeHouses;
  final List<ExpenseEntry> monthExpenses;
  final List<ExpenseEntry> monthExpensesSorted;
  final Map<String, double> categoryTotals;
  final Map<String, double> allocations;
  final double maxAllocation;
  final double monthTotal;
  final double sharedTotal;
  final double specificTotal;
  final String waterReadingText;

  static String _waterReadingText(List<ExpenseEntry> monthExpenses) {
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
    return reading == null ? 'Not set' : _decimal.format(reading);
  }
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
