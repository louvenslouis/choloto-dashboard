const now = new Date();
const stamp = { toDate: () => now };
const rows: Record<string, Record<string, unknown>[]> = {
  resultats: [
    {
      id: "draw-1",
      tirage: "ny",
      periode: "02:30 PM",
      date: stamp,
      numeros: ["031", "04", "25"],
    },
    {
      id: "draw-2",
      tirage: "fl",
      periode: "01:34 PM",
      date: stamp,
      numeros: ["03", "124", "26", "07"],
    },
  ],
  bingo: [
    {
      id: "bingo-1",
      date: stamp,
      dataStack: [
        { tirage: "NEW YORK", periode: "Midi", boul: "31", valeur: "1er lot" },
      ],
    },
  ],
  "bingo/bingo-1/bingostats": [
    { id: "reaction-1", user: "member-1", gain: true },
    { id: "reaction-2", user: "member-2", gain: true },
    { id: "reaction-3", user: "member-3", gain: false },
  ],
  "bingo/bingo-1/comments": [
    { id: "comment-1", user: "member-1", text: "Bravo !", createdAt: stamp },
  ],
  prediction: [
    {
      id: "prediction-1",
      date: stamp,
      periode: "Matin",
      pourcentage: 85,
      boloto: { boul: ["12", "24", "36", "48"] },
    },
  ],
  user: [
    {
      id: "member-1",
      display_name: "Membre Test",
      email: "membre@example.test",
      code_personnel: "CH-0001",
      created_time: stamp,
      end_sub: { toDate: () => new Date(Date.now() + 864000000) },
      member_time: 1,
    },
  ],
  payment_requests: [
    {
      id: "request-1",
      created_at: stamp,
      user_uid: "member-1",
      status: "pending",
      amount: 500,
      currency: "GDS",
      payment_method: "moncash",
    },
  ],
  payment_transactions: [
    {
      id: "payment-1",
      user_uid: "member-1",
      transaction_type: "renewal",
      payment_method: "moncash",
      receipt_code: "CH-payment-1",
      user_display_name: "Membre Test",
      user_email: "membre@example.test",
      amount: 500,
      currency: "GDS",
      created_at: stamp,
      new_end_sub: stamp,
    },
  ],
  support_conversations: [
    {
      id: "member-1",
      user_uid: "member-1",
      user_display_name: "Membre Test",
      updated_at: stamp,
      last_message: "Bonjour, comment renouveler ?",
      last_sender_role: "user",
      status: "open",
    },
  ],
  "support_conversations/member-1/messages": [
    {
      id: "admin-message",
      sender_role: "admin",
      text: "Bonjour, nous allons vous aider.",
      created_at: stamp,
    },
    {
      id: "message-1",
      sender_role: "user",
      text: "Bonjour, comment renouveler ?",
      created_at: stamp,
    },
  ],
};
if (new URLSearchParams(location.search).has("vip-duration-fixture")) {
  const daysAgo = (days: number) => ({
    toDate: () => new Date(+now - days * 86_400_000),
  });
  rows.user[0].created_time = daysAgo(60);
  rows.user[0].end_sub = daysAgo(-10);
  Object.assign(rows.payment_transactions[0], {
    created_at: daysAgo(35),
    new_end_sub: rows.user[0].end_sub,
    transaction_type: "subscription",
    member_time_before: 0,
    member_time_after: 1,
  });
}
if (new URLSearchParams(location.search).has("reaction-fixture")) {
  for (const [i, [offset, wins, misses]] of [
    [-30, 50, 50],
    [-29, 1, 3],
    [-29, 2, 1],
    [-23, 7, 2],
    [-17, 5, 3],
    [-12, 1, 4],
    [-5, 8, 6],
    [-2, 2, 3],
    [1, 50, 50],
  ].entries()) {
    const date = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate() + offset,
    );
    const id = `bingo-history-${i}`;
    rows.bingo.push({ id, date: { toDate: () => date } });
    rows[`bingo/${id}/bingostats`] = Array.from(
      { length: wins + misses },
      (_, n) => ({
        id: `reaction-${n}`,
        gain: n < wins,
      }),
    );
  }
}
if (new URLSearchParams(location.search).has("compensation-fixture")) {
  const id = `compensation_operation1_${"member".repeat(20)}`;
  rows.payment_transactions.push({
    id,
    user_uid: "member-1",
    transaction_type: "adjustment",
    receipt_code: `CH-${id}`,
    user_display_name: "Membre Test",
    user_email: "membre@example.test",
    created_at: stamp,
    previous_end_sub: stamp,
    new_end_sub: { toDate: () => new Date(+now + 3 * 86400000) },
  });
}
export const collection = (base: unknown, ...path: string[]) => ({
  path: [
    typeof base === "object" && base && "path" in base ? base.path : "",
    ...path,
  ]
    .filter(Boolean)
    .join("/"),
});
export const doc = (base: unknown, ...path: string[]) => {
  const ref = collection(base, ...path);
  return { ...ref, id: ref.path.split("/").at(-1) };
};
export const query = (ref: { path: string }, ...filters: unknown[][]) => ({
  ...ref,
  filters,
});
export const where = (...args: unknown[]) => args;
export const orderBy = (...args: unknown[]) => args;
export const limit = (...args: unknown[]) => args;
export const Timestamp = {
  now: () => stamp,
  fromDate: (date: Date) => ({ toDate: () => date }),
  fromMillis: (n: number) => ({ toDate: () => new Date(n) }),
};
export const serverTimestamp = () => stamp;
export const deleteField = () => null;
const snapshot = (path: string) => ({
  metadata: { fromCache: false, hasPendingWrites: false },
  docs: (rows[path] || []).map((row) => ({
    id: row.id,
    ref: doc({}, path, String(row.id)),
    data: () => row,
  })),
  empty: !rows[path]?.length,
});
export const onSnapshot = (
  ref: { path: string },
  optionsOrCallback: object | ((s: unknown) => void),
  next?: (s: unknown) => void,
) => {
  const callback =
    typeof optionsOrCallback === "function" ? optionsOrCallback : next!;
  queueMicrotask(() => {
    if (ref.path.split("/").length % 2 === 0) {
      const [collection, id] = ref.path.split("/");
      const row = rows[collection]?.find((r) => r.id === id);
      callback({ id, exists: () => !!row, data: () => row });
    } else callback(snapshot(ref.path));
  });
  return () => {};
};
export const getCountFromServer = async (ref: {
  path: string;
  filters?: unknown[][];
}) => {
  if (ref.path.endsWith("/bingostats")) {
    const documents = rows[ref.path] ?? [];
    const count = documents.filter(
      (row) =>
        ref.filters?.every(
          ([field, op, value]) => op === "==" && row[String(field)] === value,
        ) ?? true,
    ).length;
    return { data: () => ({ count }) };
  }
  return { data: () => ({ count: ref.path === "user" ? 1248 : 3 }) };
};
export const getDocsFromServer = async (ref: { path: string }) =>
  snapshot(ref.path);
export const getDocs = getDocsFromServer;
export const addDoc = async () => {
  throw new Error("Écriture désactivée dans les tests navigateur.");
};
export const updateDoc = addDoc;
export const deleteDoc = addDoc;
export const runTransaction = addDoc;
export const writeBatch = () => ({ delete: () => {}, commit: addDoc });
