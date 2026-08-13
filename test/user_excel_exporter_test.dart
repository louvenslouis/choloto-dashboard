import 'package:c_h_o_l_o_t_o_dashboard/users/user_excel_exporter.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a styled and typed Excel workbook for filtered users', () {
    final exportedAt = DateTime(2026, 8, 13, 14, 30);
    final bytes = UserExcelExporter.buildWorkbook(
      [
        UserExcelExportRow(
          name: 'Marie Pierre',
          email: 'marie@example.com',
          phone: '+509 3700 0000',
          status: 'VIP actif',
          endSubscription: DateTime(2026, 12, 31),
          activeMonths: 8,
          paymentMethod: 'MonCash',
          personalCode: 'CH-2048',
          createdAt: DateTime(2025, 4, 12, 9, 45),
          birthday: DateTime(1992, 6, 18),
          profile: 'Membre',
          uid: 'uid-marie',
        ),
        const UserExcelExportRow(
          name: 'Jean Louis',
          email: 'jean@example.com',
          phone: '',
          status: 'Accès gratuit',
          endSubscription: null,
          activeMonths: 0,
          paymentMethod: '',
          personalCode: '',
          createdAt: null,
          birthday: null,
          profile: '',
          uid: 'uid-jean',
        ),
      ],
      exportedAt: exportedAt,
      filterLabel: 'VIP',
      searchQuery: 'marie',
    );

    expect(bytes, isNotEmpty);
    final workbook = Excel.decodeBytes(bytes);
    expect(workbook.tables.keys, contains('Utilisateurs'));
    final sheet = workbook['Utilisateurs'];

    expect(_text(sheet, 'A1'), 'Liste des utilisateurs CHOLOTO');
    expect(_text(sheet, 'A2'), contains('2 utilisateurs'));
    expect(_text(sheet, 'A2'), contains('filtre : VIP'));
    expect(_text(sheet, 'A2'), contains('recherche : marie'));
    expect(_text(sheet, 'A4'), 'Nom');
    expect(_text(sheet, 'L4'), 'UID');
    expect(_text(sheet, 'A5'), 'Marie Pierre');
    expect(_text(sheet, 'D5'), 'VIP actif');
    expect(_text(sheet, 'G5'), 'MonCash');
    expect(_text(sheet, 'L6'), 'uid-jean');
    expect(
        sheet.cell(CellIndex.indexByString('F5')).value, const IntCellValue(8));
    expect(
      sheet.cell(CellIndex.indexByString('E5')).value,
      isA<DateCellValue>(),
    );
    expect(
      sheet.cell(CellIndex.indexByString('I5')).value,
      isA<DateTimeCellValue>(),
    );
    expect(
      sheet.cell(CellIndex.indexByString('A4')).cellStyle?.isBold,
      isTrue,
    );
    expect(sheet.getColumnWidth(1), greaterThan(sheet.getColumnWidth(5)));
  });
}

String _text(Sheet sheet, String address) {
  return sheet.cell(CellIndex.indexByString(address)).value?.toString() ?? '';
}
