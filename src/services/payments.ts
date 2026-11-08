import {
  collection,
  doc,
  getDocsFromServer,
  query,
  where,
  deleteField,
  runTransaction,
  serverTimestamp,
  Timestamp,
  type DocumentData,
} from "firebase/firestore";
import { auth, db } from "./firebase";
import { asDate, type Row } from "./data";
export const isCompensation = (row: Row) =>
  row.transaction_type === "adjustment" && row.id.startsWith("compensation_");
export const isPayment = (row: Row) =>
  !["adjustment", "cancellation"].includes(row.transaction_type);
export const paymentMethods = [
  "moncash",
  "natcash",
  "zelle",
  "cashapp",
  "virement",
  "cash",
  "stripe",
];
export function suggestedEnd(previous: Date | null, now = new Date()) {
  const base = previous && previous > now ? previous : now;
  const last = new Date(base.getFullYear(), base.getMonth() + 2, 0).getDate();
  return new Date(
    base.getFullYear(),
    base.getMonth() + 1,
    Math.min(base.getDate(), last),
    23,
    59,
    59,
  );
}
export type PaymentTerm = { days: number } | { months: 1 } | { end: Date };

function shiftDays(base: Date, days: number) {
  if (!Number.isSafeInteger(days) || days === 0) return null;
  const end = new Date(base.getTime() + days * 86_400_000);
  const year = end.getUTCFullYear();
  return year >= 1 && year <= 9999 ? end : null;
}

export function paymentEnd(
  term: PaymentTerm,
  previous: Date | null,
  now = new Date(),
) {
  if ("end" in term) return term.end;
  if ("months" in term) return suggestedEnd(previous, now);
  if (term.days < 1) return null;
  return shiftDays(previous && previous > now ? previous : now, term.days);
}
export function validatePayment(
  amount: number,
  currency: string,
  method: string,
  end: Date,
  previous: Date | null,
  now = new Date(),
) {
  if (
    !Number.isFinite(amount) ||
    amount <= 0 ||
    amount > 999999999.99 ||
    Math.abs(amount * 100 - Math.round(amount * 100)) > 0.00001
  )
    throw new Error("Montant invalide.");
  if (!["GDS", "USD"].includes(currency) || !paymentMethods.includes(method))
    throw new Error("Moyen de paiement invalide.");
  if (
    !Number.isFinite(end.getTime()) ||
    end <= now ||
    (previous && end <= previous)
  )
    throw new Error(
      "La nouvelle échéance doit dépasser l’échéance actuelle et la date du jour.",
    );
}
export async function recordPayment(
  input: {
    requestId?: string;
    uid: string;
    amount: number;
    currency: string;
    method: string;
    id: string;
  } & PaymentTerm,
) {
  const { requestId, uid, amount, currency, method, id } = input;
  const request = requestId ? doc(db, "payment_requests", requestId) : null;
  const receipt = doc(
    db,
    "payment_transactions",
    requestId ? `proof_${requestId}` : id,
  );
  await runTransaction(db, async (tx) => {
    const existing = await tx.get(receipt);
    if (existing.exists()) return;
    const proof = request ? await tx.get(request) : null;
    if (
      proof &&
      (!proof.exists() ||
        proof.data()?.status !== "pending" ||
        proof.data()?.user_uid !== uid)
    )
      throw new Error("Cette demande a déjà été traitée.");
    const profile = doc(db, "user", uid),
      snapshot = await tx.get(profile);
    if (!snapshot.exists()) throw new Error("Profil introuvable.");
    const data = snapshot.data(),
      previous = asDate(data.end_sub),
      count = Number(data.member_time) || 0;
    const now = new Date();
    const end = paymentEnd(input, previous, now);
    if (!end) throw new Error("Durée de forfait invalide.");
    validatePayment(amount, currency, method, end, previous, now);
    const details: DocumentData = {
      user_ref: profile,
      user_uid: uid,
      receipt_code: `CH-${receipt.id}`,
      transaction_type: previous ? "renewal" : "subscription",
      new_end_sub: Timestamp.fromDate(end),
      payment_method: method,
      amount,
      currency,
      member_time_before: count,
      member_time_after: count + 1,
      created_at: serverTimestamp(),
      created_by: auth.currentUser!.uid,
      created_by_email: auth.currentUser!.email || "",
    };
    for (const [source, target] of [
      ["email", "user_email"],
      ["display_name", "user_display_name"],
      ["code_personnel", "user_code"],
    ])
      if (typeof data[source] === "string") details[target] = data[source];
    if (previous) details.previous_end_sub = Timestamp.fromDate(previous);
    tx.update(profile, {
      end_sub: Timestamp.fromDate(end),
      method,
      member_time: count + 1,
      updated_time: serverTimestamp(),
    });
    tx.set(receipt, details);
    if (request)
      tx.update(request, {
        status: "approved",
        amount,
        currency,
        payment_method: method,
        transaction_id: receipt.id,
        new_end_sub: Timestamp.fromDate(end),
        reviewed_by: auth.currentUser!.uid,
        reviewed_at: serverTimestamp(),
      });
  });
}
export const newReceiptId = () =>
  doc(collection(db, "payment_transactions")).id;
