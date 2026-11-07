import { asDate, type Row } from "./data";

export type BingoItem = {
  valeur: string;
  tirage: string;
  boul: string;
  periode: string;
};
export type BingoSuggestion = {
  id: string;
  date: Date;
  predictionId: string;
  items: BingoItem[];
};
const names: Record<string, string> = {
  ny: "NEW YORK",
  fl: "FLORIDA",
  ga: "GEORGIA",
  nj: "NEW JERSEY",
  tx: "TEXAS",
  tn: "TENNESSEE",
  md: "MARYLAND",
  pa: "PENNSYLVANIA",
};
const calendar = new Intl.DateTimeFormat("en-CA", {
  timeZone: "America/Port-au-Prince",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
});
const day = (date: Date) => calendar.format(date);
function period(value: string) {
  if (["MIDDAY", "DAY", "02:30 PM", "01:34 PM"].includes(value)) return "Midi";
  if (["EVENING", "NIGHT", "10:30 PM", "09:49 PM"].includes(value))
    return "Soir";
  return null;
}
function values(row: Row, keys: string[], width: number) {
  return keys
    .flatMap((key) => (Array.isArray(row[key]?.boul) ? row[key].boul : []))
    .flatMap((value: unknown) =>
      typeof value === "string" ? value.match(/\d+/g) || [] : [],
    )
    .filter((value: string) => value.length === width);
}
const reverse = (s: string) => s.split("").reverse().join("");
function marriagePair(value: unknown) {
  if (typeof value !== "string") return null;
  const match = /^\s*(\d{2})\s*[*x]\s*(\d{2})\s*$/i.exec(value);
  return match ? [match[1], match[2]] : null;
}
const pairKey = (pair: string[]) => [...pair].sort().join("X");
function matchesMarriage([a, b]: string[], first: string, second: string) {
  // Published marriages support at most one reversed ball.
  return (
    (a === first && (b === second || reverse(b) === second)) ||
    (reverse(a) === first && b === second)
  );
}
function lot(value: string | undefined) {
  const label = value?.trim().toLowerCase() ?? "";
  if (/^(1|premier)/.test(label)) return "1er lot";
  if (/^2(e|eme|ème)/.test(label)) return "2e lot";
  if (/^3(e|eme|ème)/.test(label)) return "3e lot";
  if (label === "maryaj") return "mariage";
  return label;
}

// Suggestions describe observed wins, never predict future draws.
export function suggestBingo(
  draws: Row[],
  predictions: Row[],
  published: Row[],
  now = new Date(),
): BingoSuggestion[] {
  const suggestions: BingoSuggestion[] = [];
  const seen = new Set<string>();
  for (const draw of [...draws].sort(
    (a, b) =>
      (asDate(b.date)?.getTime() || 0) - (asDate(a.date)?.getTime() || 0),
  )) {
    if (published.some((b) => b.id === `suggested_${draw.id}`)) continue;
    const date = asDate(draw.date),
      session = period(draw.periode);
    if (
      !date ||
      !session ||
      !names[draw.tirage] ||
      date > now ||
      now.getTime() - date.getTime() > 48 * 3600000
    )
      continue;
    const numbers: unknown = draw.numeros;
    const widths = draw.tirage === "fl" ? [2, 3, 2, 2] : [3, 2, 2];
    if (
      !Array.isArray(numbers) ||
      numbers.length !== widths.length ||
      numbers.some(
        (n, i) =>
          typeof n !== "string" || !new RegExp(`^\\d{${widths[i]}}$`).test(n),
      )
    )
      continue;
    const prediction = predictions
      .filter((p) => {
        const time = asDate(p.date);
        return (
          time &&
          time < date &&
          day(time) === day(date) &&
          p.periode === session
        );
      })
      .sort((a, b) => asDate(b.date)!.getTime() - asDate(a.date)!.getTime())[0];
    if (!prediction) continue;
    const offset = draw.tirage === "fl" ? 1 : 0;
    const pick3 = numbers[offset] as string;
    const balls = [
      pick3.slice(-2),
      numbers[offset + 1],
      numbers[offset + 2],
    ] as string[];
    const selected = values(prediction, ["boloto", "favori", "soutni"], 2);
    const items: BingoItem[] = [];
    const add = (
      valeur: string,
      boul: string,
      marriageAliases?: Set<string>,
    ) => {
      const item = {
        valeur,
        boul,
        tirage: names[draw.tirage],
        periode: session,
      };
      const key = `${day(date)}:${draw.tirage}:${draw.periode}:${valeur}:${marriageAliases ? pairKey(boul.split("X")) : boul}`;
      const duplicate = published.some((b) => {
        const time = asDate(b.date);
        // Legacy evening wins were sometimes posted the next morning.
        if (
          !time ||
          time < date ||
          time.getTime() - date.getTime() > 18 * 3600000
        )
          return false;
        return (
          Array.isArray(b.dataStack) &&
          b.dataStack.some(
            (v: BingoItem) =>
              v.tirage?.trim().toUpperCase() === item.tirage &&
              v.periode === session &&
              lot(v.valeur) === lot(valeur) &&
              (marriageAliases
                ? marriageAliases.has(pairKey(marriagePair(v.boul) ?? []))
                : v.boul?.trim() === boul),
          )
        );
      });
      if (!duplicate && !seen.has(key)) {
        items.push(item);
        seen.add(key);
      }
    };
    balls.forEach((ball, i) => {
      if (selected.some((n) => n === ball || reverse(n) === ball))
        add(["1er lot", "2e lot", "3e lot"][i], ball);
    });
    if (values(prediction, ["chif3"], 3).includes(pick3)) add("LOTO 3", pick3);
    const pick4 = balls[1] + balls[2];
    if (values(prediction, ["chif4"], 4).includes(pick4)) add("LOTO 4", pick4);
    if (Array.isArray(prediction.mariage?.boul)) {
      const pairs = prediction.mariage.boul.map(marriagePair);
      // The historical publications confirm lots 1+2 and 2+3.
      for (const [first, second] of [
        [balls[0], balls[1]],
        [balls[1], balls[2]],
      ]) {
        const aliases = new Set<string>();
        for (const pair of pairs) {
          if (
            pair &&
            (matchesMarriage(pair, first, second) ||
              matchesMarriage(pair, second, first))
          )
            aliases.add(pairKey(pair));
        }
        if (aliases.size) {
          // Older posts used either the predicted pair or the drawn pair.
          aliases.add(pairKey([first, second]));
          add("MARIAGE", `${first}X${second}`, aliases);
        }
      }
    }
    if (items.length)
      suggestions.push({
        id: draw.id,
        date,
        predictionId: prediction.id,
        items,
      });
  }
  return suggestions;
}
