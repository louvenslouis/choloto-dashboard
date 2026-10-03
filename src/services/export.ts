import { asDate, localDateInput, type Row } from "./data";
export async function exportMembers(rows: Row[]) {
  const { Workbook } = await import("exceljs");
  const workbook = new Workbook();
  const sheet = workbook.addWorksheet("Membres");
  sheet.columns = [
    ["Nom", "display_name", 26],
    ["E-mail", "email", 34],
    ["Téléphone", "phone_number", 20],
    ["Statut", "status", 18],
    ["Échéance", "end_sub", 20],
    ["Renouvellements", "member_time", 20],
    ["Méthode", "method", 18],
    ["Code personnel", "code_personnel", 20],
    ["Création", "created_time", 20],
    ["Anniversaire", "birthday", 20],
    ["Profil", "profile", 24],
    ["UID", "uid", 32],
  ].map(([header, key, width]) => ({
    header: String(header),
    key: String(key),
    width: Number(width),
  }));
  rows.forEach((row) => {
    const output: Record<string, unknown> = {
      ...row,
      uid: row.uid || row.id,
      status:
        (asDate(row.end_sub)?.getTime() || 0) >= Date.now()
          ? "VIP actif"
          : "Accès gratuit",
    };
    for (const field of ["end_sub", "created_time", "birthday"])
      output[field] = asDate(row[field]);
    sheet.addRow(output);
  });
  sheet.getRow(1).font = { bold: true, color: { argb: "FFFFFFFF" } };
  sheet.getRow(1).fill = {
    type: "pattern",
    pattern: "solid",
    fgColor: { argb: "FF10243A" },
  };
  sheet.autoFilter = { from: "A1", to: "L1" };
  sheet.views = [{ state: "frozen", ySplit: 1 }];
  for (const key of ["end_sub", "created_time", "birthday"])
    sheet.getColumn(key).numFmt = "dd/mm/yyyy";
  const buffer = await workbook.xlsx.writeBuffer();
  const url = URL.createObjectURL(
    new Blob([buffer as ArrayBuffer], {
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    }),
  );
  const link = document.createElement("a");
  link.href = url;
  link.download = `membres-choloto-${localDateInput()}.xlsx`;
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
