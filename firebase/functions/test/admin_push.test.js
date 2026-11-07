const { test, after } = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const handlers = require("../admin_push");
const app = admin.initializeApp({ projectId: "demo-dashboard-push" });
after(() => app.delete());

const device = "70bf01fd-c284-4729-bbd3-ace38593b111";
const event = {
  params: { id: "case-1" },
  timestamp: new Date().toISOString(),
  eventId: "event-1",
};
const snap = (data) => ({ get: (key) => data[key] });
test("only an administrator can bind or remove their own device", async (t) => {
  const saved = t.mock.fn(),
    removed = t.mock.fn();
  const ref = t.mock.fn(() => ({ set: saved, delete: removed }));
  t.mock.method(admin.firestore(), "collection", () => ({ doc: ref }));
  const input = { device, token: "test-token", uid: "someone-else" };
  const call = handlers.setDashboardPushDevice.run;
  await assert.rejects(call(input, {}), { code: "permission-denied" });
  await assert.rejects(
    call(input, {
      auth: {
        uid: "member",
        token: { email: "sanonmaeva064@gmail.com", email_verified: false },
      },
    }),
    { code: "permission-denied" },
  );
  const context = { auth: { uid: "admin-id", token: { admin: true } } };
  await call(input, context);
  assert.deepEqual(saved.mock.calls[0].arguments[0], {
    uid: "admin-id",
    device,
    token: input.token,
  });
  await call({ device, token: null }, context);
  assert.equal(removed.mock.callCount(), 1);
  assert.equal(ref.mock.calls[0].arguments[0], ref.mock.calls[1].arguments[0]);
});

test("only new incoming messages and transitions to pending notify opted-in admins", async (t) => {
  const deleted = t.mock.fn();
  const docs = ["allowed", "revoked", "expired-token"].map((uid) => ({
    data: () => ({ uid, device, token: uid }),
    ref: { delete: deleted },
    updateTime: uid,
  }));
  t.mock.method(admin.firestore(), "collection", () => ({
    get: async () => ({ docs }),
  }));
  t.mock.method(admin.auth(), "getUser", async (uid) => ({
    customClaims: { admin: uid !== "revoked" },
  }));
  const sent = t.mock.method(admin.messaging(), "send", async (payload) => {
    if (payload.token === "expired-token") {
      throw Object.assign(new Error(), {
        code: "messaging/registration-token-not-registered",
      });
    }
  });
  const payment = (before, after) =>
    handlers.notifyDashboardPayment.run(
      { before: snap({ status: before }), after: snap({ status: after }) },
      event,
    );
  const support = (role) =>
    handlers.notifyDashboardSupport.run(
      snap({ sender_role: role, text: "private" }),
      event,
    );
  await support("admin");
  await support("bot");
  await payment("pending", "approved");
  await payment("pending", "pending");
  assert.equal(sent.mock.callCount(), 0);
  await payment(undefined, "pending");
  await support("user");
  assert.deepEqual(
    sent.mock.calls
      .filter((x) => x.arguments[0].token === "allowed")
      .map((x) => x.arguments[0].data.kind),
    ["payment", "support"],
  );
  assert.ok(sent.mock.calls.every((x) => x.arguments[0].token !== "revoked"));
  assert.equal(deleted.mock.callCount(), 4);
  assert.deepEqual(Object.keys(sent.mock.calls[0].arguments[0].data).sort(), [
    "device",
    "event",
    "id",
    "kind",
    "uid",
  ]);
});
