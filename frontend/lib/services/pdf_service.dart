import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  // Regex covering Unicode emojis, pictographs, dingbats, and variation selectors
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2300}-\u{23FF}\u{2B50}\u{FE00}-\u{FE0F}\u{200D}\u{200C}\u{E0020}-\u{E007F}]',
    unicode: true,
  );

  /// Strips emojis and normalizes spaces for clean, printable PDF rendering.
  static String _cleanText(String text) {
    if (text.isEmpty) return text;
    final withoutEmojis = text.replaceAll(_emojiRegex, '').trim();
    return withoutEmojis.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Converts currency symbols that are unsupported by standard PDF fonts
  /// (such as ₹ Indian Rupee, ₩ Won, ₺ Lira, etc.) into clean printable ASCII/Latin-1 text.
  static String _formatPdfCurrency(String currencySymbol, [String? currencyCode]) {
    final clean = currencySymbol.trim();
    if (clean == '₹' || currencyCode?.toUpperCase() == 'INR') {
      return 'Rs. ';
    }
    switch (clean) {
      case '₩':
        return 'KRW ';
      case '₺':
        return 'TRY ';
      case '₽':
        return 'RUB ';
      case '฿':
        return 'THB ';
      case 'د.إ':
        return 'AED ';
      case 'ر.س':
        return 'SAR ';
      default:
        final hasNonLatin1 = clean.runes.any((r) => r > 255 && r != 0x20AC);
        if (hasNonLatin1) {
          if (currencyCode != null && currencyCode.isNotEmpty) {
            return '$currencyCode ';
          }
          return '';
        }
        if (RegExp(r'^[A-Za-z]+$').hasMatch(clean)) {
          return '$clean ';
        }
        return clean;
    }
  }

  static Future<void> generateAndPrintStatement({
    required List<Map<String, dynamic>> transactions,
    required String accountName,
    required DateTime startDate,
    required DateTime endDate,
    required String currencySymbol,
    String? currencyCode,
    required bool includeSummary,
    bool? isSingleAccount,
  }) async {
    final pdf = pw.Document();

    final bool isSingle =
        isSingleAccount ?? (accountName.trim().toLowerCase() != 'all accounts');
    final String safeCurrency =
        _formatPdfCurrency(currencySymbol, currencyCode);

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in transactions) {
      final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      final type = tx['type']?.toString().toLowerCase() ?? '';
      if (type == 'income') {
        totalIncome += amt;
      } else if (type == 'expense') {
        totalExpense += amt;
      }
    }
    double netSavings = totalIncome - totalExpense;

    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    // Styled Logo Badge (Vector)
                    pw.Container(
                      width: 40,
                      height: 40,
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF10B981), // Emerald
                        shape: pw.BoxShape.circle,
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'FL',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'FINLOOP',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF10B981),
                          ),
                        ),
                        pw.Text(
                          'Track, Budget & Save Smarter',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'FINANCIAL STATEMENT',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Generated: ${dateFormat.format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey300, thickness: 1),
            pw.SizedBox(height: 10),

            // Period & Account Details Info Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Account: ${_cleanText(accountName)}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Statement Period: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Summary cards (rendered only if includeSummary is true)
            if (includeSummary) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryBox('Total Income', '$safeCurrency${totalIncome.toStringAsFixed(2)}', const PdfColor.fromInt(0xFF10B981)),
                  _buildSummaryBox('Total Expense', '$safeCurrency${totalExpense.toStringAsFixed(2)}', const PdfColor.fromInt(0xFFEF4444)),
                  _buildSummaryBox('Net Savings', '$safeCurrency${netSavings.toStringAsFixed(2)}', netSavings >= 0 ? const PdfColor.fromInt(0xFF10B981) : const PdfColor.fromInt(0xFFEF4444)),
                ],
              ),
              pw.SizedBox(height: 25),
            ] else ...[
              pw.SizedBox(height: 10),
            ],

            // Transactions Table
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1.0),
              ),
              columnWidths: isSingle
                  ? const {
                      0: pw.FixedColumnWidth(85), // Date
                      1: pw.FixedColumnWidth(125), // Category
                      2: pw.FlexColumnWidth(), // Notes
                      3: pw.FixedColumnWidth(100), // Amount
                    }
                  : const {
                      0: pw.FixedColumnWidth(75), // Date
                      1: pw.FixedColumnWidth(95), // Category
                      2: pw.FixedColumnWidth(90), // Account
                      3: pw.FlexColumnWidth(), // Notes
                      4: pw.FixedColumnWidth(95), // Amount
                    },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF10B981), // Emerald
                  ),
                  children: isSingle
                      ? [
                          _buildHeaderCell('Date'),
                          _buildHeaderCell('Category'),
                          _buildHeaderCell('Notes'),
                          _buildHeaderCell('Amount', alignRight: true),
                        ]
                      : [
                          _buildHeaderCell('Date'),
                          _buildHeaderCell('Category'),
                          _buildHeaderCell('Account'),
                          _buildHeaderCell('Notes'),
                          _buildHeaderCell('Amount', alignRight: true),
                        ],
                ),
                ...transactions.map((tx) {
                  // Parse date
                  final rawDate = tx['date'];
                  DateTime? parsedDate;
                  if (rawDate is DateTime) {
                    parsedDate = rawDate;
                  } else if (rawDate is Timestamp) {
                    parsedDate = rawDate.toDate();
                  } else if (rawDate is String) {
                    parsedDate = DateTime.tryParse(rawDate);
                  }

                  final dateStr = parsedDate != null ? dateFormat.format(parsedDate) : (rawDate?.toString() ?? '');
                  final amtVal = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                  final type = tx['type']?.toString() ?? '';
                  final isIncome = type.toLowerCase() == 'income';
                  final prefix = isIncome ? '+' : '-';
                  final amtColor = isIncome ? const PdfColor.fromInt(0xFF10B981) : const PdfColor.fromInt(0xFFEF4444);

                  final rawCategory = tx['category_name']?.toString() ?? '';
                  final cleanCategory = _cleanText(rawCategory);
                  final displayCategory = cleanCategory.isEmpty ? 'Other' : cleanCategory;

                  final rawNotes = tx['notes']?.toString() ?? tx['description']?.toString() ?? '-';
                  final cleanNotes = _cleanText(rawNotes);
                  final displayNotes = cleanNotes.isEmpty ? '-' : cleanNotes;

                  final amountText = '$prefix$safeCurrency${amtVal.toStringAsFixed(2)}';

                  if (isSingle) {
                    return pw.TableRow(
                      children: [
                        _buildDataCell(dateStr),
                        _buildDataCell(displayCategory),
                        _buildDataCell(displayNotes),
                        _buildDataCell(amountText, color: amtColor, alignRight: true),
                      ],
                    );
                  }

                  final rawAccount = tx['account_name']?.toString() ?? '';
                  final cleanAccount = _cleanText(rawAccount);

                  return pw.TableRow(
                    children: [
                      _buildDataCell(dateStr),
                      _buildDataCell(displayCategory),
                      _buildDataCell(cleanAccount),
                      _buildDataCell(displayNotes),
                      _buildDataCell(amountText, color: amtColor, alignRight: true),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Divider(color: PdfColors.grey200, thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Track budgets, manage expenses & save smarter. Download the Finloop app on the Google Play Store.',
                    style: pw.TextStyle(
                      color: PdfColors.grey500,
                      fontSize: 7.5,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 7.5),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'finloop_statement_${DateFormat('yyyyMMdd').format(startDate)}.pdf',
    );
  }

  static pw.Widget _buildHeaderCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Container(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildDataCell(String text, {PdfColor? color, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Container(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            color: color ?? const PdfColor.fromInt(0xFF1F2937),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF9FAFB),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.fromBorderSide(pw.BorderSide(color: PdfColor.fromInt(0xFFE5E7EB), width: 1)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF4B5563),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
