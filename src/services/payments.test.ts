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
import { recordPayment, rejectPayment, adjustMembership } from "./payments";
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
