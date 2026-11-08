import { beforeEach, it, expect, vi } from "vitest";
const mocks = vi.hoisted(() => ({
  store: new Map<string, Record<string, unknown>>(),
  writes: [] as { kind: string; path: string; data: Record<string, unknown> }[],
}));
vi.mock("./firebase", () => ({
  db: {},
  auth: { currentUser: { uid: "admin", email: "admin@example.test" } },
}));
vi.mock("firebase/firestore", () => ({
  doc: (_db: unknown, ...segments: string[]) => ({
    path: segments.join("/"),
    id: segments.at(-1),
  }),
  collection: () => ({}),
  serverTimestamp: () => ({ serverTimestamp: true }),
  Timestamp: { fromDate: (date: Date) => ({ toDate: () => date }) },
  deleteField: () => null,
  getDocsFromServer: vi.fn(),
  query: vi.fn(),
  where: vi.fn(),
  runTransaction: async (_db: unknown, fn: (tx: unknown) => Promise<void>) =>
    fn({
      get: async (ref: { path: string }) => ({
        exists: () => mocks.store.has(ref.path),
        data: () => mocks.store.get(ref.path),
      }),
      update: (ref: { path: string }, data: Record<string, unknown>) =>
        mocks.writes.push({ kind: "update", path: ref.path, data }),
      set: (ref: { path: string }, data: Record<string, unknown>) =>
        mocks.writes.push({ kind: "set", path: ref.path, data }),
    }),
}));
import {
  recordPayment,
  rejectPayment,
  adjustMembership,
  paymentEnd,
} from "./payments";
const input = {
  id: "new",
  requestId: "request1",
  uid: "member",
  amount: 500,
  currency: "GDS",
  method: "moncash",
  end: new Date(2099, 1, 1),
};
beforeEach(() => {
  mocks.store.clear();
  mocks.writes.length = 0;
  mocks.store.set("payment_requests/request1", {
    user_uid: "member",
    status: "pending",
  });
  mocks.store.set("user/member", {
    email: "member@example.test",
    member_time: 2,
  });
});
it("met à jour profil, reçu et demande dans la même transaction", async () => {
  await recordPayment(input);
  expect(mocks.writes.map((w) => w.path)).toEqual([
    "user/member",
    "payment_transactions/proof_request1",
    "payment_requests/request1",
  ]);
  expect(mocks.writes[0].data.member_time).toBe(3);
  expect(mocks.writes[1].data.receipt_code).toBe("CH-proof_request1");
  expect(mocks.writes[2].data.status).toBe("approved");
});
it("ne crée pas un second reçu après une réponse réseau perdue", async () => {
  mocks.store.set("payment_transactions/proof_request1", {});
  await recordPayment(input);
  expect(mocks.writes).toHaveLength(0);
});
it.each([1, 7, 15, 45, 120])(
  "calcule %i jours depuis l’activation ou l’échéance en cours",
  (days) => {
    const now = new Date("2028-02-24T14:20:00Z");
    const active = new Date("2028-12-30T09:00:00Z");
    for (const previous of [null, new Date("2027-12-31T00:00:00Z"), active]) {
      const base = previous === active ? active : now;
      expect(paymentEnd({ days }, previous, now)?.getTime()).toBe(
        base.getTime() + days * 86_400_000,
      );
    }
  },
);
it.each([0, -1, 1.5, NaN, Infinity, 9e12])(
  "refuse une durée invalide (%s)",
  async (days) => {
    const { end, ...payment } = input;
    await expect(recordPayment({ ...payment, days })).rejects.toThrow("Durée");
    expect(mocks.writes).toHaveLength(0);
  },
);
it.each([undefined, "request1"])(
  "applique la durée à l’échéance relue pendant la transaction (%s)",
  async (requestId) => {
    const { end, ...payment } = input;
    const previous = new Date("2099-12-25T18:03:00Z");
    mocks.store.set("user/member", { member_time: 2, end_sub: previous });
    await recordPayment({ ...payment, requestId, days: 9 });
    const expected = new Date("2100-01-03T18:03:00Z");
    expect(mocks.writes).toHaveLength(requestId ? 3 : 2);
    for (const { data } of mocks.writes) {
      const timestamp = (data.new_end_sub ?? data.end_sub) as {
        toDate(): Date;
      };
      expect(timestamp.toDate()).toEqual(expected);
    }
  },
);
it("ne modifie rien si la demande appartient à un autre utilisateur", async () => {
  mocks.store.set("payment_requests/request1", {
    user_uid: "other",
    status: "pending",
  });
  await expect(recordPayment(input)).rejects.toThrow();
  expect(mocks.writes).toHaveLength(0);
});
it("ne modifie rien si le profil manque ou la demande est traitée", async () => {
  mocks.store.delete("user/member");
  await expect(recordPayment(input)).rejects.toThrow("Profil");
  expect(mocks.writes).toHaveLength(0);
  mocks.store.set("payment_requests/request1", { status: "rejected" });
  await expect(recordPayment(input)).rejects.toThrow();
});
it("refuse une demande en conservant la raison sans créer de reçu", async () => {
  await rejectPayment("request1", " Justificatif illisible ");
  expect(mocks.writes).toHaveLength(1);
  expect(mocks.writes[0].data).toMatchObject({
    status: "rejected",
    rejection_reason: "Justificatif illisible",
    reviewed_by: "admin",
  });
});

