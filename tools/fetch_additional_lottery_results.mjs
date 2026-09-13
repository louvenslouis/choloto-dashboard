import {mkdir, writeFile} from "node:fs/promises";
import {dirname, resolve} from "node:path";

const OUTPUT_ARGUMENT = process.argv[2];
const DEPLOYED_SNAPSHOT =
  "https://louvenslouis.github.io/choloto-dashboard/data/" +
  "official-additional-lottery-results.json";
const JINA_READER = "https://r.jina.ai/http://";

if (!OUTPUT_ARGUMENT) {
  throw new Error(
    "Usage: node fetch_additional_lottery_results.mjs <output.json>",
  );
}

const sources = await Promise.allSettled([
  fetchTexas(),
  fetchNewJersey(),
  fetchTennessee(),
  fetchMaryland(),
  fetchGeorgia(),
  fetchPennsylvania(),
]);
const sourceNames = [
  "Texas",
  "New Jersey",
  "Tennessee",
  "Maryland",
  "Georgia",
  "Pennsylvania",
];

const freshRows = [];
sources.forEach((result, index) => {
  if (result.status === "fulfilled") {
    freshRows.push(...result.value);
  } else {
    console.warn(
      `${sourceNames[index]} unavailable: ${readableError(result.reason)}`,
    );
  }
});

const previousRows = await fetchPreviousSnapshot();
const rows = mergeRows(previousRows, freshRows);
if (rows.length === 0) {
  throw new Error("All additional lottery sources are unavailable");
}

const outputPath = resolve(OUTPUT_ARGUMENT);
await mkdir(dirname(outputPath), {recursive: true});
await writeFile(outputPath, `${JSON.stringify(rows, null, 2)}\n`, "utf8");
console.log(
  `Wrote ${rows.length} official/verified lottery result rows to ${outputPath}`,
);

async function fetchTexas() {
  const slots = ["morning", "day", "evening", "night"];
  const rows = [];
  await Promise.all(slots.map(async (period) => {
    const [pick3Text, pick4Text] = await Promise.all([
      requestText(texasUrl("Pick_3", `pick3${period}.csv`)),
      requestText(texasUrl("Daily_4", `daily4${period}.csv`)),
    ]);
    const pick3 = parseTexasCsv(pick3Text, 3);
    const pick4 = parseTexasCsv(pick4Text, 4);
    for (const [drawDate, number3] of pick3) {
      const number4 = pick4.get(drawDate);
      if (!number4) continue;
      rows.push(resultRow({
        lottery: "tx",
        period,
        drawDate,
        pick3: number3,
        pick4: number4,
        sourceName: "Texas Lottery",
        sourceUrl:
          "https://www.texaslottery.com/export/sites/lottery/Games/" +
          "Pick_3/Winning_Numbers/",
      }));
    }
  }));
  return rows;
}

function texasUrl(game, file) {
  return "https://www.texaslottery.com/export/sites/lottery/Games/" +
    `${game}/Winning_Numbers/${file}`;
}

function parseTexasCsv(text, length) {
  const parsed = [];
  for (const line of text.trim().split(/\r?\n/)) {
    const values = line.split(",");
    if (values.length < 4 + length) continue;
    const month = Number(values[1]);
    const day = Number(values[2]);
    const year = Number(values[3]);
    const number = values.slice(4, 4 + length).join("");
    const drawDate = isoDate(year, month, day);
    if (drawDate && isDigits(number, length)) parsed.push([drawDate, number]);
  }
  return new Map(parsed.slice(-14));
}

