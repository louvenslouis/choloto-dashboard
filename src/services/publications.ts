import {
  addDoc,
  collection,
  doc,
  runTransaction,
  serverTimestamp,
  Timestamp,
  getDocsFromServer,
  query,
  where,
} from "firebase/firestore";
import { auth, db } from "./firebase";
import { asDate, type Row } from "./data";
export const lotteries: Record<string, string> = {
  ny: "New York",
  fl: "Floride",
  ga: "Georgia",
  nj: "New Jersey",
  tx: "Texas",
  tn: "Tennessee",
  md: "Maryland",
  pa: "Pennsylvania",
};
export const periods: Record<string, string[]> = {
  ny: ["02:30 PM", "10:30 PM"],
  fl: ["01:34 PM", "09:49 PM"],
  ga: ["MIDDAY", "EVENING", "NIGHT"],
  nj: ["MIDDAY", "EVENING"],
  tx: ["MORNING", "DAY", "EVENING", "NIGHT"],
  tn: ["MORNING", "MIDDAY", "EVENING"],
  md: ["MIDDAY", "EVENING"],
  pa: ["DAY", "EVENING"],
};
export const predictionGroups = [
  ["boloto", "BOLOTO", 2],
  ["chif3", "3 CHIFFRES", 3],
  ["chif4", "4 CHIFFRES", 4],
  ["mariage", "MARIAGE", 4],
  ["favori", "FAVORI", 2],
  ["soutni", "SOUTNI", 2],
  ["extra", "EXTRA", 2],
] as const;
export function validateNumbers(values: string[], widths: number[]) {
  if (
    values.length !== widths.length ||
    values.some((v, i) => !new RegExp(`^\\d{${widths[i]}}$`).test(v))
  )
    throw new Error("Vérifiez le nombre de chiffres de chaque numéro.");
  return values;
}
export function resultPayload(
  tirage: string,
  periode: string,
  numeros: string[],
  uid: string,
) {
  if (!periods[tirage]?.includes(periode))
    throw new Error("Tirage ou période invalide.");
  validateNumbers(numeros, tirage === "fl" ? [2, 3, 2, 2] : [3, 2, 2]);
  return { tirage, periode, numeros, created_by: uid };
}
export async function publishResult(
  tirage: string,
  periode: string,
  numbers: string[],
) {
  return addDoc(collection(db, "resultats"), {
    ...resultPayload(tirage, periode, numbers, auth.currentUser!.uid),
    date: serverTimestamp(),
  });
}
export type Proposal = {
  id: string;
  code: string;
  period: string;
  date: Date;
  numbers: string[];
  source: string;
};
export function matchesPublished(row: Row, p: Proposal) {
  if (row.id === p.id) return true;
  const date = asDate(row.date);
  return (
    row.tirage === p.code &&
    row.periode === p.period &&
    JSON.stringify(row.numeros) === JSON.stringify(p.numbers) &&
    !!date &&
    (Math.abs(date.getTime() - p.date.getTime()) <= 18 * 3600000 ||
      date.toDateString() === p.date.toDateString())
  );
}
export async function publishOfficial(p: Proposal, historyVerified = false) {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error("Reconnectez-vous.");
  if (!historyVerified) {
    const midnight = new Date(p.date);
    midnight.setHours(0, 0, 0, 0);
    const history = await getDocsFromServer(
      query(
        collection(db, "resultats"),
        where(
          "date",
          ">=",
          Timestamp.fromMillis(
            Math.min(midnight.getTime(), p.date.getTime() - 18 * 3600000),
          ),
        ),
      ),
    );
    if (
      history.docs.some((d) => matchesPublished({ ...d.data(), id: d.id }, p))
    )
      return;
  }
  if (auth.currentUser?.uid !== uid) throw new Error("La session a changé.");
  const ref = doc(db, "resultats", p.id);
  return runTransaction(db, async (tx) => {
    if ((await tx.get(ref)).exists()) return;
    tx.set(ref, {
      ...resultPayload(p.code, p.period, p.numbers, uid),
      date: Timestamp.fromDate(p.date),
    });
  });
}
