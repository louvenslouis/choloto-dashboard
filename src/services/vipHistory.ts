import { asDate, type Row } from "./data";

export function vipPeriodStart(now: Date, period: number) {
  const start = new Date(now);
  if (period === 30) start.setDate(start.getDate() - 29);
  else {
    const target = new Date(
      now.getFullYear(),
      now.getMonth() - (period === 90 ? 3 : 6),
      1,
    );
    const lastDay = new Date(
      target.getFullYear(),
      target.getMonth() + 1,
      0,
    ).getDate();
    start.setFullYear(
      target.getFullYear(),
      target.getMonth(),
      Math.min(now.getDate(), lastDay),
    );
  }
  start.setHours(0, 0, 0, 0);
  return start;
}

export function vipHistory(
  rows: Row[],
  start: Date,
  now: Date,
  currentCount: number,
) {
  const histories = new Map<string, { time: number; end: number }[]>();
  for (const row of rows) {
    if (
      !["subscription", "renewal", "adjustment", "cancellation"].includes(
        row.transaction_type,
      )
    )
      continue;
    const time = asDate(row.created_at)?.getTime();
    const uid = row.user_uid || row.user_ref?.id;
    if (!uid || time == null || time > now.getTime()) continue;
    const events = histories.get(uid) || [];
    events.push({
      time,
      end:
        row.transaction_type === "cancellation"
          ? 0
          : asDate(row.new_end_sub)?.getTime() || 0,
    });
    histories.set(uid, events);
  }
  for (const events of histories.values())
    events.sort((a, b) => b.time - a.time);
  const values: number[] = [];
  const date = new Date(start);
  while (date <= now) {
    const today = date.toDateString() === now.toDateString();
    const sample = new Date(date);
    sample.setHours(23, 59, 59, 0);
    let count = 0;
    for (const events of histories.values()) {
      const event = events.find((event) => event.time <= sample.getTime());
      if (event && event.end >= sample.getTime()) count++;
    }
    values.push(today ? currentCount : count);
    date.setDate(date.getDate() + 1);
  }
  return values;
}
