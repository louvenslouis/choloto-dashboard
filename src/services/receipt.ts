import { asDate, type Row } from "./data";
export async function receiptBytes(row: Row) {
  const [{ PDFDocument, rgb }, fontkit] = await Promise.all([
    import("pdf-lib"),
    import("@pdf-lib/fontkit"),
  ]);
  const pdf = await PDFDocument.create();
  pdf.registerFontkit(fontkit.default);
  const assets = await Promise.all(
    ["fonts/Roboto-Regular.ttf", "fonts/Roboto-Bold.ttf", "logo.png"].map(
      async (path) => {
        const response = await fetch(`${import.meta.env.BASE_URL}${path}`);
        if (!response.ok) throw new Error("Impossible de charger le reçu.");
        return response.arrayBuffer();
      },
    ),
  );
  const regular = await pdf.embedFont(assets[0], { subset: true }),
    bold = await pdf.embedFont(assets[1], { subset: true }),
    logo = await pdf.embedPng(assets[2]);
  const page = pdf.addPage([595.28, 841.89]);
  const purple = rgb(0.396, 0.125, 0.553),
    ink = rgb(0.09, 0.075, 0.11),
    muted = rgb(0.396, 0.373, 0.412),
    white = rgb(1, 1, 1);
  const text = (
    value: unknown,
    x: number,
    top: number,
    size = 10,
    color = ink,
    heavy = false,
    max = 510,
  ) => {
    const font = heavy ? bold : regular;
    let label = String(value ?? "—");
    while (font.widthOfTextAtSize(label, size) > max && size > 6) size -= 0.25;
    page.drawText(label, {
      x,
      y: 842 - top - size,
      size,
      font,
      color,
      maxWidth: max,
      lineHeight: size * 1.4,
    });
  };
  const rect = (
    x: number,
    top: number,
    width: number,
    height: number,
    color = purple,
  ) => page.drawRectangle({ x, y: 842 - top - height, width, height, color });
  const gradient = (x: number, top: number, width: number, height: number) => {
    for (let i = 0; i < 100; i++) {
      const t = i / 99;
      rect(
        x + (i * width) / 100,
        top,
        width / 100 + 0.1,
        height,
        rgb(
          0.243 + (0.929 - 0.243) * t,
          0.043 + (0.31 - 0.043) * t,
          0.369 + (0.647 - 0.369) * t,
        ),
      );
    }
  };
  gradient(0, 0, 596, 30);
  gradient(0, 820, 596, 22);
  page.drawImage(logo, { x: 42, y: 842 - 110, width: 68, height: 68 });
  text("choloto.com", 42, 116, 13, ink, true);
  text("contact@choloto.com", 42, 137, 9);
  gradient(245, 60, 105, 42);
  text("REÇU", 264, 66, 25, white, true);
  text("Code de la fiche", 263, 110, 8, muted);
  text(row.receipt_code || `CH-${row.id}`, 213, 126, 8, purple, true, 170);
  page.drawCircle({ x: 520, y: 770, size: 28, color: rgb(0.14, 0.41, 0.91) });
  text("VIP", 506, 62, 16, white, true);
  text(
    String(row.user_display_name || "Membre CHOLOTO").toUpperCase(),
    395,
    114,
    10,
    ink,
    true,
    160,
  );
  text(row.user_email || "", 395, 132, 8, muted, false, 160);
  text(`Code : ${row.user_code || "—"}`, 395, 146, 8, purple, true, 160);
  const type =
    (
      {
        subscription: "Abonnement VIP",
        renewal: "Renouvellement VIP",
        adjustment: "Ajustement d’abonnement",
        cancellation: "Annulation",
      } as Record<string, string>
    )[row.transaction_type] || "Paiement";
  const amount =
      row.transaction_type === "cancellation"
        ? row.refunded_amount
        : row.amount,
    currency =
      row.transaction_type === "cancellation"
        ? row.refund_currency
        : row.currency;
  const total =
    amount == null
      ? "Non renseigné"
      : `${Number(amount).toLocaleString("fr-FR")} ${currency || ""}`;
  gradient(42, 192, 511, 29);
  ["Description", "Quantité", "Prix", "Total"].forEach((v, i) =>
    text(v, [54, 325, 390, 478][i], 201, 9, white, true),
  );
  text(type, 54, 244, 10, ink, true, 255);
  text("1", 343, 244);
  text(total, 378, 244, 9, ink, false, 85);
  text(total, 466, 244, 9, purple, true, 80);
  rect(380, 286, 173, 34);
  text(`Total : ${total}`, 394, 295, 12, white, true, 149);
  rect(42, 347, 511, 192, rgb(0.96, 0.937, 0.977));
  const date = (v: unknown) =>
    asDate(v)?.toLocaleDateString("fr-FR", { dateStyle: "long" }) ||
    "Non renseignée";
  [
    ["Référence en ligne", row.receipt_code || `CH-${row.id}`],
    ["Type d’opération", type],
    ["Date d’entrée", date(row.created_at)],
    ["Date d’expiration", date(row.new_end_sub)],
    ["Moyen de paiement", row.payment_method || "Non renseigné"],
    ["Montant enregistré", total],
  ].forEach(([label, value], i) => {
    text(label, 56, 358 + i * 30, 9, muted);
    text(value, 260, 358 + i * 30, 10, ink, true, 278);
  });
  text(
    row.transaction_type === "cancellation"
      ? "Annulation enregistrée."
      : "Votre accès V.I.P CHOLOTO est enregistré.",
    42,
    570,
    12,
    ink,
    true,
  );
  text("Merci pour votre confiance !", 42, 605, 14, purple, true);
  text(row.cancellation_reason || "", 42, 635, 10, muted, false, 500);
  rect(42, 690, 511, 64, rgb(0.96, 0.937, 0.977));
  text("CONDITIONS IMPORTANTES", 54, 699, 8, purple, true);
  text(
    "1. Toute demande de remboursement doit être effectuée dans les 24 heures suivant le paiement.",
    54,
    715,
    7.2,
    ink,
    false,
    485,
  );
  text(
    "Passé ce délai, aucun remboursement ne sera accordé.",
    65,
    726,
    7.2,
    ink,
    false,
    474,
  );
  text(
    "2. Le client reconnaît que CHOLOTO fournit des prédictions et qu’aucun résultat ni gain n’est garanti.",
    54,
    736,
    7.2,
    ink,
    false,
    485,
  );
  text(
    "3. Le client déclare être âgé de 18 ans ou plus.",
    54,
    746,
    7.2,
    ink,
    false,
    485,
  );
  text("CHOLOTO.COM", 42, 769, 11, purple, true);
  text(`Transaction : ${row.id}`, 42, 790, 8, muted, false, 510);
  pdf.setTitle(`Reçu ${row.receipt_code || row.id}`);
  pdf.setAuthor("CHOLOTO.COM");
  return pdf.save();
}
export async function exportReceipt(row: Row) {
  const bytes = await receiptBytes(row);
  const url = URL.createObjectURL(
    new Blob([bytes as BlobPart], { type: "application/pdf" }),
  );
  const link = document.createElement("a");
  link.href = url;
  link.download = `recu_choloto_${String(row.receipt_code || row.id)
    .replace(/[^a-zA-Z0-9_-]/g, "_")
    .toLowerCase()}.pdf`;
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
