import { useEffect, useState } from "react";
import { asDate, type Row } from "./data";
import { isVip } from "./members";
import { formatVipTime, measureVipTime, vipBadgeIndex } from "./vipDuration";
import type { VipBadgeTier } from "./vipBadges";

export type Membership = {
  active: boolean;
  duration: string;
  rank: number;
  tier?: VipBadgeTier;
};

export function memberVipBadge(
  member: Row,
  receipts: Row[] | null,
  tiers: VipBadgeTier[],
  asOf: number,
): Membership {
  const time = receipts && measureVipTime(member, receipts, asOf);
  const active = isVip(member, asOf);
  const rank = time ? vipBadgeIndex(time, tiers, active) : -1;
  return {
    active,
    duration: time ? formatVipTime(time) : "—",
    rank,
    tier: tiers[rank],
  };
}

export function useVipClock(rows: Row[]) {
  const [, tick] = useState(0);
  const now = Date.now();
  const nextUpdate = rows.reduce((next, row) => {
    const end = asDate(row.end_sub)?.getTime();
    return end !== undefined && end >= now ? Math.min(next, end + 1) : next;
  }, now + 60_000);
  useEffect(() => {
    const timer = window.setTimeout(
      () => tick((n) => n + 1),
      Math.max(0, nextUpdate - Date.now()),
    );
    return () => window.clearTimeout(timer);
  }, [nextUpdate]);
  return now;
}
