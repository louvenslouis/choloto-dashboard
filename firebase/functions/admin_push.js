const { createHash } = require("node:crypto");
const functions = require("firebase-functions");
const admin = require("firebase-admin");

const devices = () => admin.firestore().collection("dashboard_push_devices");
const adminEmail = "sanonmaeva064@gmail.com";
const invalidTokens = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);
const lifetime = 3600;

exports.setDashboardPushDevice = functions
  .region("us-central1")
  .https.onCall(async (input, context) => {
    const auth = context.auth;
    if (
      !auth ||
      !(
        auth.token.admin === true ||
        (auth.token.email === adminEmail && auth.token.email_verified === true)
      )
    ) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Accès administrateur requis.",
      );
    }
    const { device, token } = input || {};
    if (
      typeof device !== "string" ||
      !/^[a-f0-9-]{36}$/i.test(device) ||
      (token !== null &&
        (typeof token !== "string" || !token.trim() || token.length > 4096))
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Abonnement invalide.",
      );
    }
    const key = createHash("sha256")
      .update(JSON.stringify([auth.uid, device]))
      .digest("hex");
    const ref = devices().doc(key);
    if (token === null) await ref.delete();
    else await ref.set({ uid: auth.uid, device, token });
    return { enabled: token !== null };
  });

async function isStillAdmin(uid) {
  try {
    const user = await admin.auth().getUser(uid);
    return (
      !user.disabled &&
      (user.customClaims?.admin === true ||
        (user.email === adminEmail && user.emailVerified))
    );
  } catch (err) {
    if (err.code === "auth/user-not-found") return false;
    throw err;
  }
}

async function forget(snapshot) {
  // A concurrent opt-in or token refresh wins over cleanup of the old token.
  try {
    await snapshot.ref.delete({ lastUpdateTime: snapshot.updateTime });
  } catch (err) {
    if (err.code !== 9 && err.code !== 5) throw err;
  }
}

async function notify(kind, id, context) {
  if (Date.now() - Date.parse(context.timestamp) > lifetime * 1000) return;
  const targets = await devices().get();
  const accounts = new Map();
  const event = createHash("sha256")
    .update(context.eventId)
    .digest("hex")
    .slice(0, 32);
  await Promise.all(
    targets.docs.map(async (snapshot) => {
      const { uid, device, token } = snapshot.data();
      if (!accounts.has(uid)) accounts.set(uid, isStillAdmin(uid));
      if (!(await accounts.get(uid))) return forget(snapshot);
      try {
        await admin.messaging().send({
          token,
          data: { kind, id, uid, device, event },
          webpush: { headers: { TTL: String(lifetime), Topic: event } },
        });
      } catch (err) {
        if (invalidTokens.has(err.code)) return forget(snapshot);
        throw err;
      }
    }),
  );
}

const events = functions
  .region("us-central1")
  .runWith({ failurePolicy: true }).firestore;
exports.notifyDashboardSupport = events
  .document("support_conversations/{id}/messages/{message}")
  .onCreate((snapshot, context) => {
    if (snapshot.get("sender_role") === "user")
      return notify("support", context.params.id, context);
  });
exports.notifyDashboardPayment = events
  .document("payment_requests/{id}")
  .onWrite((change, context) => {
    if (
      change.after.get("status") === "pending" &&
      change.before.get("status") !== "pending"
    ) {
      return notify("payment", context.params.id, context);
    }
  });