async function fetchNewJersey() {
  const url = new URL(
    "https://njs-cdn.lotteryservices.com/api/v2/draw-games/draws/",
  );
  url.searchParams.set("previous-draws", "10");
  url.searchParams.set("next-draws", "0");
  url.searchParams.set("game-names", "Pick 3,Pick 4");
  const payload = await requestJson(url);
  if (!Array.isArray(payload.draws)) throw new Error("invalid NJ response");

  const games = new Map();
  for (const draw of payload.draws) {
    if (!["Pick 3", "Pick 4"].includes(draw.gameName) ||
        draw.status !== "CLOSED") {
      continue;
    }
    const regular = Array.isArray(draw.results) ?
      draw.results.find((result) => result.drawType === "Regular") : null;
    const number = regular?.primary?.[0];
    const length = draw.gameName === "Pick 3" ? 3 : 4;
    if (!isDigits(number, length)) continue;
    const drawDate = dateInTimeZone(draw.drawTime, "America/New_York");
    const period = String(draw.name || "").toLowerCase();
    if (!drawDate || !["midday", "evening"].includes(period)) continue;
    const key = `${drawDate}_${period}`;
    const game = games.get(key) || {drawDate, period};
    game[length === 3 ? "pick3" : "pick4"] = number;
    games.set(key, game);
  }

  return completeGames(games, "nj", "New Jersey Lottery",
    "https://www.njlottery.com/en-us/drawgames.html");
}

async function fetchTennessee() {
  const feedUrl =
    "https://www.youtube.com/feeds/videos.xml?" +
    "channel_id=UCjZL1HBaSxyhUs4ASqfuRrQ";
  const xml = await requestText(feedUrl);
  const rows = [];
  for (const entry of xml.matchAll(/<entry>([\s\S]*?)<\/entry>/g)) {
    const body = entry[1];
    const title = firstMatch(body, /<title>([\s\S]*?)<\/title>/);
    const titleMatch =
      /(Morning|Midday|Evening)_C3_C4_WB (\d{2})\/(\d{2})\/(\d{4})/i
        .exec(title);
    if (!titleMatch) continue;
    const description = firstMatch(
      body,
      /<media:description>([\s\S]*?)<\/media:description>/,
    );
    const pick3Digits = extractParenthesizedDigits(
      firstMatch(description, /cash3_wildball([^\n<]*)/i),
    );
    const pick4Digits = extractParenthesizedDigits(
      firstMatch(description, /cash4_wildball([^\n<]*)/i),
    );
    if (pick3Digits.length < 3 || pick4Digits.length < 4) continue;
    const drawDate = isoDate(
      Number(titleMatch[4]),
      Number(titleMatch[2]),
      Number(titleMatch[3]),
    );
    const videoUrl = firstMatch(
      body,
      /<link rel="alternate" href="([^"]+)"/,
    );
    rows.push(resultRow({
      lottery: "tn",
      period: titleMatch[1].toLowerCase(),
      drawDate,
      pick3: pick3Digits.slice(0, 3).join(""),
      pick4: pick4Digits.slice(0, 4).join(""),
      sourceName: "Tennessee Lottery · YouTube officiel",
      sourceUrl: videoUrl || feedUrl,
    }));
  }
  if (rows.length === 0) throw new Error("no Tennessee Cash 3/4 entries");
  return rows;
}

async function fetchMaryland() {
  const officialUrl =
    "https://www.mdlottery.com/wp-json/wp/v2/pages?" +
    "slug=pick-3-pick-4-pick-5";
  let text;
  try {
    text = await requestText(officialUrl);
  } catch (_) {
    text = await requestText(`${JINA_READER}${officialUrl.slice(8)}`);
  }
  const jsonText = text.includes("Markdown Content:") ?
    text.slice(text.indexOf("Markdown Content:") + 17).trim() : text;
  const payload = JSON.parse(jsonText);
  const html = payload?.[0]?.content?.rendered;
  if (typeof html !== "string") throw new Error("invalid Maryland response");
  const pick3 = parseMarylandGame(html, "pick-3", 3);
  const pick4 = parseMarylandGame(html, "pick-4", 4);
  return joinGameMaps(
    pick3,
    pick4,
    "md",
    "Maryland Lottery",
    "https://www.mdlottery.com/games/pick-3-pick-4-pick-5/",
  );
}

