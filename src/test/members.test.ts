import { describe, it, expect } from "vitest";
import { compareMembers, isNewMember, isVip } from "../services/members";
import type { Row } from "../services/data";
const now = Date.UTC(2026, 9, 3);
const row = (id: string, end?: number): Row => ({
  id,
  display_name: id,
  ...(end === undefined ? {} : { end_sub: new Date(end) }),
});
describe("Tri des membres", () => {
  it("classe les échéances actives proches, puis absentes, puis expirées récentes", () => {
    const rows = [
      row("ancien", now - 1000),
      row("loin", now + 10000),
      row("sans"),
      row("proche", now + 1),
      row("récent", now - 1),
    ];
    expect(
      rows
        .sort((a, b) => compareMembers(a, b, "end_sub", now))
        .map((r) => r.id),
    ).toEqual(["proche", "loin", "sans", "récent", "ancien"]);
  });
  it("utilise la création en l’absence de date de modification", () => {
    const rows: Row[] = [
      { id: "absent" },
      { id: "créé", created_time: new Date(now) },
      { id: "modifié", updated_time: new Date(now + 1) },
    ];
    expect(
      rows
        .sort((a, b) => compareMembers(a, b, "updated_time", now))
        .map((r) => r.id),
    ).toEqual(["modifié", "créé", "absent"]);
  });
  it("départage alphabétiquement les dates égales", () => {
    expect(
      compareMembers(row("Émile"), row("Zoé"), "created_time", now),
    ).toBeLessThan(0);
  });
});
describe("Badges des membres", () => {
  it("limite Nouveau aux six premiers jours et exclut les dates futures", () => {
    expect(isNewMember({ id: "a", created_time: new Date(now) }, now)).toBe(
      true,
    );
    expect(
      isNewMember({ id: "a", created_time: new Date(now - 6 * 86400000) }, now),
    ).toBe(false);
    expect(isNewMember({ id: "a", created_time: new Date(now + 1) }, now)).toBe(
      false,
    );
    expect(isNewMember({ id: "a" }, now)).toBe(false);
  });
  it("calcule le statut à partir de l’échéance", () => {
    expect(isVip(row("actif", now), now)).toBe(true);
    expect(isVip(row("expiré", now - 1), now)).toBe(false);
    expect(isVip(row("gratuit"), now)).toBe(false);
  });
});
