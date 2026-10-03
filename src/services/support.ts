import {
  collection,
  doc,
  getDocs,
  getDocsFromServer,
  where,
  Timestamp,
  limit,
  query,
  runTransaction,
  serverTimestamp,
  writeBatch,
} from "firebase/firestore";
import { auth, db } from "./firebase";
export type Attachment = {
  base64: string;
  mime_type: string;
  byte_length: number;
  duration_ms?: number;
};
function base64(bytes: Uint8Array) {
  let result = "";
  for (let i = 0; i < bytes.length; i += 8192)
    result += String.fromCharCode(...bytes.subarray(i, i + 8192));
  return btoa(result);
}
export async function imageAttachment(file: File): Promise<Attachment> {
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, 1400 / Math.max(bitmap.width, bitmap.height));
  const canvas = document.createElement("canvas");
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  canvas.getContext("2d")!.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close();
  for (const quality of [0.85, 0.65, 0.45, 0.25]) {
    const blob = await new Promise<Blob | null>((resolve) =>
      canvas.toBlob(resolve, "image/jpeg", quality),
    );
    if (blob && blob.size <= 600000)
      return {
        base64: base64(new Uint8Array(await blob.arrayBuffer())),
        mime_type: "image/jpeg",
        byte_length: blob.size,
      };
  }
  throw new Error("Image trop volumineuse.");
}
export async function audioAttachment(blob: Blob): Promise<Attachment> {
  const context = new AudioContext();
  let decoded: AudioBuffer;
  try {
    decoded = await context.decodeAudioData(await blob.arrayBuffer());
  } finally {
    await context.close();
  }
  const samples = Math.min(Math.floor(decoded.duration * 8000), 240000);
  if (samples < 1) throw new Error("Audio vide.");
  const offline = new OfflineAudioContext(1, samples, 8000),
    source = offline.createBufferSource();
  source.buffer = decoded;
  source.connect(offline.destination);
  source.start();
  const rendered = await offline.startRendering(),
    pcm = rendered.getChannelData(0),
    bytes = new Uint8Array(44 + samples * 2),
    view = new DataView(bytes.buffer);
  const ascii = (offset: number, text: string) =>
    [...text].forEach((c, i) => view.setUint8(offset + i, c.charCodeAt(0)));
  ascii(0, "RIFF");
  view.setUint32(4, bytes.length - 8, true);
  ascii(8, "WAVEfmt ");
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, 1, true);
  view.setUint32(24, 8000, true);
  view.setUint32(28, 16000, true);
  view.setUint16(32, 2, true);
  view.setUint16(34, 16, true);
  ascii(36, "data");
  view.setUint32(40, samples * 2, true);
  pcm.forEach((sample, i) =>
    view.setInt16(
      44 + i * 2,
      Math.max(-1, Math.min(1, sample)) * (sample < 0 ? 32768 : 32767),
      true,
    ),
  );
  return {
    base64: base64(bytes),
    mime_type: "audio/wav",
    byte_length: bytes.length,
    duration_ms: Math.floor((samples * 1000) / 8000),
  };
}
export async function sendReply(
  conversationId: string,
  messageId: string,
  text: string,
  attachment: Attachment | null,
) {
  text = text.trim();
  if (!text || text.length > 1000) throw new Error("Message invalide.");
  const ref = doc(db, "support_conversations", conversationId),
    message = doc(collection(ref, "messages"), messageId);
  await runTransaction(db, async (tx) => {
    const conversation = await tx.get(ref),
      existing = await tx.get(message);
    if (existing.exists()) return;
    if (
      !conversation.exists() ||
      conversation.data().user_uid !== conversationId ||
      conversation.data().status === "deleting"
    )
      throw new Error("Conversation indisponible.");
    const type = attachment?.mime_type === "audio/wav" ? "audio" : "image";
    tx.update(ref, {
      status: "open",
      updated_at: serverTimestamp(),
      last_message: text,
      last_message_id: messageId,
      last_sender_role: "admin",
    });
    tx.set(message, {
      sender_uid: auth.currentUser!.uid,
      sender_role: "admin",
      text,
      created_at: serverTimestamp(),
      ...(attachment ? { attachment_type: type } : {}),
    });
    if (attachment)
      tx.set(doc(collection(message, "attachments"), type), attachment);
  });
}
export async function editMessage(
  conversationId: string,
  id: string,
  text: string,
) {
  text = text.trim();
  if (!text || text.length > 1000) throw new Error("Message invalide.");
  const ref = doc(db, "support_conversations", conversationId),
    message = doc(collection(ref, "messages"), id);
  await runTransaction(db, async (tx) => {
    const c = await tx.get(ref),
      m = await tx.get(message);
    if (m.data()?.sender_role !== "admin")
      throw new Error("Message indisponible.");
    if (c.data()?.last_message_id === id)
      tx.update(ref, { last_message: text, updated_at: serverTimestamp() });
    tx.update(message, { text, edited_at: serverTimestamp() });
  });
}
export async function deleteConversation(id: string) {
  const ref = doc(db, "support_conversations", id);
  await runTransaction(db, async (tx) => {
    if ((await tx.get(ref)).exists()) tx.update(ref, { status: "deleting" });
  });
  for (;;) {
    const messages = await getDocs(
      query(collection(ref, "messages"), limit(100)),
    );
    if (messages.empty) break;
    const batch = writeBatch(db);
    messages.docs.forEach((m) => {
      batch.delete(doc(collection(m.ref, "attachments"), "image"));
      batch.delete(doc(collection(m.ref, "attachments"), "audio"));
      batch.delete(m.ref);
    });
    await batch.commit();
  }
  const batch = writeBatch(db);
  batch.delete(ref);
  await batch.commit();
}