function parseMarylandGame(html, className, length) {
  const section = firstMatch(
    html,
    new RegExp(
      `<div class="single-winning-numbers ${className}">` +
      "([\\s\\S]*?)<p class=\"past-results\">",
    ),
  );
  const dateMatch = /<p>(\d{2})\/(\d{2})\/(\d{2})<\/p>/.exec(section);
  if (!dateMatch) return new Map();
  const drawDate = isoDate(
    2000 + Number(dateMatch[3]),
    Number(dateMatch[1]),
    Number(dateMatch[2]),
  );
  const result = new Map();
  for (const match of section.matchAll(
    /result-drawing-row (midday|evening)[\s\S]*?<ul class="balls">([\s\S]*?)<\/ul>/g,
  )) {
    const digits = [...match[2].matchAll(/<li(?: class="drawn")?>(\d)<\/li>/g)]
      .map((item) => item[1])
      .join("");
    if (isDigits(digits, length)) {
      result.set(`${drawDate}_${match[1]}`, digits);
    }
  }
  return result;
}

async function fetchGeorgia() {
  const officialUrl =
    "https://mapi.galottery.com/en-us/winning-numbers.html";
  let text;
  try {
    text = await requestText(officialUrl);
  } catch (_) {
    text = await requestText(`${JINA_READER}${officialUrl.slice(8)}`);
  }
  const cash3Section = between(text, "drawgames.play Cash 3",
    "drawgames.play Cash 4");
  const cash4Section = between(text, "drawgames.play Cash 4",
    "drawgames.play Cash Pop");
  const pick3 = parseGeorgiaGame(cash3Section, 3);
  const pick4 = parseGeorgiaGame(cash4Section, 4);
  return joinGameMaps(
    pick3,
    pick4,
    "ga",
    "Georgia Lottery",
    officialUrl,
  );
}

function parseGeorgiaGame(text, length) {
  const result = new Map();
  const pattern =
    /(MIDDAY|EVENING|NIGHT)\s+(\d{2})\/(\d{2})\/(\d{4})\s+((?:_\d_\s*){3,4})/gi;
  for (const match of text.matchAll(pattern)) {
    const number = (match[5].match(/\d/g) || []).join("");
    const drawDate = isoDate(Number(match[4]), Number(match[2]),
      Number(match[3]));
    if (isDigits(number, length)) {
      result.set(`${drawDate}_${match[1].toLowerCase()}`, number);
    }
  }
  return result;
}

async function fetchPennsylvania() {
  const [pick3Text, pick4Text] = await Promise.all([
    requestText(`${JINA_READER}www.lotterypost.com/results/pa/pick3`),
    requestText(`${JINA_READER}www.lotterypost.com/results/pa/pick4`),
  ]);
  const pick3 = parsePennsylvaniaGame(pick3Text, "Pick 3", 3);
  const pick4 = parsePennsylvaniaGame(pick4Text, "Pick 4", 4);
  return joinGameMaps(
    pick3,
    pick4,
    "pa",
    "Lottery Post · secours Pennsylvania",
    "https://www.lotterypost.com/results/pa/pick3",
  );
}

function parsePennsylvaniaGame(text, gameName, length) {
  const result = new Map();
  for (const period of ["Day", "Evening"]) {
    const pattern = new RegExp(
      `## ${gameName} ${period}\\s+` +
      "([A-Za-z]+, [A-Za-z]+ \\d{1,2}, \\d{4})\\s+" +
      `${period}\\s+((?:\\*\\s+\\d\\s*){${length}})`,
    );
    const match = pattern.exec(text);
    if (!match) continue;
    const number = (match[2].match(/\d/g) || []).join("");
    const drawDate = parseEnglishDate(match[1]);
    if (drawDate && isDigits(number, length)) {
      result.set(`${drawDate}_${period.toLowerCase()}`, number);
    }
  }
  return result;
}

function joinGameMaps(pick3, pick4, lottery, sourceName, sourceUrl) {
  const rows = [];
  for (const [key, number3] of pick3) {
    const number4 = pick4.get(key);
    if (!number4) continue;
    const separator = key.lastIndexOf("_");
    rows.push(resultRow({
      lottery,
      period: key.slice(separator + 1),
      drawDate: key.slice(0, separator),
      pick3: number3,
      pick4: number4,
      sourceName,
      sourceUrl,
    }));
  }
  if (rows.length === 0) throw new Error(`no complete ${lottery} results`);
  return rows;
}

