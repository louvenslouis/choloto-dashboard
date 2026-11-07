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
  it.each([
    [["468", "12", "34"], "68*12", "68X12", "MARYAJ", "68*12"],
    [["116", "60", "00"], "06*00", "60X00", "MARIAGE", "06X00"],
    [["133", "62", "79"], "79*26", "62X79", "MARIAGE", "62X79"],
    [["41", "600", "96", "74"], "69*00", "00X96", "MARIAGE", "00X96"],
    [["25", "430", "33", "61"], "16*33", "33X61", "MARIAGE", "61X33"],
  ] as const)(
    "replays the published marriage for %j",
    (numeros, pair, expected, valeur, boul) => {
      const florida = numeros.length === 4;
      const result = { ...draw, tirage: florida ? "fl" : "ny", numeros };
      const forecast = {
        ...prediction,
        mariage: { boul: [pair, pair.replace("*", "X")] },
      };
      const published = [
        {
          id: "manual",
          date: now,
          dataStack: [
            {
              valeur,
              boul,
              tirage: florida ? "FLORIDA" : "NEW YORK",
              periode: "Soir",
            },
          ],
        },
      ];
      const marriages = (posts: typeof published) =>
        suggestBingo([result], [forecast], posts, now)
          .flatMap((s) => s.items)
          .filter((i) => i.valeur === "MARIAGE")
          .map((i) => i.boul);
      expect(marriages([])).toEqual([expected]);
      expect(marriages(published)).toEqual([]);
    },
  );
  it("requires an explicit pair and only accepts historically verified lot positions and reversals", () => {
    const forecast = {
      ...prediction,
      mariage: {
        boul: [
          "59",
          "27",
          "59*89",
          "95*72",
          "59*59",
          "359X27",
          "59X27X89",
          null,
        ],
      },
    };
    const items = suggestBingo([draw], [forecast], [], now)[0].items;
    expect(items.some((item) => item.valeur === "MARIAGE")).toBe(false);
  });
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
