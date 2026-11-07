import type { PDFFont, RGB } from "pdf-lib";
import { asDate, type Row } from "./data";
import { isCompensation } from "./payments";

const months = [
  "Janvier",
  "Février",
  "Mars",
  "Avril",
  "Mai",
  "Juin",
  "Juillet",
  "Août",
  "Septembre",
  "Octobre",
  "Novembre",
  "Décembre",
];
const shortMonths = [
  "JAN",
  "FÉV",
  "MAR",
  "AVR",
  "MAI",
  "JUN",
  "JUL",
  "AOÛ",
  "SEP",
  "OCT",
  "NOV",
  "DÉC",
];
const paymentLabels: Record<string, string> = {
  moncash: "MonCash",
  natcash: "Natcash",
  cash: "Espèces",
  stripe: "Carte / Stripe",
  zelle: "Zelle",
  cashapp: "CashApp",
  virement: "Virement",
};

function dateLabel(date: Date | null) {
  return date
    ? `${String(date.getDate()).padStart(2, "0")} ${shortMonths[date.getMonth()]} ${date.getFullYear()}`
    : "Non renseignée";
}

function periodLabel(start: Date | null, end: Date | null) {
  if (!start) return "";
  const first = months[start.getMonth()];
  if (
    !end ||
    (start.getFullYear() === end.getFullYear() &&
      start.getMonth() === end.getMonth())
  )
    return `${first} ${start.getFullYear()}`;
  return `${first}${start.getFullYear() === end.getFullYear() ? "" : " " + start.getFullYear()} - ${months[end.getMonth()]} ${end.getFullYear()}`;
}

// A receipt reference can be a single long Firestore ID with no word boundaries.
function wrapText(value: string, font: PDFFont, size: number, width: number) {
  const lines: string[] = [];
  let line = "";
  for (const word of value.trim().split(/\s+/u)) {
    const next = line ? line + " " + word : word;
    if (font.widthOfTextAtSize(next, size) <= width) {
      line = next;
      continue;
    }
    if (line) lines.push(line);
    line = "";
    for (const char of word) {
      if (font.widthOfTextAtSize(line + char, size) > width && line) {
        lines.push(line);
        line = "";
      }
      line += char;
    }
  }
  return [...lines, line];
}

type TextStyle = {
  size?: number;
  color?: RGB;
  bold?: boolean;
  align?: "left" | "center" | "right";
  lines?: number;
};

