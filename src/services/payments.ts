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
import { asDate } from "./data";
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
export async function recordPayment({
  requestId,
  uid,
  amount,
  currency,
  method,
  end,
  id,
}: {
  requestId?: string;
  uid: string;
  amount: number;
  currency: string;
  method: string;
  end: Date;
  id: string;
}) {
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
    validatePayment(amount, currency, method, end, previous);
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
export async function callAdmin(name: string, data: Record<string, unknown>) {
  const token = await auth.currentUser?.getIdToken();
  if (!token) throw new Error("Reconnectez-vous.");
  const response = await fetch(
    `https://us-central1-choloto-6aa5b.cloudfunctions.net/${name}`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ data }),
    },
  );
  const payload = await response.json();
  if (!response.ok || payload.error)
    throw new Error(payload.error?.message || "Le serveur ne répond pas.");
  return payload.data ?? payload.result;
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

export async function adjustMembership(uid: string, end: Date, id: string) {
  if (!Number.isFinite(end.getTime()) || end <= new Date())
    throw new Error("Échéance invalide.");
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
    const payload: DocumentData = {
      user_ref: profile,
      user_uid: uid,
      receipt_code: `CH-${id}`,
      transaction_type: "adjustment",
      new_end_sub: Timestamp.fromDate(end),
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
    if (previous) payload.previous_end_sub = Timestamp.fromDate(previous);
    if (data.method) payload.payment_method = data.method;
    tx.update(profile, {
      end_sub: Timestamp.fromDate(end),
      updated_time: serverTimestamp(),
    });
    tx.set(receipt, payload);
  });
}
