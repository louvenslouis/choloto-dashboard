import { beforeEach, afterEach, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  store: new Map<string, Record<string, any>>(),
  fail: new Set<string>(),
  loseReply: false,
  commits: [] as string[][],
  queries: [] as any[],
  admin: { uid: "admin", email: "admin@example.test" } as {
    uid: string;
    email: string;
  } | null,
}));
vi.mock("./firebase", () => ({
  db: {},
  auth: {
    get currentUser() {
      return mocks.admin;
    },
  },
}));
vi.mock("firebase/firestore", () => ({
  collection: (_db: unknown, path: string) => ({ path }),
  doc: (base: { path?: string }, ...parts: string[]) => {
    const path = parts.length ? parts.join("/") : `${base.path}/operation1`;
    return { path, id: path.split("/").at(-1) };
  },
  Timestamp: {
    fromDate: (date: Date) => date,
    fromMillis: (time: number) => new Date(time),
  },
  serverTimestamp: () => new Date(),
  where: (field: string, operator: string, value: Date) => ({
    field,
    operator,
    value,
  }),
  query: (ref: { path: string }, filter: unknown) => ({ ...ref, filter }),
  getDocsFromServer: async (query: any) => {
    mocks.queries.push(query);
    return {
      docs: [...mocks.store.entries()]
        .filter(
          ([path, data]) =>
            path.startsWith(`${query.path}/`) &&
            data[query.filter.field] >= query.filter.value,
        )
        .map(([path]) => ({ id: path.split("/").at(-1) })),
    };
  },
  runTransaction: async (
    _db: unknown,
    run: (tx: unknown) => Promise<unknown>,
  ) => {
    const writes: { path: string; data: Record<string, any> }[] = [];
    const result = await run({
      get: async (ref: { path: string }) => {
        if (writes.length) throw new Error("Lecture après écriture");
        if (mocks.fail.has(ref.path)) throw new Error("Connexion interrompue");
        return {
          exists: () => mocks.store.has(ref.path),
          data: () => mocks.store.get(ref.path),
        };
      },
      update: (ref: { path: string }, data: Record<string, any>) =>
        writes.push({
          path: ref.path,
          data: { ...mocks.store.get(ref.path), ...data },
        }),
      set: (ref: { path: string }, data: Record<string, any>) =>
        writes.push({ path: ref.path, data }),
    });
    if (writes.length) {
      writes.forEach(({ path, data }) => mocks.store.set(path, data));
      mocks.commits.push(writes.map((write) => write.path));
      if (mocks.loseReply) {
        mocks.loseReply = false;
        throw new Error("Réponse perdue");
      }
    }
    return result;
  },
}));
import {
  applyCompensation,
  compensationEnd,
  prepareCompensation,
} from "./compensation";
import { isCompensation, isPayment } from "./payments";
const now = new Date("2026-11-07T12:00:00Z");
const day = 86400000;
beforeEach(() => {
  vi.useFakeTimers();
  vi.setSystemTime(now);
  mocks.store.clear();
  mocks.fail.clear();
  mocks.commits.length = 0;
  mocks.queries.length = 0;
  mocks.loseReply = false;
  mocks.admin = { uid: "admin", email: "admin@example.test" };
  mocks.store.set("user/active", {
    end_sub: new Date(+now + 10 * day),
    member_time: 3,
    method: "moncash",
  });
  mocks.store.set("user/expired", {
    end_sub: new Date(+now - day),
    member_time: 2,
  });
  mocks.store.set("user/free", { email: "free@example.test" });
});
afterEach(() => vi.useRealTimers());

it("fige tous les VIP actuels à partir du serveur et ignore la sélection", async () => {
  const operation = await prepareCompensation(3, "vip", ["expired"]);
  expect(operation.uids).toEqual(["active"]);
  expect(mocks.queries[0].filter).toEqual({
    field: "end_sub",
    operator: ">=",
    value: now,
  });
  mocks.store.set("user/new-vip", { end_sub: new Date(+now + day) });
  await applyCompensation(operation);
  expect(mocks.store.get("user/new-vip")!.end_sub).toEqual(
    new Date(+now + day),
  );
  expect(mocks.store.get("user/expired")!.end_sub).toEqual(
    new Date(+now - day),
  );
});

it("prolonge l’échéance et enregistre la compensation atomiquement sans encaissement", async () => {
  const operation = await prepareCompensation(3, "selected", [
    "active",
    "active",
  ]);
  const result = await applyCompensation(operation);
  expect(result).toMatchObject({ applied: 1, skipped: 0, failed: 0 });
  expect(mocks.store.get("user/active")).toMatchObject({
    end_sub: new Date(+now + 13 * day),
    member_time: 3,
    method: "moncash",
  });
  const id = `compensation_${operation.id}_active`;
  expect(mocks.commits).toEqual([
    ["user/active", `payment_transactions/${id}`],
  ]);
  const receipt = mocks.store.get(`payment_transactions/${id}`)!;
  expect(receipt).toMatchObject({
    transaction_type: "adjustment",
    member_time_before: 3,
    member_time_after: 3,
    created_by: "admin",
    receipt_code: `CH-${id}`,
    previous_end_sub: new Date(+now + 10 * day),
  });
  expect(receipt).not.toHaveProperty("amount");
  expect(receipt).not.toHaveProperty("currency");
  expect(isCompensation({ ...receipt, id })).toBe(true);
  expect(isPayment({ ...receipt, id })).toBe(false);
});

