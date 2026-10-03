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
      id: "message-1",
      sender_role: "user",
      text: "Bonjour, comment renouveler ?",
      created_at: stamp,
    },
  ],
};
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
export const query = (ref: unknown, ..._filters: unknown[]) => ref;
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
  docs: (rows[path] || []).map((row) => ({
    id: row.id,
    ref: doc({}, path, String(row.id)),
    data: () => row,
  })),
  empty: !rows[path]?.length,
});
export const onSnapshot = (
  ref: { path: string },
  callback: (s: unknown) => void,
) => {
  queueMicrotask(() => {
    if (ref.path.split("/").length % 2 === 0) {
      const [collection, id] = ref.path.split("/");
      const row = rows[collection]?.find((r) => r.id === id);
      callback({ id, exists: () => !!row, data: () => row });
    } else callback(snapshot(ref.path));
  });
  return () => {};
};
export const getCountFromServer = async (ref: { path: string }) => ({
  data: () => ({ count: ref.path === "user" ? 1248 : 3 }),
});
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
