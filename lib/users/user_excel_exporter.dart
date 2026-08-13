import 'dart:typed_data';

import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

class UserExcelExportRow {
  const UserExcelExportRow({
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.endSubscription,
    required this.activeMonths,
    required this.paymentMethod,
    required this.personalCode,
    required this.createdAt,
    required this.birthday,
    required this.profile,
    required this.uid,
  });

  factory UserExcelExportRow.fromRecord(
    UserRecord user, {
    required DateTime referenceDate,
  }) {
    final active = user.endSub != null && !user.endSub!.isBefore(referenceDate);

    return UserExcelExportRow(
      name: user.displayName.trim().isEmpty
          ? 'Membre CHOLOTO'
          : user.displayName.trim(),
      email: user.email.trim(),
      phone: user.phoneNumber.trim(),
      status: active ? 'VIP actif' : 'Accès gratuit',
      endSubscription: user.endSub,
      activeMonths: user.memberTime,
      paymentMethod: _paymentLabel(user.method),
      personalCode: user.codePersonnel.trim(),
      createdAt: user.createdTime,
      birthday: user.birthday,
      profile: user.profile.trim(),
      uid: user.uid.trim(),
    );
  }

  final String name;
  final String email;
  final String phone;
  final String status;
  final DateTime? endSubscription;
  final int activeMonths;
  final String paymentMethod;
  final String personalCode;
  final DateTime? createdAt;
  final DateTime? birthday;
  final String profile;
  final String uid;

  static String _paymentLabel(PaimentMethod? method) {
    return switch (method) {
      PaimentMethod.moncash => 'MonCash',
      PaimentMethod.cash => 'Espèces',
      PaimentMethod.stripe => 'Carte / Stripe',
      null => '',
    };
  }
}

class UserExcelExporter {
  const UserExcelExporter._();

  static const _sheetName = 'Utilisateurs';
  static const _headers = <String>[
    'Nom',
    'E-mail',
    'Téléphone',
    'Statut',
    'Fin abonnement',
    'Mois actifs',
    'Méthode de paiement',
    'Code personnel',
    'Date d’inscription',
    'Date de naissance',
    'Profil',
    'UID',
  ];

  static Future<String> export(
    List<UserRecord> users, {
    required String filterLabel,
    String searchQuery = '',
  }) async {
    final exportedAt = DateTime.now();
    final rows = users
        .map(
          (user) => UserExcelExportRow.fromRecord(
            user,
            referenceDate: exportedAt,
          ),
        )
        .toList();
    final bytes = buildWorkbook(
      rows,
      exportedAt: exportedAt,
      filterLabel: filterLabel,
      searchQuery: searchQuery,
    );
    final name =
        'choloto_utilisateurs_${DateFormat('yyyyMMdd_HHmm').format(exportedAt)}';

    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    return '$name.xlsx';
  }

  static Uint8List buildWorkbook(
    List<UserExcelExportRow> rows, {
    required DateTime exportedAt,
    String filterLabel = 'Tous',
    String searchQuery = '',
  }) {
    final workbook = Excel.createExcel();
    final defaultSheet = workbook.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != _sheetName) {
      workbook.rename(defaultSheet, _sheetName);
    }
    workbook.setDefaultSheet(_sheetName);
    final sheet = workbook[_sheetName];

