import { auth } from "./firebase";
import { callAdmin } from "./admin";

const base = new URL(import.meta.env.BASE_URL, location.origin);
const bindingUrl = new URL("dashboard-push-binding", base).href;
const cacheName = "choloto-dashboard-push";
const vapidKey =
  "BGuDQSOZ80wL1DkqkIu5UBq0_fuia9ji3RR6HspwG-j0qkgv3Ax9o5hwZr2cWA2KzUljewAgew31DeYM3Mz6IgM";
type Binding = { uid: string; device: string };

export function pushAvailable() {
  return (
    window.isSecureContext &&
    "Notification" in window &&
    "PushManager" in window &&
    "serviceWorker" in navigator &&
    "caches" in window
  );
}
async function binding(): Promise<Binding | undefined> {
  if (!("caches" in window)) return;
  const entry = await (await caches.open(cacheName)).match(bindingUrl);
  return entry?.json();
}
export async function pushEnabled(uid: string) {
  return (
    pushAvailable() &&
    Notification.permission === "granted" &&
    (await binding())?.uid === uid
  );
}

let queue: Promise<unknown> = Promise.resolve();
function serialized(action: () => Promise<void>) {
  if (navigator.locks) return navigator.locks.request(bindingUrl, action);
  const next = queue.then(action, action);
  queue = next.catch(() => {});
  return next;
}

async function register(uid: string, previous?: Binding) {
  const { getMessaging, getToken, isSupported } =
    await import("firebase/messaging");
  if (!(await isSupported()))
    throw new Error("Notifications indisponibles dans ce navigateur.");
  const registration = await navigator.serviceWorker.register(
    new URL("dashboard-push.js", base),
    { scope: base.href },
  );
  await navigator.serviceWorker.ready;
  const token = await getToken(getMessaging(), {
    vapidKey,
    serviceWorkerRegistration: registration,
  });
  if (!token || auth.currentUser?.uid !== uid)
    throw new Error("Reconnectez-vous au dashboard.");
  const device = previous?.uid === uid ? previous.device : crypto.randomUUID();
  await callAdmin("setDashboardPushDevice", { device, token });
  if (auth.currentUser?.uid !== uid) throw new Error("La session a changé.");
  await (
    await caches.open(cacheName)
  ).put(bindingUrl, new Response(JSON.stringify({ uid, device })));
}

export async function enablePush(uid: string) {
  // iOS requires the permission prompt directly inside the user's gesture.
  const permission = await Notification.requestPermission();
  if (permission !== "granted")
    throw new Error(
      permission === "denied"
        ? "Autorisez les notifications dans les réglages du navigateur ou de l’app."
        : "Autorisation non accordée.",
    );
  return serialized(async () => register(uid, await binding()));
}

async function clearLocal() {
  await (await caches.open(cacheName)).delete(bindingUrl);
  if (!("serviceWorker" in navigator)) return;
  const registration = await navigator.serviceWorker.getRegistration(base.href);
  if (
    registration?.active?.scriptURL !== new URL("dashboard-push.js", base).href
  )
    return;
  for (const notification of await registration.getNotifications())
    notification.close();
  const subscription = await registration.pushManager.getSubscription();
  await subscription?.unsubscribe();
}

export function forgetSessionPush(uid: string) {
  return serialized(async () => {
    if ((await binding())?.uid === uid) await clearLocal();
  });
}

export function disablePush(uid: string) {
  return serialized(async () => {
    const previous = await binding();
    if (previous?.uid !== uid) return;
    await callAdmin("setDashboardPushDevice", {
      device: previous.device,
      token: null,
    });
    await clearLocal();
  });
}

// Runs after Firebase resolves the session. An explicit opt-in is required
// before ever requesting permission or registering a new device.
export function reconcilePush(uid: string | null) {
  return serialized(async () => {
    const previous = await binding();
    if (!previous || (auth.currentUser?.uid ?? null) !== uid) return;
    if (
      previous.uid !== uid ||
      !pushAvailable() ||
      Notification.permission !== "granted"
    ) {
      await clearLocal();
    } else {
      await register(previous.uid, previous);
    }
  });
}
