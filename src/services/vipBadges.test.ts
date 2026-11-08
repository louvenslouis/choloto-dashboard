import { beforeEach, expect, it, vi } from "vitest";

const mock = vi.hoisted(() => ({ stored: undefined as unknown, set: vi.fn() }));
vi.mock("./firebase", () => ({ db: {} }));
vi.mock("firebase/firestore", () => ({
  doc: (_db: unknown, ...parts: string[]) => parts.join("/"),
  runTransaction: async (
    _db: unknown,
    callback: (tx: unknown) => Promise<void>,
  ) =>
    callback({
      get: async () => ({
        exists: () => !!mock.stored,
        data: () => mock.stored,
      }),
      set: mock.set,
    }),
}));
import {
  defaultVipBadgeTiers,
  saveVipBadgeTiers,
  validateVipBadgeTiers,
} from "./vipBadges";

const edit = (index: number, change: Partial<{ name: string; days: number }>) =>
  defaultVipBadgeTiers.map((tier, i) =>
    i === index ? { ...tier, ...change } : tier,
  );

beforeEach(() => {
  mock.stored = undefined;
  mock.set.mockClear();
});

it("enregistre une configuration complète à partir des règles initiales", async () => {
  expect(defaultVipBadgeTiers.map((t) => t.days)).toEqual([
    0, 30, 60, 180, 365, 730, 1095, 1460,
  ]);
  await saveVipBadgeTiers(
    defaultVipBadgeTiers,
    edit(1, { name: " Initié VIP ", days: 15 }),
  );
  expect(mock.set).toHaveBeenCalledWith("vip_badges/config", {
    tiers: edit(1, { name: "Initié VIP", days: 15 }),
  });
});

it("protège la configuration modifiée par un autre administrateur", async () => {
  mock.stored = { tiers: edit(1, { days: 25 }) };
  await expect(
    saveVipBadgeTiers(defaultVipBadgeTiers, edit(1, { days: 15 })),
  ).rejects.toThrow("ailleurs");
  expect(mock.set).not.toHaveBeenCalled();
});

it("refuse un premier seuil non nul, les seuils désordonnés et les niveaux incomplets", () => {
  for (const tiers of [
    edit(0, { days: 1 }),
    edit(1, { days: 60 }),
    edit(2, { days: 29 }),
    edit(2, { days: 1.5 }),
    edit(7, { days: 36501 }),
    edit(3, { name: "   " }),
    defaultVipBadgeTiers.slice(0, -1),
  ]) {
    expect(() => validateVipBadgeTiers(tiers)).toThrow();
  }
});
