import { describe, expect, it } from "vitest";
import { suggestBingo } from "./bingoSuggestions";
const now = new Date("2026-10-14T03:00:00Z");
const draw = {
  id: "draw",
  date: new Date("2026-10-14T02:30:00Z"),
  tirage: "ny",
  periode: "10:30 PM",
  numeros: ["359", "27", "89"],
};
const prediction = {
  id: "prediction",
  date: new Date("2026-10-13T21:00:00Z"),
  periode: "Soir",
  favori: { boul: ["95", "27"] },
  soutni: { boul: ["89"] },
  chif3: { boul: ["359-610"] },
  chif4: { boul: ["2789"] },
};
describe("BINGO suggestions", () => {
  it("does not propose a draw already published from a suggestion", () => {
    expect(
      suggestBingo(
        [draw],
        [prediction],
        [{ id: "suggested_draw", date: now, dataStack: [] }],
        now,
      ),
    ).toEqual([]);
  });
  it("uses the Haiti draw day, exact and reversed balls, and exact 3/4 digit predictions", () => {
    expect(
      suggestBingo([draw], [prediction], [], now)[0].items.map((i) => [
        i.valeur,
        i.boul,
      ]),
    ).toEqual([
      ["1er lot", "59"],
      ["2e lot", "27"],
      ["3e lot", "89"],
      ["LOTO 3", "359"],
      ["LOTO 4", "2789"],
    ]);
  });
  it("preserves zeros and skips Florida Pick 2 when identifying the three lots", () => {
    const result = suggestBingo(
      [
        {
          ...draw,
          tirage: "fl",
          periode: "09:49 PM",
          numeros: ["59", "008", "27", "89"],
        },
      ],
      [
        {
          ...prediction,
          favori: { boul: ["08"] },
          soutni: { boul: [] },
          chif3: { boul: [] },
          chif4: { boul: [] },
        },
      ],
      [],
      now,
    );
    expect(result[0].items.map((i) => i.boul)).toEqual(["08"]);
  });
  it("rejects predictions after the draw, from another day, or another session", () => {
    for (const change of [
      { date: now },
      { date: new Date("2026-10-12T21:00:00Z") },
      { periode: "Midi" },
    ])
      expect(
        suggestBingo([draw], [{ ...prediction, ...change }], [], now),
      ).toEqual([]);
  });
  it("uses only the latest eligible prediction", () => {
    expect(
      suggestBingo(
        [draw],
        [
          prediction,
          {
            ...prediction,
            id: "new",
            date: new Date("2026-10-13T22:00:00Z"),
            favori: { boul: [] },
            soutni: { boul: [] },
            chif3: { boul: [] },
            chif4: { boul: [] },
          },
        ],
        [],
        now,
      ),
    ).toEqual([]);
  });
  it("removes already published items, including legacy lot labels", () => {
    const published = [
      {
        id: "b",
        date: now,
        dataStack: [
          {
            valeur: "PREMIER LO",
            boul: "59",
            tirage: "NEW YORK",
            periode: "Soir",
          },
        ],
      },
    ];
    expect(
      suggestBingo([draw, draw], [prediction], published, now),
    ).toHaveLength(1);
    expect(
      suggestBingo([draw], [prediction], published, now)[0].items.some(
        (i) => i.boul === "59",
      ),
    ).toBe(false);
  });
  it("ignores malformed, future, stale, and unknown draws", () => {
    for (const change of [
      { numeros: ["359", "27"] },
      { date: new Date("2026-10-15T02:30:00Z") },
      { date: new Date("2026-10-10T02:30:00Z") },
      { periode: "unknown" },
      { tirage: "unknown" },
    ])
      expect(
        suggestBingo([{ ...draw, ...change }], [prediction], [], now),
      ).toEqual([]);
  });
});