function completeGames(games, lottery, sourceName, sourceUrl) {
  const rows = [];
  for (const game of games.values()) {
    if (!isDigits(game.pick3, 3) || !isDigits(game.pick4, 4)) continue;
    rows.push(resultRow({lottery, sourceName, sourceUrl, ...game}));
  }
  if (rows.length === 0) throw new Error(`no complete ${lottery} results`);
  return rows;
}

function resultRow({
  lottery,
  period,
  drawDate,
  pick3,
  pick4,
  sourceName,
  sourceUrl,
}) {
  if (!drawDate || !isDigits(pick3, 3) || !isDigits(pick4, 4)) {
    throw new Error(`invalid ${lottery} ${period} result`);
  }
  return {
    lottery,
    period,
    draw_date: drawDate,
    pick3,
    pick4,
    source_name: sourceName,
    source_url: sourceUrl,
  };
}

async function fetchPreviousSnapshot() {
  try {
    const rows = await requestJson(DEPLOYED_SNAPSHOT);
    return Array.isArray(rows) ? rows : [];
  } catch (_) {
    return [];
  }
}

function mergeRows(previous, fresh) {
  const merged = new Map();
  for (const row of [...previous, ...fresh]) {
    if (!row || !row.lottery || !row.period || !row.draw_date ||
        !isDigits(row.pick3, 3) || !isDigits(row.pick4, 4)) {
      continue;
    }
    merged.set(`${row.lottery}_${row.draw_date}_${row.period}`, row);
  }
  return [...merged.values()]
    .sort((left, right) => {
      const byDate = String(right.draw_date).localeCompare(left.draw_date);
      return byDate || String(left.lottery).localeCompare(right.lottery) ||
        String(left.period).localeCompare(right.period);
    })
    .filter((row, index, allRows) => {
      const sameLotteryBefore = allRows.slice(0, index)
        .filter((candidate) => candidate.lottery === row.lottery).length;
      return sameLotteryBefore < 40;
    });
}

async function requestText(url) {
  const host = new URL(url).host;
  const response = await fetch(url, {
    headers: {
      Accept: host === "r.jina.ai" ?
        "text/plain" : "text/html,application/json,text/csv,application/xml",
      "User-Agent": "CHOLOTO-Dashboard/1.0",
    },
    signal: AbortSignal.timeout(20000),
  });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.text();
}

async function requestJson(url) {
  const text = await requestText(url);
  return JSON.parse(text);
}

function dateInTimeZone(timestamp, timeZone) {
  if (!Number.isFinite(Number(timestamp))) return null;
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date(Number(timestamp)));
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return isoDate(Number(values.year), Number(values.month), Number(values.day));
}

function isoDate(year, month, day) {
  const date = new Date(Date.UTC(year, month - 1, day));
  if (date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1 ||
      date.getUTCDate() !== day) {
    return null;
  }
  return `${String(year).padStart(4, "0")}-` +
    `${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

function parseEnglishDate(value) {
  const match =
    /^[A-Za-z]+, ([A-Za-z]+) (\d{1,2}), (\d{4})$/.exec(value.trim());
  if (!match) return null;
  const month = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ].indexOf(match[1]) + 1;
  return month > 0 ? isoDate(Number(match[3]), month, Number(match[2])) : null;
}

function firstMatch(text, pattern) {
  return pattern.exec(text)?.[1] || "";
}

function extractParenthesizedDigits(text) {
  return [...text.matchAll(/\((\d)\)/g)].map((match) => match[1]);
}

function between(text, start, end) {
  const startIndex = text.indexOf(start);
  if (startIndex < 0) return "";
  const endIndex = text.indexOf(end, startIndex + start.length);
  return text.slice(startIndex, endIndex < 0 ? undefined : endIndex);
}

function isDigits(value, length) {
  return new RegExp(`^\\d{${length}}$`).test(String(value || ""));
}

function readableError(error) {
  return error instanceof Error ? error.message : String(error);
}
