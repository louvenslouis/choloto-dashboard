import { asDate, type Row } from "./data";

// Signup and onboarding can initialize end_sub without granting VIP access.
export function initialExpiry(profile: Row, expiry: number | null) {
  if (expiry === null) return true;
  const created = asDate(profile.created_time)?.getTime();
  return (
    (created !== undefined && expiry <= created) ||
    expiry === asDate(profile.onboarding_completed_at)?.getTime()
  );
}

export function isVip(row: Row, now = Date.now()) {
  const end = asDate(row.end_sub)?.getTime();
  return end !== undefined && end >= now && !initialExpiry(row, end);
}
export function compareMembers(a: Row, b: Row, sort: string, now = Date.now()) {
  const alphabetical = () =>
    String(a.display_name?.trim() || a.email || "").localeCompare(
      String(b.display_name?.trim() || b.email || ""),
      "fr",
      { sensitivity: "base" },
    ) ||
    String(a.email || "").localeCompare(String(b.email || ""), "fr", {
      sensitivity: "base",
    });
  if (sort === "name") return alphabetical();
  if (sort === "end_sub") {
    const first = asDate(a.end_sub)?.getTime(),
      second = asDate(b.end_sub)?.getTime();
    const group = (date: number | undefined) =>
      date === undefined ? 1 : date < now ? 2 : 0;
    return (
      group(first) - group(second) ||
      (first !== undefined && second !== undefined
        ? first >= now
          ? first - second
          : second - first
        : 0) ||
      alphabetical()
    );
  }
  const date = (row: Row) =>
    asDate(
      sort === "updated_time"
        ? (row.updated_time ?? row.created_time)
        : row.created_time,
    )?.getTime() ?? -Infinity;
  return date(b) - date(a) || 0 || alphabetical();
}