it("part du présent pour les membres gratuits ou expirés sélectionnés", async () => {
  await applyCompensation(
    await prepareCompensation(2, "selected", ["expired", "free"]),
  );
  for (const uid of ["expired", "free"])
    expect(mocks.store.get(`user/${uid}`)!.end_sub).toEqual(
      new Date(+now + 2 * day),
    );
  expect(mocks.store.get("user/active")!.end_sub).toEqual(
    new Date(+now + 10 * day),
  );
});

it("relit la dernière échéance après un renouvellement concurrent", async () => {
  const operation = await prepareCompensation(2, "vip", []);
  mocks.store.get("user/active")!.end_sub = new Date(+now + 40 * day);
  await applyCompensation(operation);
  expect(mocks.store.get("user/active")!.end_sub).toEqual(
    new Date(+now + 42 * day),
  );
});

it("ignore un VIP annulé et un profil supprimé après la préparation", async () => {
  const operation = await prepareCompensation(2, "vip", []);
  delete mocks.store.get("user/active")!.end_sub;
  expect(await applyCompensation(operation)).toMatchObject({
    applied: 0,
    skipped: 1,
  });
  const selected = await prepareCompensation(2, "selected", ["missing"]);
  expect(await applyCompensation(selected)).toMatchObject({
    applied: 0,
    skipped: 1,
  });
  expect(mocks.commits).toHaveLength(0);
});

it("reprend les échecs partiels sans doubler les jours déjà accordés", async () => {
  const operation = await prepareCompensation(2, "selected", [
    "active",
    "expired",
    "free",
  ]);
  mocks.fail.add("user/expired");
  const progress: number[] = [];
  expect(
    await applyCompensation(operation, (n) => progress.push(n)),
  ).toMatchObject({ applied: 2, failed: 1 });
  expect(progress).toEqual([1, 2, 3]);
  mocks.fail.clear();
  expect(await applyCompensation(operation)).toMatchObject({
    applied: 3,
    failed: 0,
  });
  expect(mocks.store.get("user/active")!.end_sub).toEqual(
    new Date(+now + 12 * day),
  );
  expect(mocks.store.get("user/free")!.end_sub).toEqual(
    new Date(+now + 2 * day),
  );
  expect(mocks.commits).toHaveLength(3);
});

it("reconnaît un succès même si la réponse réseau s’est perdue", async () => {
  const operation = await prepareCompensation(2, "selected", ["active"]);
  mocks.loseReply = true;
  expect(await applyCompensation(operation)).toMatchObject({ failed: 1 });
  expect(await applyCompensation(operation)).toMatchObject({
    applied: 1,
    failed: 0,
  });
  expect(mocks.store.get("user/active")!.end_sub).toEqual(
    new Date(+now + 12 * day),
  );
  expect(mocks.commits).toHaveLength(1);
});

it("traite plus de 500 bénéficiaires sans lot surdimensionné", async () => {
  const uids = Array.from({ length: 501 }, (_, i) => `member-${i}`);
  uids.forEach((uid) => mocks.store.set(`user/${uid}`, {}));
  expect(
    await applyCompensation(await prepareCompensation(1, "selected", uids)),
  ).toMatchObject({ applied: 501, failed: 0 });
  expect(mocks.commits.every((writes) => writes.length === 2)).toBe(true);
});

it("refuse jours invalides, sélection vide et changement de compte avant toute écriture", async () => {
  for (const days of [0, -1, 1.5, NaN, Infinity, 3651])
    await expect(prepareCompensation(days, "vip", [])).rejects.toThrow("jours");
  await expect(prepareCompensation(1, "selected", [])).rejects.toThrow(
    "Aucun membre",
  );
  const operation = await prepareCompensation(1, "vip", []);
  mocks.admin = { uid: "another-admin", email: "" };
  await expect(applyCompensation(operation)).rejects.toThrow(
    "Reconnectez-vous",
  );
  mocks.admin = null;
  await expect(prepareCompensation(1, "vip", [])).rejects.toThrow(
    "Reconnectez-vous",
  );
  expect(mocks.commits).toHaveLength(0);
});

it("ajoute des jours entiers en conservant l’heure au passage de mois et d’année", () => {
  expect(compensationEnd(new Date("2026-12-31T22:10:00Z"), 2, now)).toEqual(
    new Date("2027-01-02T22:10:00Z"),
  );
  expect(compensationEnd(new Date("2028-02-28T22:10:00Z"), 2, now)).toEqual(
    new Date("2028-03-01T22:10:00Z"),
  );
});
