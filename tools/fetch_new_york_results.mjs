import {mkdir, writeFile} from "node:fs/promises";
import {dirname, resolve} from "node:path";

const NY_OPEN_DATA_URL = new URL(
  "https://data.ny.gov/resource/hsys-3def.json",
);
NY_OPEN_DATA_URL.searchParams.set("$limit", "7");
NY_OPEN_DATA_URL.searchParams.set("$order", "draw_date DESC");

const NY_LOTTERY_API_URL =
  "https://nylottery.ny.gov/drupal-api/api/v2/winning_numbers";
const NY_OPEN_DATA_PAGE = "https://data.ny.gov/d/hsys-3def";
const NY_LOTTERY_RESULTS_PAGE =
  "https://nylottery.ny.gov/all-winning-numbers/";

const outputArgument = process.argv[2];
if (!outputArgument) {
  throw new Error("Usage: node fetch_new_york_results.mjs <output.json>");
}

const [openData, lotteryWebsite] = await Promise.allSettled([
  fetchNewYorkOpenData(),
  fetchNewYorkLotteryWebsite(),
]);

if (openData.status === "rejected") {
  console.warn(`NY Open Data unavailable: ${readableError(openData.reason)}`);
}
if (lotteryWebsite.status === "rejected") {
  console.warn(
    `NY Lottery website unavailable: ${readableError(lotteryWebsite.reason)}`,
  );
}

const rows = selectFreshestRows(openData, lotteryWebsite);
if (rows === null) {
  throw new Error("All official New York lottery sources are unavailable");
}

const outputPath = resolve(outputArgument);
await mkdir(dirname(outputPath), {recursive: true});
await writeFile(outputPath, `${JSON.stringify(rows, null, 2)}\n`, "utf8");
console.log(
  `Wrote ${rows.length} official New York result rows to ${outputPath}`,
);

async function fetchNewYorkOpenData() {
  const rows = await requestJson(NY_OPEN_DATA_URL);
  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error("NY Open Data returned no rows");
  }

  return rows.map((row) => ({
    ...row,
    _choloto_source_name: "NY Open Data · Gaming Commission",
    _choloto_source_url: NY_OPEN_DATA_PAGE,
  }));
}

async function fetchNewYorkLotteryWebsite() {
  const [numbersRows, win4Rows] = await Promise.all([
    fetchNewYorkLotteryGame("41"),
    fetchNewYorkLotteryGame("46"),
  ]);
  const rowsByDate = new Map();

  appendLotteryGame(rowsByDate, numbersRows, "daily", 3);
  appendLotteryGame(rowsByDate, win4Rows, "win_4", 4);

  const rows = [...rowsByDate.values()]
    .filter((row) =>
      (isDigits(row.midday_daily, 3) && isDigits(row.midday_win_4, 4)) ||
      (isDigits(row.evening_daily, 3) && isDigits(row.evening_win_4, 4)),
    )
    .sort((left, right) => right.draw_date.localeCompare(left.draw_date))
    .slice(0, 7);

  if (rows.length === 0) {
    throw new Error("NY Lottery returned no complete result rows");
  }
  return rows;
}

async function fetchNewYorkLotteryGame(nid) {
  const url = new URL(NY_LOTTERY_API_URL);
  url.searchParams.set("_format", "json");
  url.searchParams.set("nid", nid);
  const response = await requestJson(url);
  if (!response || !Array.isArray(response.rows)) {
    throw new Error(`NY Lottery game ${nid} returned an invalid response`);
  }
  return response.rows;
}

async function requestJson(url) {
  const response = await fetch(url, {
    headers: {
      Accept: "application/json",
      "User-Agent": "CHOLOTO-Dashboard/1.0",
    },
    signal: AbortSignal.timeout(15000),
  });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  return response.json();
}

function appendLotteryGame(rowsByDate, sourceRows, field, length) {
  sourceRows.forEach((sourceRow) => {
    const date = String(sourceRow.date || "");
    const period = String(sourceRow.draw_time || "").toLowerCase();
    const numbers = Array.isArray(sourceRow.winning_numbers) ?
      sourceRow.winning_numbers.join("") :
      "";

    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) ||
        !["midday", "evening"].includes(period) ||
        !isDigits(numbers, length)) {
      return;
    }

    const row = rowsByDate.get(date) || {
      draw_date: `${date}T00:00:00.000`,
      _choloto_source_name: "New York Lottery",
      _choloto_source_url: NY_LOTTERY_RESULTS_PAGE,
    };
    row[`${period}_${field}`] = numbers;
    rowsByDate.set(date, row);
  });
}

function selectFreshestRows(openData, lotteryWebsite) {
  if (openData.status === "rejected" && lotteryWebsite.status === "rejected") {
    return null;
  }
  if (openData.status === "rejected") return lotteryWebsite.value;
  if (lotteryWebsite.status === "rejected") return openData.value;

  return latestDate(lotteryWebsite.value) >= latestDate(openData.value) ?
    lotteryWebsite.value :
    openData.value;
}

function latestDate(rows) {
  return rows.reduce((latest, row) => {
    const date = String(row.draw_date || "").slice(0, 10);
    return date > latest ? date : latest;
  }, "");
}

function isDigits(value, length) {
  return new RegExp(`^\\d{${length}}$`).test(String(value || ""));
}

function readableError(error) {
  return error instanceof Error ? error.message : String(error);
}
