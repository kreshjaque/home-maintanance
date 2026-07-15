import 'package:flutter_test/flutter_test.dart';
import 'package:home_maintenance/main.dart';

void main() {
  final month = DateTime(2026, 7, 1);
  const houseA = House(id: 'a', name: 'House A');
  const houseB = House(id: 'b', name: 'House B');

  test('external water source splits by usage percentage', () {
    final state = LedgerState(
      houses: const [houseA, houseB],
      customCategories: const [],
      selectedMonth: month,
      expenses: [
        ExpenseEntry(
          id: 'water',
          category: 'Water meter',
          amount: 1000,
          date: month,
          waterUsageBased: true,
          waterPreviousReadings: const {'a': 100, 'b': 200},
          waterCurrentReadings: const {'a': 130, 'b': 270},
        ),
      ],
    );

    final report = MonthlyReport.from(state);

    expect(report.allocations['a'], 300);
    expect(report.allocations['b'], 700);
  });

  test('water readings are kept while non-external water splits equally', () {
    final state = LedgerState(
      houses: const [houseA, houseB],
      customCategories: const [],
      selectedMonth: month,
      expenses: [
        ExpenseEntry(
          id: 'water',
          category: 'Water meter',
          amount: 1000,
          date: month,
          waterUsageBased: false,
          waterPreviousReadings: const {'a': 100, 'b': 200},
          waterCurrentReadings: const {'a': 130, 'b': 270},
        ),
      ],
    );

    final report = MonthlyReport.from(state);

    expect(report.allocations['a'], 500);
    expect(report.allocations['b'], 500);
    expect(state.lastWaterCurrentReading('b', before: DateTime(2026, 8)), 270);
  });

  test('selected month only includes that month expenses', () {
    final state = LedgerState(
      houses: const [houseA, houseB],
      customCategories: const [],
      selectedMonth: DateTime(2026, 8),
      expenses: [
        ExpenseEntry(
          id: 'july-water',
          category: 'Water meter',
          amount: 1000,
          date: DateTime(2026, 7, 1),
          waterCurrentReadings: const {'a': 130, 'b': 270},
        ),
      ],
    );

    final report = MonthlyReport.from(state);

    expect(report.monthTotal, 0);
    expect(report.allocations['a'], 0);
    expect(state.lastWaterCurrentReading('a', before: DateTime(2026, 8)), 130);
  });
}