export async function rejectPayment(id: string, reason: string) {
  if (!reason.trim() || reason.trim().length > 500)
    throw new Error("Indiquez le motif du refus.");
  const ref = doc(db, "payment_requests", id);
  await runTransaction(db, async (tx) => {
    const snapshot = await tx.get(ref);
    if (snapshot.data()?.status !== "pending")
      throw new Error("Demande déjà traitée.");
    tx.update(ref, {
      status: "rejected",
      rejection_reason: reason.trim(),
      reviewed_by: auth.currentUser!.uid,
      reviewed_at: serverTimestamp(),
    });
  });
}
export async function cancelMembership(
  uid: string,
  reason: string,
  refund: number | null,
  currency: string,
  id: string,
) {
  if (!reason.trim() || reason.trim().length > 500)
    throw new Error("Indiquez le motif de l’annulation.");
  if (
    refund !== null &&
    (!Number.isFinite(refund) ||
      refund < 0 ||
      refund > 999999999.99 ||
      !["GDS", "USD"].includes(currency))
  )
    throw new Error("Montant retourné invalide.");
  const profile = doc(db, "user", uid);
  const history = await getDocsFromServer(
    query(
      collection(db, "payment_transactions"),
      where("user_ref", "==", profile),
    ),
  );
  const cancelled = new Set(
    history.docs
      .filter((d) => d.data().transaction_type === "cancellation")
      .map((d) => d.data().related_transaction_ref?.path),
  );
  const latest = history.docs
    .filter(
      (d) =>
        d.data().transaction_type !== "cancellation" &&
        d.data().transaction_type !== "adjustment" &&
        !cancelled.has(d.ref.path),
    )
    .sort(
      (a, b) =>
        (asDate(b.data().created_at)?.getTime() || 0) -
        (asDate(a.data().created_at)?.getTime() || 0),
    )[0];
  const receipt = doc(
    db,
    "payment_transactions",
    latest ? `cancel_${latest.id}` : id,
  );
  await runTransaction(db, async (tx) => {
    const existing = await tx.get(receipt),
      snapshot = await tx.get(profile);
    if (existing.exists()) return;
    if (!snapshot.exists()) throw new Error("Profil introuvable.");
    const data = snapshot.data(),
      previous = asDate(data.end_sub),
      count = Number(data.member_time) || 0;
    if (!previous) throw new Error("Aucun abonnement à annuler.");
    const result: DocumentData = {
      user_ref: profile,
      user_uid: uid,
      receipt_code: `CH-${receipt.id}`,
      transaction_type: "cancellation",
      previous_end_sub: Timestamp.fromDate(previous),
      member_time_before: count,
      member_time_after: count,
      created_at: serverTimestamp(),
      created_by: auth.currentUser!.uid,
      created_by_email: auth.currentUser!.email || "",
      payment_cancelled: !!latest,
      cancellation_reason: reason.trim(),
    };
    for (const [source, target] of [
      ["email", "user_email"],
      ["display_name", "user_display_name"],
      ["code_personnel", "user_code"],
    ])
      if (typeof data[source] === "string") result[target] = data[source];
    if (data.method) result.payment_method = data.method;
    if (latest) result.related_transaction_ref = latest.ref;
    if (refund !== null)
      Object.assign(result, {
        refunded_amount: refund,
        refund_currency: currency,
      });
    tx.update(profile, {
      end_sub: deleteField(),
      method: deleteField(),
      updated_time: serverTimestamp(),
    });
    tx.set(receipt, result);
  });
}

export type ExpiryAdjustment = Date | { shiftDays: number } | null;

export function adjustmentEnd(
  change: ExpiryAdjustment,
  previous: Date | null,
  now = new Date(),
) {
  if (change instanceof Date) return change > now ? change : null;
  if (!previous || previous <= now) return null;
  if (change === null) return previous;
  const shifted = shiftDays(previous, change.shiftDays);
  return shifted && shifted > now ? shifted : null;
}

export async function adjustMembership(
  uid: string,
  change: ExpiryAdjustment,
  id: string,
  method?: string,
) {
  if (method !== undefined && method !== "" && !paymentMethods.includes(method))
    throw new Error("Moyen de paiement invalide.");
  const profile = doc(db, "user", uid),
    receipt = doc(db, "payment_transactions", id);
  await runTransaction(db, async (tx) => {
    const existing = await tx.get(receipt),
      snapshot = await tx.get(profile);
    if (existing.exists()) return;
    if (!snapshot.exists()) throw new Error("Profil introuvable.");
    const data = snapshot.data(),
      previous = asDate(data.end_sub),
      count = Number(data.member_time) || 0;
    const end = adjustmentEnd(change, previous);
    if (!end) throw new Error("L’échéance ajustée doit être dans le futur.");
    // Keep the original Firestore timestamp (including microseconds) on method-only edits.
    const recordedEnd =
      change === null ? data.end_sub : Timestamp.fromDate(end);
    const payload: DocumentData = {
      user_ref: profile,
      user_uid: uid,
      receipt_code: `CH-${id}`,
      transaction_type: "adjustment",
      new_end_sub: recordedEnd,
      member_time_before: count,
      member_time_after: count,
      created_at: serverTimestamp(),
      created_by: auth.currentUser!.uid,
      created_by_email: auth.currentUser!.email || "",
    };
    for (const [source, target] of [
      ["email", "user_email"],
      ["display_name", "user_display_name"],
      ["code_personnel", "user_code"],
    ])
      if (typeof data[source] === "string") payload[target] = data[source];
    if (previous) payload.previous_end_sub = data.end_sub;
    const updatedMethod = method === undefined ? data.method : method;
    if (updatedMethod) payload.payment_method = updatedMethod;
    tx.update(profile, {
      end_sub: recordedEnd,
      ...(method === undefined ? {} : { method: method || deleteField() }),
      updated_time: serverTimestamp(),
    });
    tx.set(receipt, payload);
  });
}
