import {
  collection,
  doc,
  getDocsFromServer,
  query,
  runTransaction,
  serverTimestamp,
  Timestamp,
  where,
  type DocumentData,
} from "firebase/firestore";
import { auth, db } from "./firebase";
import { asDate, errorMessage } from "./data";
import { newReceiptId, paymentEnd } from "./payments";

export type CompensationScope = "vip" | "selected";
export type Compensation = {
  id: string;
  adminUid: string;
  days: number;
  scope: CompensationScope;
  uids: string[];
  startedAt: number;
};
export type CompensationResult = {
  applied: number;
  skipped: number;
  failed: number;
  error: string;
};

export function validateCompensationDays(days: number) {
  if (!Number.isSafeInteger(days) || days < 1 || days > 3650)
    throw new Error("Indiquez un nombre entier de jours entre 1 et 3 650.");
}

export function compensationEnd(
  previous: Date | null,
  days: number,
  now: Date,
) {
  validateCompensationDays(days);
  const end = paymentEnd({ days }, previous, now);
  if (!end) throw new Error("Échéance invalide.");
  return end;
}

export async function prepareCompensation(
  days: number,
  scope: CompensationScope,
  selected: string[],
): Promise<Compensation> {
  validateCompensationDays(days);
  const adminUid = auth.currentUser?.uid;
  if (!adminUid) throw new Error("Reconnectez-vous.");
  const startedAt = Date.now();
  const uids =
    scope === "vip"
      ? (
          await getDocsFromServer(
            query(
              collection(db, "user"),
              where("end_sub", ">=", Timestamp.fromMillis(startedAt)),
            ),
          )
        ).docs.map((snapshot) => snapshot.id)
      : [...new Set(selected)];
  if (!uids.length) throw new Error("Aucun membre à compenser.");
  return { id: newReceiptId(), adminUid, days, scope, uids, startedAt };
}

export async function applyCompensation(
  operation: Compensation,
  onProgress: (processed: number) => void = () => {},
): Promise<CompensationResult> {
  validateCompensationDays(operation.days);
  const admin = auth.currentUser;
  if (!admin || admin.uid !== operation.adminUid)
    throw new Error(
      "Reconnectez-vous avec le compte ayant lancé la compensation.",
    );
  const result: CompensationResult = {
    applied: 0,
    skipped: 0,
    failed: 0,
    error: "",
  };
  const uids = [...new Set(operation.uids)];
  let cursor = 0;
  // Small independent transactions keep large audiences below batch limits.
  // A stable receipt per operation/member makes retries safe after a lost reply.
  const worker = async () => {
    while (cursor < uids.length) {
      const uid = uids[cursor++];
      try {
        const status = await runTransaction(db, async (tx) => {
          const profile = doc(db, "user", uid);
          const receipt = doc(
            db,
            "payment_transactions",
            `compensation_${operation.id}_${uid}`,
          );
          if ((await tx.get(receipt)).exists()) return "applied";
          const snapshot = await tx.get(profile);
          if (!snapshot.exists()) return "skipped";
          const data = snapshot.data();
          const previous = asDate(data.end_sub);
          // Recheck a cancellation/expiration that happened after the audience query.
          if (
            operation.scope === "vip" &&
            (!previous || previous.getTime() < operation.startedAt)
          )
            return "skipped";
          const end = compensationEnd(previous, operation.days, new Date());
          const count = Number(data.member_time) || 0;
          // Keep the existing adjustment schema understood by released clients/rules.
          const details: DocumentData = {
            user_ref: profile,
            user_uid: uid,
            receipt_code: `CH-${receipt.id}`,
            transaction_type: "adjustment",
            new_end_sub: Timestamp.fromDate(end),
            member_time_before: count,
            member_time_after: count,
            created_at: serverTimestamp(),
            created_by: admin.uid,
            created_by_email: admin.email || "",
          };
          for (const [source, target] of [
            ["email", "user_email"],
            ["display_name", "user_display_name"],
            ["code_personnel", "user_code"],
          ])
            if (typeof data[source] === "string")
              details[target] = data[source];
          if (previous) details.previous_end_sub = Timestamp.fromDate(previous);
          tx.update(profile, {
            end_sub: Timestamp.fromDate(end),
            updated_time: serverTimestamp(),
          });
          tx.set(receipt, details);
          return "applied";
        });
        result[status]++;
      } catch (error) {
        result.failed++;
        result.error ||= errorMessage(error);
      }
      onProgress(result.applied + result.skipped + result.failed);
    }
  };
  await Promise.all(Array.from({ length: Math.min(5, uids.length) }, worker));
  return result;
}
