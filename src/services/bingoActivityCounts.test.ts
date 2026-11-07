import { afterEach, beforeEach, expect, it, vi } from "vitest";
import {
  clearActivityCounts,
  loadActivityCounts,
  loadReactionCounts,
} from "./bingoActivityCounts";

const { auth, count } = vi.hoisted(() => ({
  auth: { currentUser: { uid: "admin" } },
  count: vi.fn(),
}));
vi.mock("./firebase", () => ({ auth, db: {} }));
vi.mock("firebase/firestore", () => ({
  collection: (_db: unknown, ...path: string[]) => path.join("/"),
  query: (path: string, filter: string) => path + filter,
  where: (field: string, op: string, value: boolean) =>
    `?${field}${op}${value}`,
  getCountFromServer: count,
}));

beforeEach(() => {
  vi.useFakeTimers();
  count.mockReset().mockImplementation(async (path: string) => ({
    data: () => ({ count: path.endsWith("?gain==true") ? 1 : 2 }),
  }));
  auth.currentUser = { uid: "admin" };
});
afterEach(() => vi.useRealTimers());

it("partage les lectures en cours et ne recompte que les nouveaux bingos", async () => {
  const first = loadActivityCounts(["a"]);
  const reactions = loadReactionCounts(["a"]);
  const second = loadActivityCounts(["a", "b"]);
  expect(count).toHaveBeenCalledTimes(8);
  expect((await reactions).a).toEqual({ won: 1, lost: 1 });
  expect((await first).a).toEqual({ comments: 4, reactions: 2 });
  await second;
  await loadActivityCounts(["b", "a"]);
  expect(count).toHaveBeenCalledTimes(8);
  vi.advanceTimersByTime(29 * 60_000);
  await loadActivityCounts(["b"]);
  expect(count).toHaveBeenCalledTimes(8);
  vi.advanceTimersByTime(60_000);
  await loadActivityCounts(["b"]);
  expect(count).toHaveBeenCalledTimes(12);
});

it("relit les compteurs après un échec, une actualisation et une nouvelle session", async () => {
  count.mockRejectedValueOnce(new Error("Hors ligne"));
  await expect(loadActivityCounts(["a"])).rejects.toThrow("Hors ligne");
  await loadActivityCounts(["a"]);
  clearActivityCounts();
  await loadActivityCounts(["a"]);
  auth.currentUser = { uid: "admin" };
  await loadActivityCounts(["a"]);
  expect(count).toHaveBeenCalledTimes(14);
});
