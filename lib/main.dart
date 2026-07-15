import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

part 'src/core/app_constants.dart';
part 'src/app/app.dart';
part 'src/state/ledger_controller.dart';
part 'src/models/ledger_models.dart';
part 'src/ui/home_page.dart';
part 'src/ui/dashboard_sections.dart';
part 'src/ui/setup_panel.dart';
part 'src/ui/expense_form_sheet.dart';
part 'src/ui/shared_widgets.dart';
part 'src/pdf/report_pdf.dart';

void main() {
  runApp(const HomeMaintenanceApp());
}
