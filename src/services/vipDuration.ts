import { asDate, type Row } from "./data";

const day = 86_400_000;
const time = (value: unknown) => asDate(value)?.getTime() ?? null;

export function groupVipHistory(receipts: Row[]) {
  const histories = new Map<string, Row[]>();
  for (const receipt of receipts) {
    const uid = receipt.user_uid || receipt.user_ref?.id;
    if (!uid) continue;
    const history = histories.get(uid);
    if (history) history.push(receipt);
    else histories.set(uid, [receipt]);
  }
  for (const history of histories.values())
    history.sort(
      (a, b) => (time(a.created_at) ?? 0) - (time(b.created_at) ?? 0),
    );
  return histories;
}

// The app can initialize end_sub at signup or onboarding, without granting VIP.
function initialExpiry(profile: Row, expiry: number | null) {
  if (expiry === null) return true;
  const created = time(profile.created_time);
  return (
    (created !== null && expiry <= created) ||
    expiry === time(profile.onboarding_completed_at)
  );
}

export function vipDuration(profile: Row, history: Row[], now: number) {
  const currentEnd = time(profile.end_sub);
  const currentCount = Number(profile.member_time ?? 0);
  const first = history[0];
  if (!first) {
    return currentCount === 0 && initialExpiry(profile, currentEnd)
      ? "0 j"
      : "Indéterminée";
  }

  let partial =
    !initialExpiry(profile, time(first.previous_end_sub)) ||
    Number(first.member_time_before) !== 0;
  let elapsed = 0;
  for (let i = 0; i < history.length; i++) {
    const event = history[i];
    const start = time(event.created_at);
    const next = history[i + 1];
    const nextStart = next ? time(next.created_at) : now;
    // An undated change could interrupt any of the recorded periods.
    if (start === null || nextStart === null) return "Indéterminée";
    if (start > now) break;

    const end = time(event.new_end_sub);
    const expectedEnd = next ? time(next.previous_end_sub) : currentEnd;
    const expectedCount = next ? Number(next.member_time_before) : currentCount;
    // A broken chain leaves the time of the unrecorded change unknown.
    if (
      end !== expectedEnd ||
      Number(event.member_time_after) !== expectedCount
    ) {
      partial = true;
      continue;
    }
    if (event.transaction_type === "cancellation") continue;
    if (end === null) {
      partial = true;
      continue;
    }
    elapsed += Math.max(0, Math.min(now, nextStart, end) - start);
  }
  if (partial && elapsed === 0) return "Indéterminée";
  // Expiry is calculated on validation; Firestore timestamps the receipt on commit.
  // Display completed totals to the nearest minute before converting to whole days.
  const finished = currentEnd === null || currentEnd <= now;
  const displayedTime =
    finished && !partial ? Math.round(elapsed / 60_000) * 60_000 : elapsed;
  const days = Math.floor(displayedTime / day);
  if (!days) return partial ? "Indéterminée" : elapsed ? "< 1 j" : "0 j";
  const months = Math.floor(days / 30);
  const remainder = days % 30;
  const duration = [months && `${months} mois`, remainder && `${remainder} j`]
    .filter(Boolean)
    .join(" ");
  return partial ? `≥ ${duration}` : duration;
}
