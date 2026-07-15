part of '../../main.dart';

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
const _appInk = Color(0xff17211f);
const _appMuted = Color(0xff52635f);

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

DateTime _defaultEntryDateForMonth(DateTime selectedMonth) {
  final now = DateTime.now();
  if (now.year == selectedMonth.year && now.month == selectedMonth.month) {
    return now;
  }
  return DateTime(selectedMonth.year, selectedMonth.month);
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