export async function receiptBytes(row: Row) {
  const [lib, fontkit] = await Promise.all([
    import("pdf-lib"),
    import("@pdf-lib/fontkit"),
  ]);
  const pdf = await lib.PDFDocument.create();
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
  const regular = await pdf.embedFont(assets[0], { subset: true });
  const bold = await pdf.embedFont(assets[1], { subset: true });
  const logo = await pdf.embedPng(assets[2]);
  const page = pdf.addPage(lib.PageSizes.A4);
  const { width, height } = page.getSize();
  const left = 42,
    right = width - left,
    inner = right - left;
  const rgb = (r: number, g: number, b: number) =>
    lib.rgb(r / 255, g / 255, b / 255);
  const purple = rgb(101, 32, 141),
    deep = rgb(62, 11, 94),
    pink = rgb(237, 79, 165),
    red = rgb(217, 47, 69),
    ink = rgb(23, 19, 28),
    muted = rgb(101, 95, 105),
    pale = rgb(245, 239, 249),
    rule = rgb(221, 216, 225),
    white = rgb(255, 255, 255);

  // Coordinates are measured from the top of the original A4 receipt.
  function text(
    value: string,
    x: number,
    baseline: number,
    w: number,
    style: TextStyle = {},
  ) {
    const font = style.bold ? bold : regular;
    let size = style.size ?? 10;
    const limit = style.lines ?? 1;
    let lines = wrapText(value, font, size, w);
    while (lines.length > limit && size > 4) {
      size -= 0.25;
      lines = wrapText(value, font, size, w);
    }
    lines.forEach((line, i) => {
      const space = w - font.widthOfTextAtSize(line, size);
      const offset =
        style.align === "right"
          ? space
          : style.align === "center"
            ? space / 2
            : 0;
      page.drawText(line, {
        x: x + offset,
        y: height - baseline - i * size * 1.17,
        font,
        size,
        color: style.color ?? ink,
      });
    });
    return (lines.length - 1) * size * 1.17;
  }

  // Clip the gradient to the same rounded outline as the Flutter template.
  const shadings = pdf.context.obj({});
  page.node
    .normalizedEntries()
    .Resources.set(lib.PDFName.of("Shading"), shadings);
  function gradient(
    name: string,
    x: number,
    top: number,
    w: number,
    h: number,
    colors: RGB[],
    radius = 0,
    bottomRadius = radius,
  ) {
    const stops = colors.map((c) => [c.red, c.green, c.blue]);
    const segments = stops.slice(1).map((stop, i) => ({
      FunctionType: 2,
      Domain: [0, 1],
      C0: stops[i],
      C1: stop,
      N: 1,
    }));
    const fn =
      segments.length === 1
        ? segments[0]
        : {
            FunctionType: 3,
            Domain: [0, 1],
            Functions: segments,
            Bounds: [0.5],
            Encode: [0, 1, 0, 1],
          };
    const key = lib.PDFName.of(name);
    shadings.set(
      key,
      pdf.context.register(
        pdf.context.obj({
          ShadingType: 2,
          ColorSpace: "DeviceRGB",
          Coords: [x, 0, x + w, 0],
          Function: fn,
          Extend: [true, true],
        }),
      ),
    );
    const y = height - top,
      bottom = y - h,
      end = x + w,
      k = 0.552285;
    const r = radius,
      b = bottomRadius;
    page.pushOperators(
      lib.pushGraphicsState(),
      lib.moveTo(x + r, y),
      lib.lineTo(end - r, y),
      lib.appendBezierCurve(end - r + k * r, y, end, y - r + k * r, end, y - r),
      lib.lineTo(end, bottom + b),
      lib.appendBezierCurve(
        end,
        bottom + b - k * b,
        end - b + k * b,
        bottom,
        end - b,
        bottom,
      ),
      lib.lineTo(x + b, bottom),
      lib.appendBezierCurve(
        x + b - k * b,
        bottom,
        x,
        bottom + b - k * b,
        x,
        bottom + b,
      ),
      lib.lineTo(x, y - r),
      lib.appendBezierCurve(x, y - r + k * r, x + r - k * r, y, x + r, y),
      lib.closePath(),
      lib.clip(),
      lib.endPath(),
      lib.PDFOperator.of(lib.PDFOperatorNames.ShadingFill, [key]),
      lib.popGraphicsState(),
    );
  }
  function panel(
    x: number,
    top: number,
    w: number,
    h: number,
    r: number,
    color: RGB,
    border = false,
  ) {
    page.drawSvgPath(
      `M ${r} 0 H ${w - r} Q ${w} 0 ${w} ${r} V ${h - r} Q ${w} ${h} ${w - r} ${h} H ${r} Q 0 ${h} 0 ${h - r} V ${r} Q 0 0 ${r} 0 Z`,
      {
        x,
        y: height - top,
        color,
        ...(border ? { borderColor: rule, borderWidth: 0.7 } : {}),
      },
    );
  }
  function divider(x: number, top: number, w: number) {
    page.drawLine({
      start: { x, y: height - top },
      end: { x: x + w, y: height - top },
      color: rule,
      thickness: 0.7,
    });
  }

  const receipt = String(row.receipt_code || `CH-${row.id}`);
  const compensation = isCompensation(row);
  const cancellation = row.transaction_type === "cancellation";
  const operation = compensation
    ? "Compensation"
    : (
        {
          subscription: "Activation",
          renewal: "Prolongation",
          adjustment: "Modification",
          cancellation: "Annulation",
        } as Record<string, string>
      )[row.transaction_type] || "Paiement";
  const amount = cancellation ? row.refunded_amount : row.amount;
  const currency = cancellation ? row.refund_currency : row.currency;
  const total = compensation
    ? "Sans frais"
    : amount == null
      ? "Non renseigné"
      : [Number(amount).toLocaleString("fr-FR"), currency]
          .filter(Boolean)
          .join(" ");
  const issued = asDate(row.created_at),
    expires = asDate(row.new_end_sub);

  gradient("Top", 0, 0, width, 30, [deep, purple, pink]);
  gradient("Bottom", 0, height - 22, width, 22, [pink, purple, deep]);
  page.drawSvgPath("M -29 22.6 L 159.4 49.1 L 162.7 25.4 L -25.4 -1.1 Z", {
    x: 0,
    y: height,
    color: purple,
  });
  page.drawSvgPath("M 419.5 817.2 L 628 842.4 L 631.1 816.6 L 422.6 791.4 Z", {
    x: 0,
    y: height,
    color: purple,
  });
  page.drawImage(logo, { x: left, y: height - 110, width: 68, height: 68 });
  text("choloto.com", left, 128, 158, { size: 13, bold: true });
  text("contact@choloto.com", left, 141, 158, { size: 7.3, bold: true });
  gradient("Title", width / 2 - 51.5, 60, 103, 48, [deep, pink], 9);
  text("REÇU", 200, 92.2, width - 400, {
    size: 25,
    bold: true,
    align: "center",
    color: white,
  });
  text("Code de la fiche", 200, 122.3, width - 400, {
    size: 7.5,
    align: "center",
    color: muted,
  });
  const headerWrap = text(receipt, 200, 133.6, width - 400, {
    size: 8,
    bold: true,
    color: purple,
    lines: 2,
    align: bold.widthOfTextAtSize(receipt, 8) > width - 400 ? "left" : "center",
  });

  page.drawCircle({
    x: right - 29,
    y: height - 71,
    size: 29,
    color: rgb(36, 104, 232),
    borderWidth: 3,
    borderColor: white,
  });
  text("VIP", right - 58, 76.5, 58, {
    size: 16,
    color: white,
    bold: true,
    align: "center",
  });
  const rightAlign = { align: "right" } as const;
  const nameWrap = text(
    String(row.user_display_name || "Membre CHOLOTO").toUpperCase(),
    right - 158,
    116.7,
    158,
    { ...rightAlign, size: 10.5, bold: true, lines: 2 },
  );
  let memberY = 129.2 + nameWrap;
  text("Abonné CHOLOTO", right - 158, memberY, 158, {
    ...rightAlign,
    size: 7.3,
  });
  if (row.user_code) {
    memberY += 10;
    memberY += text(
      `Code personnel : ${row.user_code}`,
      right - 158,
      memberY,
      158,
      { ...rightAlign, size: 7.3, bold: true, color: purple, lines: 2 },
    );
  }
  if (row.user_email) {
    memberY += 10;
    memberY += text(String(row.user_email), right - 158, memberY, 158, {
      ...rightAlign,
      size: 7.3,
      color: muted,
      lines: 5,
    });
  }
  const headerBottom = Math.max(141, 133.6 + headerWrap, memberY);
  const tableTop = Math.max(179.3, headerBottom + 12);
  gradient("Table", left, tableTop, inner, 26, [purple, pink], 9, 0);
  const columnWidths = [0.5, 0.1, 0.2, 0.2].map(
    (fraction) => (inner - 24) * fraction,
  );
  const cells = [`${operation} abonnement VIP CHOLOTO`, "1", total, total];
  let columnX = left + 12;
  ["Description", "Quantité", "Prix", "Total"].forEach((label, i) => {
    const align = i === 0 ? "left" : "center";
    text(label, columnX, tableTop + 16.3, columnWidths[i], {
      size: 9.5,
      bold: true,
      color: white,
      align,
    });
    text(cells[i], columnX, tableTop + 53.8, columnWidths[i], {
      size: i === 0 ? 10 : 8.5,
      bold: i === 0 || i === 3,
      color: i === 3 ? red : ink,
      align,
    });
    columnX += columnWidths[i];
  });
  divider(left, tableTop + 75.3, inner);
  const banner = `Total : ${total}`,
    bannerWidth = Math.min(inner, bold.widthOfTextAtSize(banner, 12) + 40);
  panel(right - bannerWidth, tableTop + 91.3, bannerWidth, 30.1, 12, purple);
  text(banner, right - bannerWidth + 20, tableTop + 110.4, bannerWidth - 40, {
    size: 12,
    bold: true,
    color: white,
    align: "center",
  });

  const rows = [
    ["Référence en ligne", receipt],
    ["Type d’opération", operation],
    ["Date d'entrée", dateLabel(issued)],
    ["Date d'expiration", dateLabel(expires)],
    [
      "Moyen de paiement",
      paymentLabels[row.payment_method] ||
        row.payment_method ||
        "Non renseigné",
    ],
    ["Montant enregistré", total],
  ];
  const valueWidth = ((inner - 40) * 2) / 3;
  const termsTop = 675;
  const reason = String(row.cancellation_reason || "").trim();
  const reasonLines = reason ? wrapText(reason, regular, 8, inner).length : 0;
  const rowHeights = rows.map(
    ([, value]) =>
      35.15 + (wrapText(value, bold, 9.5, valueWidth).length > 1 ? 11.1 : 0),
  );
  const detailsTop = tableTop + 149.4;
  // Reserve room for multiline member details and a cancellation reason
  // by taking the extra space from the padding of the six detail rows.
  const naturalHeight = rowHeights.reduce((sum, h) => sum + h, 8);
  const messageHeight = reason ? 52 + (reasonLines - 1) * 9.36 : 39.9;
  const overflow = Math.max(
    0,
    detailsTop + naturalHeight + 31.7 + messageHeight + 12 - termsTop,
  );
  const trim = Math.min(18, overflow / rows.length);
  const detailsHeight = naturalHeight - trim * rows.length;
  panel(left, detailsTop, inner, detailsHeight, 10, pale);
  let rowTop = detailsTop + 4;
  rows.forEach(([label, value], i) => {
    const last = i === rows.length - 1;
    text(
      label,
      left + 14,
      rowTop + 21.2 + (rowHeights[i] - 35.15 - trim) / 2,
      148,
      {
        size: 9.5,
        bold: true,
      },
    );
    text(value, right - 14 - valueWidth, rowTop + 21.2 - trim / 2, valueWidth, {
      size: 9.5,
      bold: true,
      align: "right",
      lines: 2,
      color: last ? (amount != null && !compensation ? red : muted) : ink,
    });
    rowTop += rowHeights[i] - trim;
    if (!last) divider(left + 14, rowTop, inner - 28);
  });

  const messageTop = detailsTop + detailsHeight + 31.7;
  text(
    cancellation
      ? "Annulation enregistrée."
      : "Félicitations, votre accès au groupe V.I.P CHOLOTO est maintenant enregistré.",
    left,
    messageTop,
    inner,
    { size: 10.5, bold: true },
  );
  const confirmation = cancellation
    ? amount == null
      ? "Votre abonnement a été annulé."
      : `Remboursement enregistré : ${total}.`
    : compensation
      ? "La compensation de votre abonnement a été enregistrée sans frais."
      : amount != null
        ? `Le paiement de ${total} a été enregistré.`
        : (
            {
              Activation:
                "L’activation de votre abonnement a été enregistrée avec succès.",
              Prolongation:
                "La prolongation de votre abonnement a été enregistrée avec succès.",
              Modification:
                "La modification de votre abonnement a été enregistrée avec succès.",
            } as Record<string, string>
          )[operation] || "Votre transaction a été enregistrée.";
  text(confirmation, left, messageTop + 15.3, inner, {
    size: 10.5,
    bold: true,
    color: red,
  });
  text("Merci pour votre confiance !", left, messageTop + 39.9, inner, {
    size: 14,
    bold: true,
    color: purple,
  });

  if (reason) {
    const baseline = messageTop + 52;
    text(reason, left, baseline, inner, {
      size: 8,
      color: muted,
      lines: reasonLines,
    });
  }
  panel(left, termsTop, inner, 72.3, 8, pale, true);
  text("CONDITIONS IMPORTANTES", 54, 691.5, 480, {
    size: 8,
    bold: true,
    color: purple,
  });
  const terms = [
    "Toute demande de remboursement doit être effectuée dans les 24 heures suivant le paiement. Passé ce délai, aucun remboursement ne sera accordé.",
    "Le client reconnaît que CHOLOTO fournit des prédictions et qu’aucun résultat ni gain n’est garanti.",
    "Le client déclare être âgé de 18 ans ou plus.",
  ];
  terms.forEach((term, i) => {
    const baseline = [705, 726.2, 737.6][i];
    text(`${i + 1}.`, 54, baseline, 15, {
      size: 7.2,
      bold: true,
      color: purple,
    });
    text(term, 69, baseline, right - 12 - 69, { size: 7.2, lines: 2 });
  });
  text(periodLabel(issued, expires), left, 805.5, 380, {
    size: 10,
    bold: true,
    color: purple,
  });
  text("Termes et conditions", right - 90, 769.7, 90, {
    size: 9,
    bold: true,
    color: purple,
    align: "center",
  });
  page.drawImage(logo, {
    x: right - 89.5,
    y: height - 807.9,
    width: 34,
    height: 34,
  });
  text("CHOLOTO", right - 50.5, 789.6, 51, { size: 11, bold: true });
  text("Administration", right - 50.5, 799.1, 51, { size: 7.3, color: muted });
  pdf.setTitle(`Reçu ${receipt}`);
  pdf.setAuthor("CHOLOTO.COM");
  pdf.setCreator("CHOLOTO Dashboard");
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