    final navy = ExcelColor.fromHexString('FF12263F');
    final gold = ExcelColor.fromHexString('FFF6C744');
    final lightBackground = ExcelColor.fromHexString('FFF5F7FA');
    final borderColor = ExcelColor.fromHexString('FFE4EAF1');
    final mutedText = ExcelColor.fromHexString('FF66758A');
    final success = ExcelColor.fromHexString('FF16805C');
    final inactive = ExcelColor.fromHexString('FFE14F5A');
    final bodyFont = getFontFamily(FontFamily.Calibri);
    final subtleBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: borderColor,
    );

    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('L1'),
      customValue: TextCellValue('Liste des utilisateurs CHOLOTO'),
    );
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('L2'),
      customValue: TextCellValue(
        _exportSummary(
          rows.length,
          exportedAt,
          filterLabel: filterLabel,
          searchQuery: searchQuery,
        ),
      ),
    );

    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
      backgroundColorHex: navy,
      fontColorHex: ExcelColor.white,
      fontFamily: bodyFont,
      fontSize: 18,
      bold: true,
      verticalAlign: VerticalAlign.Center,
      horizontalAlign: HorizontalAlign.Left,
    );
    sheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
      backgroundColorHex: gold,
      fontColorHex: navy,
      fontFamily: bodyFont,
      fontSize: 11,
      bold: true,
      verticalAlign: VerticalAlign.Center,
      horizontalAlign: HorizontalAlign.Left,
    );
    sheet.setRowHeight(0, 34);
    sheet.setRowHeight(1, 25);
    sheet.setRowHeight(2, 8);

    for (var column = 0; column < _headers.length; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 3),
      );
      cell.value = TextCellValue(_headers[column]);
      cell.cellStyle = CellStyle(
        backgroundColorHex: navy,
        fontColorHex: ExcelColor.white,
        fontFamily: bodyFont,
        fontSize: 11,
        bold: true,
        verticalAlign: VerticalAlign.Center,
        horizontalAlign: HorizontalAlign.Left,
        bottomBorder: Border(
          borderStyle: BorderStyle.Medium,
          borderColorHex: gold,
        ),
      );
    }
    sheet.setRowHeight(3, 28);

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final excelRowIndex = rowIndex + 4;
      final values = <CellValue?>[
        TextCellValue(row.name),
        TextCellValue(row.email),
        TextCellValue(row.phone),
        TextCellValue(row.status),
        _dateValue(row.endSubscription),
        IntCellValue(row.activeMonths),
        TextCellValue(row.paymentMethod),
        TextCellValue(row.personalCode),
        _dateTimeValue(row.createdAt),
        _dateValue(row.birthday),
        TextCellValue(row.profile),
        TextCellValue(row.uid),
      ];

      for (var column = 0; column < values.length; column++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: column,
            rowIndex: excelRowIndex,
          ),
        );
        cell.value = values[column];
        cell.cellStyle = CellStyle(
          backgroundColorHex:
              rowIndex.isOdd ? lightBackground : ExcelColor.white,
          fontColorHex: column == 3
              ? row.status == 'VIP actif'
                  ? success
                  : inactive
              : ExcelColor.black,
          fontFamily: bodyFont,
          fontSize: 10,
          bold: column == 0 || column == 3,
          verticalAlign: VerticalAlign.Center,
          horizontalAlign:
              column == 5 ? HorizontalAlign.Right : HorizontalAlign.Left,
          bottomBorder: subtleBorder,
          numberFormat: switch (column) {
            4 || 9 => const CustomDateTimeNumFormat(formatCode: 'yyyy-mm-dd'),
            8 => const CustomDateTimeNumFormat(formatCode: 'yyyy-mm-dd hh:mm'),
            5 => const CustomNumericNumFormat(formatCode: '#,##0'),
            _ => NumFormat.standard_0,
          },
        );
      }
      sheet.setRowHeight(excelRowIndex, 23);
    }

    if (rows.isEmpty) {
      sheet.merge(
        CellIndex.indexByString('A5'),
        CellIndex.indexByString('L6'),
        customValue: TextCellValue('Aucun utilisateur à exporter'),
      );
      sheet.cell(CellIndex.indexByString('A5')).cellStyle = CellStyle(
        backgroundColorHex: lightBackground,
        fontColorHex: mutedText,
        fontFamily: bodyFont,
        italic: true,
        verticalAlign: VerticalAlign.Center,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    const widths = <double>[
      24,
      32,
      19,
      17,
      17,
      13,
      21,
      19,
      20,
      18,
      20,
      38,
    ];
    for (var index = 0; index < widths.length; index++) {
      sheet.setColumnWidth(index, widths[index]);
    }

    final encoded = workbook.encode();
    if (encoded == null || encoded.isEmpty) {
      throw StateError('Le classeur Excel n’a pas pu être généré.');
    }
    return Uint8List.fromList(encoded);
  }

  static String _exportSummary(
    int count,
    DateTime exportedAt, {
    required String filterLabel,
    required String searchQuery,
  }) {
    final details = <String>[
      '$count ${count > 1 ? 'utilisateurs' : 'utilisateur'}',
      'filtre : $filterLabel',
      if (searchQuery.trim().isNotEmpty) 'recherche : ${searchQuery.trim()}',
      'exporté le ${DateFormat('dd/MM/yyyy à HH:mm').format(exportedAt)}',
    ];
    return details.join(' • ');
  }

  static CellValue? _dateValue(DateTime? value) {
    return value == null ? null : DateCellValue.fromDateTime(value);
  }

  static CellValue? _dateTimeValue(DateTime? value) {
    return value == null ? null : DateTimeCellValue.fromDateTime(value);
  }
}
