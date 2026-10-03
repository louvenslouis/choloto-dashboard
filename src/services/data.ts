import { useEffect, useState } from "react";
import {
  collection,
  doc,
  onSnapshot,
  query,
  orderBy,
  limit,
  where,
  Timestamp,
  type DocumentData,
} from "firebase/firestore";
import { db } from "./firebase";
export type Row = DocumentData & { id: string };
export function useCollection(
  path: string,
  sort = "date",
  count = 100,
  after = 0,
  equalField = "",
  equalValue = "",
) {
  const [state, setState] = useState<{
    rows: Row[];
    loading: boolean;
    error: string;
  }>({ rows: [], loading: true, error: "" });
  useEffect(() => {
    setState({ rows: [], loading: true, error: "" });
    return onSnapshot(
      query(
        collection(db, path),
        ...(equalField ? [where(equalField, "==", equalValue)] : []),
        ...(sort ? [orderBy(sort, "desc")] : []),
        ...(count > 0 ? [limit(count)] : []),
        ...(after ? [where(sort, ">=", Timestamp.fromMillis(after))] : []),
      ),
      (snapshot) =>
        setState({
          rows: snapshot.docs.map((d) => ({ ...d.data(), id: d.id })),
          loading: false,
          error: "",
        }),
      (error) => setState({ rows: [], loading: false, error: error.message }),
    );
  }, [path, sort, count, after, equalField, equalValue]);
  return state;
}
export function useDocument(path: string) {
  const [state, setState] = useState<{
    data: Row | null;
    loading: boolean;
    error: string;
  }>({ data: null, loading: true, error: "" });
  useEffect(() => {
    setState({ data: null, loading: true, error: "" });
    return onSnapshot(
      doc(db, path),
      (snapshot) =>
        setState({
          data: snapshot.exists()
            ? { ...snapshot.data(), id: snapshot.id }
            : null,
          loading: false,
          error: "",
        }),
      (error) => setState({ data: null, loading: false, error: error.message }),
    );
  }, [path]);
  return state;
}
export function asDate(value: unknown): Date | null {
  if (value instanceof Date) return value;
  if (
    value &&
    typeof value === "object" &&
    "toDate" in value &&
    typeof value.toDate === "function"
  )
    return value.toDate();
  return null;
}
export function dateLabel(value: unknown, time = false) {
  const d = asDate(value);
  return d
    ? new Intl.DateTimeFormat("fr-HT", {
        dateStyle: "medium",
        ...(time ? { timeStyle: "short" as const } : {}),
      }).format(d)
    : "—";
}
export const numberLabel = (value: number) =>
  new Intl.NumberFormat("fr-HT").format(value);
export const errorMessage = (error: unknown) =>
  error instanceof Error ? error.message : "Opération impossible. Réessayez.";
export function localDateInput(date = new Date()) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}
