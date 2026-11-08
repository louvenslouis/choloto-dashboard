import { useEffect, useState } from "react";
import {
  collection,
  doc,
  documentId,
  onSnapshot,
  or,
  query,
  where,
  type Query,
} from "firebase/firestore";
import { db } from "./firebase";
import type { Row } from "./data";
import { groupVipHistory } from "./vipDuration";
import { useVipBadgeTiers } from "./vipBadges";
import { memberVipBadge, useVipClock } from "./memberVipBadge";

type BadgeSource = { profile: Row; receipts: Row[] };

export function useSupportBadges(conversations: Row[]) {
  const ids = conversations
    .filter((row) => !row.guest_access)
    .map((row) => row.user_uid || row.id)
    .filter(
      (uid): uid is string =>
        typeof uid === "string" && !!uid && !uid.includes("/"),
    );
  const key = JSON.stringify([...new Set(ids)].sort());
  const [sources, setSources] = useState<BadgeSource[]>([]);
  const { tiers } = useVipBadgeTiers();
  useEffect(() => {
    const uids: string[] = JSON.parse(key);
    const sourcesByUid = new Map<string, BadgeSource>();
    const stops: (() => void)[] = [];
    let listening = true;
    setSources([]);
    // Each member contributes two alternatives to the receipt query (UID and legacy reference).
    for (let i = 0; i < uids.length; i += 15) {
      const group = uids.slice(i, i + 15);
      let profiles: Row[] = [];
      let histories: Map<string, Row[]> | null = null;
      function publish() {
        group.forEach((id) => sourcesByUid.delete(id));
        if (histories) {
          for (const profile of profiles) {
            sourcesByUid.set(profile.id, {
              profile,
              receipts: histories.get(profile.id) ?? [],
            });
          }
        }
        setSources([...sourcesByUid.values()]);
      }
      function watch(source: Query, update: (rows: Row[] | null) => void) {
        stops.push(
          onSnapshot(
            source,
            { includeMetadataChanges: true },
            (snapshot) => {
              if (!listening) return;
              update(
                snapshot.metadata.fromCache ||
                  snapshot.metadata.hasPendingWrites
                  ? null
                  : snapshot.docs.map((d) => ({ ...d.data(), id: d.id })),
              );
              publish();
            },
            () => {
              if (!listening) return;
              update(null);
              publish();
            },
          ),
        );
      }
      watch(
        query(collection(db, "user"), where(documentId(), "in", group)),
        (rows) => {
          profiles = rows ?? [];
        },
      );
      watch(
        query(
          collection(db, "payment_transactions"),
          or(
            where("user_uid", "in", group),
            where(
              "user_ref",
              "in",
              group.map((id) => doc(db, "user", id)),
            ),
          ),
        ),
        (rows) => {
          histories = rows && groupVipHistory(rows);
        },
      );
    }
    return () => {
      listening = false;
      stops.forEach((stop) => stop());
    };
  }, [key]);

  const now = useVipClock(sources.map((source) => source.profile));
  return new Map(
    sources.map(({ profile, receipts }) => [
      profile.id,
      memberVipBadge(profile, receipts, tiers, now),
    ]),
  );
}
