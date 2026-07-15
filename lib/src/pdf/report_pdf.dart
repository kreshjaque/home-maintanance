part of '../../main.dart';

String _pdfName(LedgerState state) =>
    'maintenance-${DateFormat('yyyy-MM').format(state.selectedMonth)}.pdf';

Future<Uint8List> _buildPdf(LedgerState state) async {
  final doc = pw.Document();
  final report = MonthlyReport.from(state);
  final commonExpenses = report.monthExpenses
      .where((expense) => expense.targetHouseId == null)
      .toList();
  final houseCount = report.activeHouses.length;
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
                  pw.Expanded(
                    child: pw.Column(
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
                          '${_monthFormat.format(state.selectedMonth)} monthly split for all active houses',
                          style: pw.TextStyle(
                            color: _pdfColor(0xe7e5ff),
                            fontSize: 11,
                          ),
                        ),
                      ],
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
                    _money.format(report.monthTotal),
                    _pdfColor(0x007ad1),
                    _pdfColor(0xffffff),
                    _pdfColor(0xf0f8ff),
                  ),
                  _pdfMetric(
                    'Shared total',
                    _money.format(report.sharedTotal),
                    _pdfColor(0x009f88),
                    _pdfColor(0xffffff),
                    _pdfColor(0xf0f8ff),
                  ),
                  _pdfMetric(
                    'Houses',
                    '$houseCount',
                    _pdfColor(0xffa600),
                    _pdfColor(0x453db2),
                    _pdfColor(0x453db2),
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
            for (final entry in report.categoryTotals.entries)
              _pdfCategoryChip(report, entry.key, _money.format(entry.value)),
          ],
        ),
        pw.SizedBox(height: 18),
        _pdfSectionTitle('House-wise detailed split'),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            for (final house in report.activeHouses)
              _pdfHouseSplit(report, house, commonExpenses),
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
  PdfColor backgroundColor,
  PdfColor valueColor,
  PdfColor labelColor,
) {
  return pw.Container(
    width: 160,
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: backgroundColor,
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

pw.Widget _pdfCategoryChip(
  MonthlyReport report,
  String category,
  String amount,
) {
  final color = _pdfCategoryColor(category);
  final expenses = report.monthExpenses
      .where((expense) => expense.category == category)
      .toList();
  final splitInfo = _pdfCategorySplitInfo(report.state, expenses);
  return pw.Container(
    width: 252,
    padding: const pw.EdgeInsets.all(10),
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
  MonthlyReport report,
  House house,
  List<ExpenseEntry> commonExpenses,
) {
  final specificExpenses = report.monthExpenses
      .where((expense) => expense.targetHouseId == house.id)
      .toList();
  final commonRows = [
    for (final expense in commonExpenses)
      [
        '${_pdfCategoryIcon(expense.category)} ${expense.category}',
        _pdfExpenseSplitType(expense, house.id),
        _money.format(report.state.allocationForExpense(expense, house.id)),
      ],
  ];
  final specificRows = [
    for (final expense in specificExpenses)
      [
        '${_pdfCategoryIcon(expense.category)} ${expense.category}',
        'Specific',
        _money.format(expense.amount),
      ],
  ];
  final total = report.allocations[house.id] ?? 0;
  final rows = [...commonRows, ...specificRows];

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
            children: [
              _pdfIconBadge('H', _pdfColor(0x009f88)),
              pw.SizedBox(width: 7),
              pw.Expanded(
                child: pw.Text(
                  house.name,
                  maxLines: 1,
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: pw.BoxDecoration(color: _pdfColor(0x453db2)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total due',
                style: pw.TextStyle(
                  color: _pdfColor(0xe7e5ff),
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _money.format(total),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (rows.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Text(
              'No dues for this month',
              style: pw.TextStyle(fontSize: 8, color: _pdfColor(0x52635f)),
            ),
          )
        else
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
              0: const pw.FlexColumnWidth(1.8),
              1: const pw.FlexColumnWidth(1.9),
              2: const pw.FlexColumnWidth(1),
            },
            headers: ['Expense', 'Split type', 'Due'],
            data: rows,
          ),
      ],
    ),
  );
}

String _pdfExpenseSplitType(ExpenseEntry expense, String houseId) {
  if (expense.waterUsageBased) {
    final usage = expense.waterUsageForHouse(houseId);
    final percent = expense.waterUsagePercentForHouse(houseId);
    return 'Usage ${_decimal.format(usage)} units (${_percent.format(percent)})';
  }
  if (expense.targetHouseId != null) {
    return 'Specific';
  }
  return 'Common equal';
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
