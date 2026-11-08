import { useEffect, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "./firebase";
import { groupVipHistory } from "./vipDuration";
import type { Row } from "./data";

export function useVipHistory(revision: number) {
  const [history, setHistory] = useState<Map<string, Row[]> | null>(null);
  const [error, setError] = useState("");
  useEffect(() => {
    setHistory(null);
    setError("");
    return onSnapshot(
      collection(db, "payment_transactions"),
      { includeMetadataChanges: true },
      (snapshot) => {
        if (snapshot.metadata.fromCache || snapshot.metadata.hasPendingWrites) {
          setHistory(null);
          return;
        }
        setHistory(
          groupVipHistory(
            snapshot.docs.map((d) => ({ ...d.data(), id: d.id })),
          ),
        );
      },
      (cause) => {
        setHistory(null);
        setError(cause.message);
      },
    );
  }, [revision]);
  return { history, error };
}
