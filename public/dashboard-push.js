// The FCM data message arrives as a standard Web Push event, including when
// the dashboard has no open tab. This worker deliberately has no fetch handler.
const scope = self.registration.scope;
const binding = new URL("dashboard-push-binding", scope).href;
const types = {
  support: ["Nouveau message au support", "support-inbox", "conversation"],
  payment: ["Paiement à vérifier", "payment-reviews", "request"],
};
async function enabledFor(data) {
  const entry = await (
    await caches.open("choloto-dashboard-push")
  ).match(binding);
  if (!entry) return false;
  const state = await entry.json();
  return state.uid === data.uid && state.device === data.device;
}
self.addEventListener("install", (event) =>
  event.waitUntil(self.skipWaiting()),
);
self.addEventListener("activate", (event) =>
  event.waitUntil(self.clients.claim()),
);
const recentUrl = new URL("dashboard-push-recent", scope).href;
let pending = Promise.resolve();
async function display(data) {
  if (!(await enabledFor(data))) return;
  const cache = await caches.open("choloto-dashboard-push");
  const stored = await cache.match(recentUrl);
  const recent = stored ? await stored.json() : [];
  if (recent.includes(data.event)) return;
  const [title] = types[data.kind];
  await self.registration.showNotification(title, {
    body: "CHOLOTO • Administration",
    icon: new URL("dashboard-192.png", scope).href,
    tag: "dashboard-" + data.event,
    data: { kind: data.kind, id: data.id, uid: data.uid, device: data.device },
  });
  // Firestore can retry an event after a partial delivery to multiple devices.
  await cache.put(
    recentUrl,
    new Response(JSON.stringify([...recent.slice(-255), data.event])),
  );
}
self.addEventListener("push", (event) => {
  const data = event.data?.json()?.data;
  if (
    !data ||
    !Object.hasOwn(types, data.kind) ||
    typeof data.event !== "string" ||
    typeof data.id !== "string" ||
    !data.id ||
    data.id.includes("/")
  )
    return;
  const task = pending.then(() => display(data));
  pending = task.catch(() => {});
  event.waitUntil(task);
});
self.addEventListener("notificationclick", (event) => {
  const data = event.notification.data;
  event.notification.close();
  if (!data || !Object.hasOwn(types, data.kind)) return;
  event.waitUntil(
    (async () => {
      if (!(await enabledFor(data))) return;
      const [, path, param] = types[data.kind];
      const target = new URL(path, scope);
      target.searchParams.set(param, data.id);
      const windows = await self.clients.matchAll({
        type: "window",
        includeUncontrolled: true,
      });
      // Reuse only an exact match so an unrelated open form keeps its draft.
      const existing = windows.find((client) => client.url === target.href);
      if (existing) return existing.focus();
      return self.clients.openWindow(target.href);
    })(),
  );
});
