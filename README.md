# Home Maintenance

A mobile and desktop friendly Flutter app for calculating monthly home maintenance expenses, splitting shared bills across houses, tracking water meter readings, and generating a colorful PDF statement that can be shared directly through WhatsApp or downloaded for records.

The app is designed for offline use. Multi-user sync is intentionally not required; data can be backed up and restored using export/import.

## Features

- Month-wise expense tracking.
- Previous and next month navigation from the dashboard.
- House setup with custom house names.
- Shared expenses split equally across all active houses.
- House-specific expenses assigned to a single house.
- Water meter expense support with previous and current readings per house.
- External water source toggle:
  - Off: water amount is split equally.
  - On: water amount is split by usage percentage from meter reading difference.
- Previous month current water reading is carried forward as next month previous reading.
- Custom miscellaneous categories.
- Edit and delete saved expenses.
- Dashboard with category chart, monthly totals, house-wise dues, and responsive summary tiles.
- PDF statement generation with category summary and detailed house-wise split.
- Direct PDF sharing through the device share sheet, including WhatsApp.
- JSON backup export and import for offline data transfer.

## Tech Stack

- Flutter for cross-platform app development.
- Dart for app logic.
- Material 3 for the UI design system.
- Riverpod for app state management.
- Shared Preferences for offline local storage.
- PDF and Printing packages for PDF generation and preview/download.
- Share Plus for Android/iOS/native share sheet support.
- File Picker for importing JSON backups.
- FL Chart for the dashboard category chart.
- Intl for currency, date, decimal, and percentage formatting.
- UUID for stable IDs.

## Project Structure

```text
lib/
  main.dart
  src/
    app/
      app.dart
    core/
      app_constants.dart
    models/
      ledger_models.dart
    pdf/
      report_pdf.dart
    state/
      ledger_controller.dart
    ui/
      dashboard_sections.dart
      expense_form_sheet.dart
      home_page.dart
      setup_panel.dart
      shared_widgets.dart
test/
  ledger_report_test.dart
  widget_test.dart
```

## How To Run

Install Flutter, then run:

```bash
flutter pub get
flutter run
```

To run on Android, connect a device or start an emulator first:

```bash
flutter devices
flutter run -d <device-id>
```

## Build Android APK

Create a release APK:

```bash
flutter build apk --release
```

The APK will be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## How To Use

1. Open the app.
2. Add or update house names in the House setup section.
3. Select the month using the previous/next buttons in the top summary section.
4. Tap Add expense.
5. Choose a category or enter a custom category.
6. Enter the amount and date.
7. Choose whether the expense is shared by all houses or specific to one house.
8. For water meter expenses, enter previous and current readings for each house.
9. Turn on External source water only when the water bill should be split by meter usage.
10. Save the entry.
11. Review the dashboard and house-wise dues.
12. Use the PDF action to generate/download the monthly statement.
13. Use the share action to send the PDF through WhatsApp or any supported app.

## Water Calculation

Water meter readings are stored month-wise.

For a new month, the app carries forward the previous month current reading as the new month previous reading. The amount starts fresh because expenses are filtered by month.

When External source water is off:

```text
Each house share = Water amount / Number of active houses
```

When External source water is on:

```text
House usage = Current reading - Previous reading
House percentage = House usage / Total usage
House share = Water amount * House percentage
```

## Backup And Restore

Use Export backup to share or save a JSON copy of the app data.

Use Import backup to restore data from a previously exported JSON file.

This makes the app practical for offline usage without a server or multi-user login.

## Quality Checks

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Format code:

```bash
dart format lib test
```

## Author

Built by Krishna.

This project was created to make monthly home maintenance calculation easier for small residential groups, especially where expenses are shared house-wise and monthly PDF statements need to be sent over WhatsApp.
