import { type Proposal, periods } from "./publications";
const times: Record<string, number[][]> = {
  ny: [
    [14, 30],
    [22, 30],
  ],
  fl: [
    [13, 34],
    [21, 49],
  ],
  tx: [
    [10, 0],
    [12, 27],
    [18, 0],
    [22, 12],
  ],
  md: [
    [12, 30],
    [19, 56],
  ],
  ga: [
    [12, 29],
    [18, 59],
    [23, 34],
  ],
  tn: [
    [10, 28],
    [13, 28],
    [18, 28],
  ],
  pa: [
    [13, 35],
    [18, 59],
  ],
  nj: [
    [12, 59],
    [22, 57],
  ],
};
const sourcePeriods: Record<string, string[]> = {
  ny: ["midday", "evening"],
  fl: ["midday", "evening"],
  tx: ["morning", "day", "evening", "night"],
  md: ["midday", "evening"],
  ga: ["midday", "evening", "night"],
  tn: ["morning", "midday", "evening"],
  pa: ["day", "evening"],
  nj: ["midday", "evening"],
};
const codes: Record<string, string> = {
  newYork: "ny",
  florida: "fl",
  texas: "tx",
  maryland: "md",
  georgia: "ga",
  tennessee: "tn",
  pennsylvania: "pa",
  newJersey: "nj",
  new_jersey: "nj",
  "new-jersey": "nj",
};
const digits = (v: unknown) => String(v ?? "").replace(/\D/g, "");
export function proposal(
  code: string,
  period: string,
  date: string,
  numbers: string[],
  source: string,
): Proposal | null {
  code = codes[code] || code;
  const index = sourcePeriods[code]?.indexOf(period.toLowerCase()) ?? -1;
  const widths = code === "fl" ? [2, 3, 2, 2] : [3, 2, 2];
  if (
    index < 0 ||
    numbers.length !== widths.length ||
    numbers.some((n, i) => !new RegExp(`^\\d{${widths[i]}}$`).test(n)) ||
    !/^\d{4}-\d{2}-\d{2}/.test(date)
  )
    return null;
  const day = date.slice(0, 10),
    [hour, minute] = times[code][index];
  const time = new Date(
    `${day}T${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}:00`,
  );
  if (
    !Number.isFinite(time.getTime()) ||
    time.getDate() !== Number(day.slice(8))
  )
    return null;
  return {
    id: `official_${code}_${day.replaceAll("-", "")}_${period.toLowerCase()}`,
    code,
    period: periods[code][index],
    date: time,
    numbers,
    source,
  };
}
async function json(url: string, headers: Record<string, string> = {}) {
  const response = await fetch(url, {
    headers,
    cache: "no-store",
    signal: AbortSignal.timeout(18000),
  });
  if (!response.ok) throw new Error(`Source indisponible (${response.status})`);
  const value = await response.json();
  if (!Array.isArray(value)) throw new Error("Format de résultats invalide.");
  return value;
}
async function snapshot(name: string) {
  try {
    return await json(`${import.meta.env.BASE_URL}data/${name}`);
  } catch {
    return json(
      `https://louvenslouis.github.io/choloto-dashboard/data/${name}`,
    );
  }
}
async function newYork() {
  const sources = await Promise.allSettled([
    json(
      "https://data.ny.gov/resource/hsys-3def.json?$limit=7&$order=draw_date%20DESC",
    ),
    snapshot("official-new-york-results.json"),
  ]);
  const rows = sources.flatMap((result) =>
    result.status === "fulfilled" ? result.value : [],
  );
  if (!rows.length) throw new Error("Sources New York indisponibles.");
  return rows.flatMap((row) =>
    ["midday", "evening"].map((period) => {
      const pick4 = digits(row[`${period}_win_4`]);
      return proposal(
        "ny",
        period,
        row.draw_date,
        [digits(row[`${period}_daily`]), pick4.slice(0, 2), pick4.slice(2, 4)],
        row._choloto_source_name || "NY Open Data",
      );
    }),
  );
}
async function additional() {
  return (await snapshot("official-additional-lottery-results.json")).map(
    (row) => {
      const four = digits(row.pick4);
      return proposal(
        row.lottery,
        row.period,
        row.draw_date,
        [digits(row.pick3), four.slice(0, 2), four.slice(2, 4)],
        row.source_name || "Résultats officiels",
      );
    },
  );
}
async function florida() {
  const responses = await Promise.all(
    ["127", "104", "108"].map((id) =>
      json(
        `https://apim-website-prod-eastus.azure-api.net/drawgamesapp/getLatestDrawGames?id=${id}`,
        { "x-partner": "web" },
      ),
    ),
  );
  const draws = new Map<
    string,
    { date: string; period: string; values: string[] }
  >();
  responses.forEach((rows, index) =>
    rows.forEach((row) => {
      const raw = String(row.DrawDate),
        match = raw.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})/),
        date = match
          ? `${match[3]}-${match[1].padStart(2, "0")}-${match[2].padStart(2, "0")}`
          : raw.slice(0, 10);
      const type = String(row.DrawType).toLowerCase(),
        period = type.includes("mid")
          ? "midday"
          : type.includes("eve")
            ? "evening"
            : "";
      const value = (row.DrawNumbers || [])
        .filter((n: { NumberType: string }) => /^wn\d+$/i.test(n.NumberType))
        .sort(
          (a: { NumberType: string }, b: { NumberType: string }) =>
            Number(a.NumberType.slice(2)) - Number(b.NumberType.slice(2)),
        )
        .map((n: { NumberPick: unknown }) => digits(n.NumberPick))
        .join("");
      if (!period || value.length !== index + 2) return;
      const key = `${date}_${period}`,
        draw = draws.get(key) || { date, period, values: ["", "", ""] };
      draw.values[index] = value;
      draws.set(key, draw);
    }),
  );
  return [...draws.values()].map((d) =>
    proposal(
      "fl",
      d.period,
      d.date,
      [d.values[0], d.values[1], d.values[2].slice(0, 2), d.values[2].slice(2)],
      "Florida Lottery",
    ),
  );
}
export async function fetchOfficial() {
  const settled = await Promise.allSettled([
    newYork(),
    florida(),
    additional(),
  ]);
  const warnings: string[] = [],
    all: Proposal[] = [];
  settled.forEach((result, i) => {
    if (result.status === "fulfilled")
      all.push(...result.value.filter((p): p is Proposal => !!p));
    else
      warnings.push(
        `${["New York", "Floride", "Autres tirages"][i]} : ${result.reason.message}`,
      );
  });
  const latest = new Map<string, Proposal>();
  for (const p of all) {
    const key = `${p.code}_${p.period}`;
    if (!latest.has(key) || latest.get(key)!.date < p.date) latest.set(key, p);
  }
  return {
    proposals: [...latest.values()].sort(
      (a, b) => b.date.getTime() - a.date.getTime(),
    ),
    warnings,
  };
}
