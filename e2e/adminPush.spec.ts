import { test, expect } from "@playwright/test";

test("activation par appareil, réception en arrière-plan et désactivation", async ({
  page,
  context,
}) => {
  await context.grantPermissions(["notifications"]);
  const calls: { device: string; token: string | null }[] = [];
  await context.route(
    "https://us-central1-choloto-6aa5b.cloudfunctions.net/setDashboardPushDevice",
    async (route) => {
      calls.push(route.request().postDataJSON().data);
      await route.fulfill({
        json: { result: { enabled: calls.at(-1)?.token !== null } },
      });
    },
  );
  await page.goto("/settings");
  await page
    .getByRole("button", { name: "Activer sur cet appareil", exact: true })
    .click();
  const disable = page.getByRole("button", {
    name: "Désactiver sur cet appareil",
  });
  await expect(disable).toBeVisible();
  const device = calls[0].device;
  expect(calls[0].token).toBe("fixture-admin-device-token");
  const observer = await context.newPage();
  // A blank same-origin tab lets us inspect Chrome's notification store after closing the dashboard.
  await observer.goto("/dashboard.webmanifest");
  const cdp = await context.newCDPSession(observer);
  let registrationId = "";
  cdp.on("ServiceWorker.workerRegistrationUpdated", ({ registrations }) => {
    const item = registrations.find(
      (r) => r.scopeURL === new URL("/", observer.url()).href,
    );
    if (item) registrationId = item.registrationId;
  });
  await cdp.send("ServiceWorker.enable");
  await expect.poll(() => registrationId).not.toBe("");
  await page.close();
  const deliver = (kind: string, id: string, uid = "fixture-admin") =>
    cdp.send("ServiceWorker.deliverPushMessage", {
      origin: new URL(observer.url()).origin,
      registrationId,
      data: JSON.stringify({ data: { kind, id, uid, device, event: id } }),
    });
  await deliver("support", "member-1");
  await deliver("payment", "request-1");
  const titles = () =>
    observer.evaluate(async () =>
      (await (await navigator.serviceWorker.ready).getNotifications())
        .map((n) => n.title)
        .sort(),
    );
  await expect
    .poll(titles)
    .toEqual(["Nouveau message au support", "Paiement à vérifier"]);
  // Headless Chrome has no OS notification tray. Dispatch its click event on
  // the real worker and capture the window URL that a user gesture would open.
  const worker = context
    .serviceWorkers()
    .find((w) => w.url().endsWith("/dashboard-push.js"))!;
  const targets = await worker.evaluate(async () => {
    const sw = self as unknown as ServiceWorkerGlobalScope;
    const urls: string[] = [];
    sw.clients.openWindow = async (url) => {
      urls.push(url);
      return null;
    };
    for (const notification of await sw.registration.getNotifications()) {
      const event = new NotificationEvent("notificationclick", {
        notification,
      });
      let task: Promise<unknown> | undefined;
      Object.defineProperty(event, "waitUntil", {
        value: (work: Promise<unknown>) => {
          task = work;
        },
      });
      sw.dispatchEvent(event);
      await task;
    }
    return urls.map((url) => new URL(url).pathname + new URL(url).search);
  });
  expect(targets.sort()).toEqual([
    "/payment-reviews?request=request-1",
    "/support-inbox?conversation=member-1",
  ]);
  await deliver("support", "member-1");
  await deliver("payment", "other-admin-only", "different-uid");
  await deliver("support", "sentinel");
  await expect.poll(titles).toEqual(["Nouveau message au support"]);
  await observer.goto(targets[1]);
  await expect(
    observer.getByRole("textbox", { name: "Message", exact: true }),
  ).toBeVisible();
  await observer.goto(targets[0]);
  await expect(
    observer.getByRole("dialog", { name: "Vérifier le paiement" }),
  ).toBeVisible();
  await observer.goto("/settings");
  await observer
    .getByRole("button", { name: "Désactiver sur cet appareil" })
    .click();
  await expect(
    observer.getByRole("button", {
      name: "Activer sur cet appareil",
      exact: true,
    }),
  ).toBeVisible();
  expect(calls.at(-1)).toEqual({ device, token: null });
  await expect.poll(titles).toEqual([]);
});
