import { expect, it, vi } from "vitest";
vi.mock("./data", () => ({
  asDate: (value: unknown) => (value instanceof Date ? value : null),
}));
import { vipHistory, vipPeriodStart } from "./vipHistory";
const now = new Date(2026, 9, 6, 12);
it("ends every period today and clamps month boundaries", () => {
  for (const period of [30, 90, 180]) {
    const start = vipPeriodStart(now, period);
    const values = vipHistory([], start, now, 7);
    expect(values.at(-1)).toBe(7);
    const end = new Date(start);
    end.setDate(end.getDate() + values.length - 1);
    expect(end.toDateString()).toBe(now.toDateString());
  }
  expect(vipHistory([], vipPeriodStart(now, 30), now, 7)).toHaveLength(30);
  expect(vipPeriodStart(new Date(2026, 4, 31), 90).getDate()).toBe(28);
});
it("counts past subscriptions once and respects cancellations and expiry", () => {
  const event = (id: string, date: number, type: string, end: number) => ({
    id,
    user_uid: "a",
    created_at: new Date(2026, 9, date, 10),
    transaction_type: type,
    new_end_sub: new Date(2026, 9, end, 23, 59, 59),
  });
  const rows = [
    event("1", 1, "subscription", 2),
    event("2", 2, "renewal", 4),
    event("3", 3, "cancellation", 4),
    event("4", 4, "subscription", 4),
  ];
  expect(vipHistory(rows, new Date(2026, 9, 1), now, 2)).toEqual([
    1, 1, 0, 1, 0, 2,
  ]);
});
