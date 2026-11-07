import { useEffect, useState } from "react";
import { asDate, errorMessage, localDateInput, type Row } from "./data";
import { loadReactionCounts } from "./bingoActivityCounts";

export function useBingoReactionHistory(
  bingos: Row[],
  start: number,
  now: Date,
  ready: boolean,
) {
  const [history, setHistory] = useState<{
    won: number[];
    lost: number[];
  } | null>(null);
  const [error, setError] = useState("");
  useEffect(() => {
    let current = true;
    setHistory(null);
    setError("");
    if (!ready) return;
    const days = new Map<string, number>();
    const date = new Date(start);
    while (date <= now) {
      days.set(localDateInput(date), days.size);
      date.setDate(date.getDate() + 1);
    }
    const publications = new Map<string, number>();
    for (const bingo of bingos) {
      const published = asDate(bingo.date);
      if (!published || published > now) continue;
      const index = days.get(localDateInput(published));
      if (index !== undefined) publications.set(bingo.id, index);
    }
    loadReactionCounts([...publications.keys()])
      .then((counts) => {
        if (!current) return;
        const won = Array<number>(days.size).fill(0);
        const lost = Array<number>(days.size).fill(0);
        for (const [id, index] of publications) {
          won[index] += counts[id].won;
          lost[index] += counts[id].lost;
        }
        setHistory({ won, lost });
      })
      .catch((reason) => {
        if (current) setError(errorMessage(reason));
      });
    return () => {
      current = false;
    };
  }, [bingos, start, now, ready]);
  return { history, error };
}
