import { expect, it, vi } from "vitest";
import { groupVipHistory, vipDuration } from "./vipDuration";
import type { Row } from "./data";

vi.mock("./data", () => ({
  asDate: (v: unknown) => (v instanceof Date ? v : null),
}));
const day = 86_400_000;
const at = (days: number) => new Date(Date.UTC(2026, 0, 31) + days * day);
const profile = (end: number | null, count: number): Row => ({
  id: "a",
  created_time: at(-1),
  member_time: count,
  end_sub: end === null ? null : at(end),
});
const receipt = (
  start: number,
  previous: number | null,
  end: number | null,
  before: number,
  after: number,
  type?: string,
): Row => ({
  id: String(start),
  user_ref: { id: "a" },
  created_at: at(start),
  previous_end_sub: previous === null ? null : at(previous),
  new_end_sub: end === null ? null : at(end),
  member_time_before: before,
  member_time_after: after,
  transaction_type: type,
});

it("arrête un abonnement prépayé à maintenant et respecte les fins de mois", () => {
  const first = receipt(0, null, 90, 0, 1);
  for (const [days, label] of [
    [0, "0 j"],
    [0.5, "< 1 j"],
    [28, "28 j"],
    [31, "1 mois 1 j"],
    [110, "3 mois"],
  ] as const) {
    expect(vipDuration(profile(90, 1), [first], +at(days))).toBe(label);
  }
});

it("cumule deux forfaits de 15 jours uniquement à mesure que l’accès est consommé", () => {
  const first = receipt(0, null, 15, 0, 1);
  expect(vipDuration(profile(15, 1), [first], +at(7))).toBe("7 j");
  expect(vipDuration(profile(15, 1), [first], +at(22))).toBe("15 j");
  const second = receipt(25, 15, 40, 1, 2, "renewal");
  expect(vipDuration(profile(40, 2), [first, second], +at(30))).toBe("20 j");
  expect(vipDuration(profile(40, 2), [first, second], +at(42))).toBe("1 mois");
});

it("affiche les jours du forfait à son terme malgré la latence du reçu", () => {
  const first = {
    ...receipt(0, null, 7, 0, 1),
    created_at: new Date(+at(0) + 450),
  };
  expect(vipDuration(profile(7, 1), [first], +at(7) - 100)).toBe("6 j");
  expect(vipDuration(profile(7, 1), [first], +at(7))).toBe("7 j");
  const shortened = { ...first, created_at: new Date(+at(0) + 61_000) };
  expect(vipDuration(profile(7, 1), [shortened], +at(7))).toBe("6 j");
});

it("cumule jours et fractions sans doubler les renouvellements anticipés ni les interruptions", () => {
  const first = receipt(0, null, 9, 0, 1);
  const renewal = receipt(2.5, 9, 20.5, 1, 2, "renewal");
  const compensation = receipt(35, 20.5, 50, 2, 2, "adjustment");
  const cancelled = receipt(45.5, 50, null, 2, 2, "cancellation");
  const histories = groupVipHistory([
    compensation,
    first,
    { ...first, user_uid: "b" },
    cancelled,
    renewal,
  ]);
  expect(histories.get("b")).toHaveLength(1);
  expect(vipDuration(profile(null, 2), histories.get("a")!, +at(70))).toBe(
    "1 mois 1 j",
  );
});

it("applique un raccourcissement à sa date, même lorsque le compteur reste identique", () => {
  expect(
    vipDuration(
      profile(12, 1),
      [receipt(0, null, 60, 0, 1), receipt(10, 60, 12, 1, 1, "adjustment")],
      +at(90),
    ),
  ).toBe("12 j");
});

it("distingue les profils gratuits, les anciens abonnés sans début connu et les minima vérifiables", () => {
  expect(vipDuration(profile(-1, 0), [], +at(10))).toBe("0 j");
  expect(vipDuration(profile(50, 0), [], +at(10))).toBe("Indéterminée");
  expect(vipDuration(profile(null, 4), [], +at(10))).toBe("Indéterminée");
  expect(vipDuration(profile(28, 5), [receipt(0, 2, 28, 4, 5)], +at(40))).toBe(
    "≥ 28 j",
  );
  expect(vipDuration(profile(28, 1), [receipt(0, -1, 28, 0, 1)], +at(40))).toBe(
    "28 j",
  );
});

it("ne valide pas un intervalle quand une modification de l’échéance manque", () => {
  const events = [receipt(0, null, 50, 0, 1), receipt(40, 11, 90, 2, 3)];
  expect(vipDuration(profile(90, 3), events, +at(44))).toBe("≥ 4 j");
  expect(vipDuration(profile(null, 1), events.slice(0, 1), +at(44))).toBe(
    "Indéterminée",
  );
});