it("ajuste l’échéance sans compter un renouvellement ni un paiement", async () => {
  await adjustMembership("member", input.end, "adjustment1");
  expect(mocks.writes).toHaveLength(2);
  expect(mocks.writes[1].data).toMatchObject({
    transaction_type: "adjustment",
    member_time_before: 2,
    member_time_after: 2,
  });
  expect(mocks.writes[1].data).not.toHaveProperty("amount");
});

it.each([9, -4])(
  "décale de %i jours l’échéance courante en gardant son heure",
  async (days) => {
    const previous = new Date("2099-12-28T18:45:10Z");
    mocks.store.set("user/member", { end_sub: previous, member_time: 3 });
    await adjustMembership("member", { shiftDays: days }, "adjust");
    const expected = new Date(previous.getTime() + days * 86_400_000);
    const [profile, receipt] = mocks.writes;
    expect((profile.data.end_sub as { toDate(): Date }).toDate()).toEqual(
      expected,
    );
    expect(receipt.data).toMatchObject({
      transaction_type: "adjustment",
      member_time_before: 3,
      member_time_after: 3,
    });
    expect(receipt.data).not.toHaveProperty("amount");
  },
);

it("préserve l’échéance exacte quand seule la méthode change", async () => {
  const expiry = { toDate: () => new Date("2099-05-12T13:17:28.345Z") };
  mocks.store.set("user/member", { end_sub: expiry, method: "cash" });
  await adjustMembership("member", null, "method", "moncash");
  expect(mocks.writes[0].data.end_sub).toBe(expiry);
  expect(mocks.writes[0].data.method).toBe("moncash");
  expect(mocks.writes[1].data.previous_end_sub).toBe(expiry);
  expect(mocks.writes[1].data.new_end_sub).toBe(expiry);
});

it("refuse de retirer plus de temps qu’il en reste ou de décaler un accès annulé", async () => {
  mocks.store.set("user/member", {
    end_sub: new Date(Date.now() + 2 * 86_400_000),
  });
  await expect(
    adjustMembership("member", { shiftDays: -3 }, "shorten"),
  ).rejects.toThrow("futur");
  mocks.store.set("user/member", {});
  await expect(
    adjustMembership("member", { shiftDays: 7 }, "shift"),
  ).rejects.toThrow("futur");
  expect(mocks.writes).toHaveLength(0);
});
