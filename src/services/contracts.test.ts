import { describe, it, expect, vi } from "vitest";
vi.mock("./firebase", () => ({
  auth: { currentUser: { uid: "admin", email: "admin@example.test" } },
  db: {},
}));
import {
  validateNumbers,
  resultPayload,
  matchesPublished,
} from "./publications";
import { proposal } from "./official";
import { suggestedEnd, validatePayment } from "./payments";
import { initialBot, validateBot } from "./bot";
describe("Compatibilité des publications", () => {
  it("conserve les zéros initiaux et le schéma des tirages", () =>
    expect(
      resultPayload("ny", "02:30 PM", ["001", "02", "03"], "admin"),
    ).toEqual({
      tirage: "ny",
      periode: "02:30 PM",
      numeros: ["001", "02", "03"],
      created_by: "admin",
    }));
  it("refuse les numéros incomplets et les périodes incompatibles", () => {
    expect(() => validateNumbers(["01", "23", "45"], [3, 2, 2])).toThrow();
    expect(() =>
      resultPayload("fl", "02:30 PM", ["01", "234", "56", "78"], "admin"),
    ).toThrow();
  });
  it("conserve les identifiants des résultats officiels Flutter", () => {
    const p = proposal("ny", "midday", "2026-10-02", ["001", "02", "03"], "NY");
    expect(p?.id).toBe("official_ny_20261002_midday");
    expect(p?.period).toBe("02:30 PM");
    expect(p?.date.getHours()).toBe(14);
  });
  it("refuse dates et sources malformées", () => {
    expect(
      proposal("ny", "midday", "2026-02-30", ["123", "45", "67"], ""),
    ).toBeNull();
    expect(
      proposal("tx", "midday", "2026-10-02", ["123", "45", "67"], ""),
    ).toBeNull();
  });
});
describe("Paiements", () => {
  it("prolonge un 31 janvier au dernier jour de février", () => {
    const end = suggestedEnd(new Date(2027, 0, 31), new Date(2027, 0, 1));
    expect([
      end.getFullYear(),
      end.getMonth(),
      end.getDate(),
      end.getHours(),
    ]).toEqual([2027, 1, 28, 23]);
  });
  it("repart du jour courant quand un abonnement est expiré", () =>
    expect(
      suggestedEnd(new Date(2025, 0, 1), new Date(2026, 9, 2)).getMonth(),
    ).toBe(10));
  it("refuse réduction d’échéance, montants invalides et devises non prévues", () => {
    const now = new Date(2026, 9, 1),
      end = new Date(2026, 10, 1);
    expect(() =>
      validatePayment(1, "GDS", "moncash", end, new Date(2026, 11, 1), now),
    ).toThrow();
    for (const amount of [0, -1, NaN, 1.001, Infinity])
      expect(() =>
        validatePayment(amount, "GDS", "moncash", end, null, now),
      ).toThrow();
    expect(() =>
      validatePayment(1, "EUR", "moncash", end, null, now),
    ).toThrow();
    expect(() =>
      validatePayment(123.45, "USD", "zelle", end, null, now),
    ).not.toThrow();
  });
});
describe("Bot compatible avec les clients existants", () => {
  it("refuse une arborescence cyclique", () =>
    expect(() =>
      validateBot({
        ...initialBot,
        nodes: [{ ...initialBot.nodes[0], parent: "help" }],
      }),
    ).toThrow("hiérarchie"));
  it("refuse une référence vers un paiement supprimé", () =>
    expect(() =>
      validateBot({
        ...initialBot,
        nodes: [{ ...initialBot.nodes[0], paymentMethodId: "gone" }],
      }),
    ).toThrow("introuvable"));
  it("synchronise le prix historique depuis le plan actif le plus court", () => {
    const result = validateBot({
      ...initialBot,
      plans: [
        {
          id: "p",
          name: "Mensuel",
          months: 1,
          amountHtgMinor: 50000,
          amountUsdMinor: 500,
          enabled: true,
        },
      ],
      paymentMethods: [
        {
          id: "moncash",
          name: "MonCash",
          currency: "HTG",
          amountMinor: 1,
          months: 6,
          account: "123",
          recipient: "Test",
          enabled: true,
        },
      ],
    });
    expect(result.paymentMethods[0].amountMinor).toBe(50000);
    expect(result.paymentMethods[0].months).toBe(1);
  });
});

it("reconnaît un résultat hérité sans identifiant officiel", () => {
  const p = proposal("ny", "evening", "2026-10-02", ["001", "02", "03"], "NY")!;
  expect(
    matchesPublished(
      {
        id: "legacy-id",
        tirage: "ny",
        periode: "10:30 PM",
        numeros: ["001", "02", "03"],
        date: new Date(2026, 9, 2),
      },
      p,
    ),
  ).toBe(true);
  expect(
    matchesPublished(
      {
        id: "legacy-id",
        tirage: "ny",
        periode: "10:30 PM",
        numeros: ["001", "02", "99"],
        date: new Date(2026, 9, 2),
      },
      p,
    ),
  ).toBe(false);
});