export async function deleteMessage(
  conversationId: string,
  id: string,
  replacementId?: string,
) {
  const ref = doc(db, "support_conversations", conversationId),
    message = doc(collection(ref, "messages"), id);
  await runTransaction(db, async (tx) => {
    const conversation = await tx.get(ref),
      snapshot = await tx.get(message),
      replacement = replacementId
        ? await tx.get(doc(collection(ref, "messages"), replacementId))
        : null;
    if (snapshot.data()?.sender_role !== "admin" || !conversation.exists())
      throw new Error("Message indisponible.");
    const isLast = conversation.data().last_message_id === id;
    if (isLast && !replacement?.exists())
      throw new Error(
        "Le dernier message ne peut pas être supprimé sans message précédent.",
      );
    tx.delete(doc(collection(message, "attachments"), "image"));
    tx.delete(doc(collection(message, "attachments"), "audio"));
    tx.delete(message);
    if (isLast)
      tx.update(ref, {
        last_message: replacement!.data()!.text,
        last_message_id: replacement!.id,
        last_sender_role: replacement!.data()!.sender_role,
        updated_at: serverTimestamp(),
      });
  });
}

export async function cleanExpiredSupport(uid: string) {
  const cutoff = Timestamp.fromMillis(Date.now() - 15 * 86400000);
  while (auth.currentUser?.uid === uid) {
    const conversations = await getDocsFromServer(
      query(
        collection(db, "support_conversations"),
        where("status", "==", "open"),
        where("updated_at", "<=", cutoff),
        limit(20),
      ),
    );
    if (conversations.empty) return;
    for (const conversation of conversations.docs) {
      if (auth.currentUser?.uid !== uid) return;
      for (;;) {
        const messages = await getDocsFromServer(
          query(
            collection(conversation.ref, "messages"),
            where("created_at", "<=", cutoff),
            limit(100),
          ),
        );
        if (messages.empty) break;
        if (auth.currentUser?.uid !== uid) return;
        const batch = writeBatch(db);
        messages.docs.forEach((m) => {
          batch.delete(doc(collection(m.ref, "attachments"), "image"));
          batch.delete(doc(collection(m.ref, "attachments"), "audio"));
          batch.delete(m.ref);
        });
        await batch.commit();
      }
      await runTransaction(db, async (tx) => {
        const snapshot = await tx.get(conversation.ref);
        const data = snapshot.data();
        if (
          data?.status === "open" &&
          data.updated_at instanceof Timestamp &&
          data.updated_at.toMillis() <= cutoff.toMillis()
        )
          tx.delete(conversation.ref);
      });
    }
  }
}
