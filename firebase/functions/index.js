const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
admin.initializeApp();

exports.ensureUserDocumentByEmail = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication is required.",
      );
    }

    const token = context.auth.token || {};
    const isAdmin = token.admin === true ||
      token.email === "sanonmaeva064@gmail.com";
    if (!isAdmin) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only administrators can create user documents.",
      );
    }

    const email = String(data && data.email || "").trim().toLowerCase();
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid email address is required.",
      );
    }

    let authUser;
    try {
      authUser = await admin.auth().getUserByEmail(email);
    } catch (error) {
      if (error && error.code === "auth/user-not-found") {
        throw new functions.https.HttpsError(
          "not-found",
          "No Firebase Auth account matches this email.",
        );
      }
      functions.logger.error("Unable to find Firebase Auth user", error);
      throw new functions.https.HttpsError(
        "internal",
        "Unable to find the Firebase Auth user.",
      );
    }

    const reference = admin.firestore().collection("user").doc(authUser.uid);
    const snapshot = await reference.get();
    const dataToMerge = {
      email: authUser.email || email,
      uid: authUser.uid,
      updated_time: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (authUser.displayName) dataToMerge.display_name = authUser.displayName;
    if (authUser.photoURL) dataToMerge.photo_url = authUser.photoURL;
    if (authUser.phoneNumber) dataToMerge.phone_number = authUser.phoneNumber;

    if (snapshot.exists) {
      if (!snapshot.data().created_time) {
        dataToMerge.created_time = admin.firestore.FieldValue.serverTimestamp();
      }
      await reference.set(dataToMerge, {merge: true});
      return {
        created: false,
        repaired: true,
        email: authUser.email || email,
        uid: authUser.uid,
      };
    }

    await reference.set({
      ...dataToMerge,
      created_time: admin.firestore.FieldValue.serverTimestamp(),
      member_time: 0,
    });
    return {
      created: true,
      repaired: false,
      email: authUser.email || email,
      uid: authUser.uid,
    };
  });

const NY_OPEN_DATA_URL = "https://data.ny.gov/resource/hsys-3def.json";
const NY_LOTTERY_API_URL =
  "https://nylottery.ny.gov/drupal-api/api/v2/winning_numbers";
const NY_OPEN_DATA_PAGE = "https://data.ny.gov/d/hsys-3def";
const NY_LOTTERY_RESULTS_PAGE =
  "https://nylottery.ny.gov/all-winning-numbers/";

exports.officialNewYorkResults = functions
  .region("us-central1")
  .https.onRequest(async (request, response) => {
    response.set("Access-Control-Allow-Origin", "*");
    response.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    response.set("Access-Control-Allow-Headers", "Content-Type");

    if (request.method === "OPTIONS") {
      response.status(204).send("");
      return;
    }
    if (request.method !== "GET") {
      response.status(405).json({error: "Method not allowed"});
      return;
    }

    response.set("Cache-Control", "public, max-age=300, s-maxage=300");

    const [openData, lotteryWebsite] = await Promise.allSettled([
      fetchNewYorkOpenData(),
      fetchNewYorkLotteryWebsite(),
    ]);

    if (openData.status === "rejected") {
      functions.logger.warn("NY Open Data unavailable", {
        error: readableAxiosError(openData.reason),
      });
    }
    if (lotteryWebsite.status === "rejected") {
      functions.logger.warn("NY Lottery website API unavailable", {
        error: readableAxiosError(lotteryWebsite.reason),
      });
    }

    const rows = selectFreshestNewYorkRows(openData, lotteryWebsite);
    if (rows === null) {
      functions.logger.error("All official New York sources unavailable");
      response.status(502).json({
        error: "Official New York lottery sources are temporarily unavailable",
      });
      return;
    }

    response.status(200).json(rows);
  });

function selectFreshestNewYorkRows(openData, lotteryWebsite) {
  if (openData.status === "rejected" && lotteryWebsite.status === "rejected") {
    return null;
  }
  if (openData.status === "rejected") return lotteryWebsite.value;
  if (lotteryWebsite.status === "rejected") return openData.value;

  const openDataDate = latestNewYorkDate(openData.value);
  const lotteryWebsiteDate = latestNewYorkDate(lotteryWebsite.value);
  return lotteryWebsiteDate >= openDataDate ?
    lotteryWebsite.value :
    openData.value;
}

function latestNewYorkDate(rows) {
  return rows.reduce((latest, row) => {
    const drawDate = String(row.draw_date || "").slice(0, 10);
    return drawDate > latest ? drawDate : latest;
  }, "");
}

async function fetchNewYorkOpenData() {
  const result = await axios.get(NY_OPEN_DATA_URL, {
    params: {
      "$limit": 7,
      "$order": "draw_date DESC",
    },
    headers: {Accept: "application/json"},
    timeout: 12000,
  });
  if (!Array.isArray(result.data) || result.data.length === 0) {
    throw new Error("NY Open Data returned no rows");
  }

  return result.data.map((row) => ({
    ...row,
    _choloto_source_name: "NY Open Data · Gaming Commission",
    _choloto_source_url: NY_OPEN_DATA_PAGE,
  }));
}

async function fetchNewYorkLotteryWebsite() {
  const [numbersResponse, win4Response] = await Promise.all([
    fetchNewYorkLotteryGame("41"),
    fetchNewYorkLotteryGame("46"),
  ]);
  const rowsByDate = new Map();

  appendNewYorkLotteryGame(rowsByDate, numbersResponse, "daily", 3);
  appendNewYorkLotteryGame(rowsByDate, win4Response, "win_4", 4);

  const rows = [...rowsByDate.values()]
    .filter((row) =>
      (isDigits(row.midday_daily, 3) && isDigits(row.midday_win_4, 4)) ||
      (isDigits(row.evening_daily, 3) && isDigits(row.evening_win_4, 4)),
    )
    .sort((left, right) => right.draw_date.localeCompare(left.draw_date))
    .slice(0, 7);

  if (rows.length === 0) {
    throw new Error("NY Lottery returned no complete rows");
  }
  return rows;
}

async function fetchNewYorkLotteryGame(nid) {
  const result = await axios.get(NY_LOTTERY_API_URL, {
    params: {
      _format: "json",
      nid,
    },
    headers: {Accept: "application/json"},
    timeout: 12000,
  });
  const rows = result.data && result.data.rows;
  if (!Array.isArray(rows)) {
    throw new Error(`NY Lottery game ${nid} returned an invalid response`);
  }
  return rows;
}

function appendNewYorkLotteryGame(rowsByDate, sourceRows, field, length) {
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

function isDigits(value, length) {
  return new RegExp(`^\\d{${length}}$`).test(String(value || ""));
}

function readableAxiosError(error) {
  if (error && error.response) {
    return `HTTP ${error.response.status}`;
  }
  if (error && error.code) {
    return error.code;
  }
  return error && error.message ? error.message : "unknown error";
}
