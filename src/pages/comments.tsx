import { useState } from "react";
import {
  doc,
  runTransaction,
  serverTimestamp,
  deleteField,
  updateDoc,
} from "firebase/firestore";
import { auth, db } from "../services/firebase";
import {
  useCollection,
  useDocument,
  dateLabel,
  type Row,
} from "../services/data";
import { Status, useAction } from "../components/ui";
export default function Comments({ bingoId }: { bingoId: string }) {
  const [hidden, setHidden] = useState(false),
    [replies, setReplies] = useState<Record<string, string>>({});
  const path = `bingo/${bingoId}/${hidden ? "hiddenComments" : "comments"}`;
  const state = useCollection(path, "createdAt", 100),
    action = useAction();
  async function toggleHidden(row: Row) {
    const from = doc(db, path, row.id),
      to = doc(
        db,
        `bingo/${bingoId}/${hidden ? "comments" : "hiddenComments"}`,
        row.id,
      );
    await runTransaction(db, async (tx) => {
      const source = await tx.get(from);
      if (!source.exists()) throw new Error("Commentaire introuvable.");
      const data = source.data();
      delete data.hiddenAt;
      delete data.hiddenBy;
      if (!hidden)
        Object.assign(data, {
          hiddenAt: serverTimestamp(),
          hiddenBy: auth.currentUser!.uid,
        });
      tx.set(to, data);
      tx.delete(from);
    });
  }
  return (
    <>
      <div className="tabs">
        <button
          className={!hidden ? "active" : ""}
          onClick={() => setHidden(false)}
        >
          Visibles
        </button>
        <button
          className={hidden ? "active" : ""}
          onClick={() => setHidden(true)}
        >
          Masqués
        </button>
      </div>
      <Status {...state} empty={!state.rows.length} />
      {action.feedback}
      {state.rows.map((row) => (
        <article className="publication" key={row.id}>
          <CommentIdentity uid={row.user} date={row.createdAt} />
          {row.updatedAt && <span className="badge">Modifié</span>}
          <p>{row.text}</p>
          {row.adminReply && <blockquote>{row.adminReply}</blockquote>}
          <div className="actions">
            <button
              disabled={action.busy}
              onClick={() =>
                void action.run(() =>
                  updateDoc(
                    doc(db, path, row.id),
                    row.adminLiked
                      ? {
                          adminLiked: deleteField(),
                          adminLikedAt: deleteField(),
                          adminLikedBy: deleteField(),
                        }
                      : {
                          adminLiked: true,
                          adminLikedAt: serverTimestamp(),
                          adminLikedBy: auth.currentUser!.uid,
                        },
                  ),
                )
              }
            >
              {row.adminLiked ? "♥" : "♡"}
            </button>
            <button
              disabled={action.busy}
              onClick={() => void action.run(() => toggleHidden(row))}
            >
              {hidden ? "Restaurer" : "Masquer"}
            </button>
          </div>
          <form
            className="inline-form"
            onSubmit={(e) => {
              e.preventDefault();
              void action.run(() =>
                updateDoc(doc(db, path, row.id), {
                  adminReply: (replies[row.id] ?? row.adminReply ?? "").trim(),
                  adminReplyAt: serverTimestamp(),
                  adminReplyBy: auth.currentUser!.uid,
                }),
              );
            }}
          >
            <input
              aria-label="Réponse"
              placeholder="Répondre…"
              required
              maxLength={500}
              value={replies[row.id] ?? row.adminReply ?? ""}
              onChange={(e) =>
                setReplies({ ...replies, [row.id]: e.target.value })
              }
            />
            <button disabled={action.busy}>
              {row.adminReply ? "Modifier la réponse" : "Répondre"}
            </button>
            {row.adminReply && (
              <button
                type="button"
                disabled={action.busy}
                onClick={() => {
                  if (confirm("Supprimer la réponse ?"))
                    void action.run(() =>
                      updateDoc(doc(db, path, row.id), {
                        adminReply: deleteField(),
                        adminReplyAt: deleteField(),
                        adminReplyBy: deleteField(),
                      }),
                    );
                }}
              >
                Supprimer la réponse
              </button>
            )}
          </form>
        </article>
      ))}
    </>
  );
}

function CommentIdentity({ uid, date }: { uid: string; date: unknown }) {
  const state = useDocument(`user/${uid}`);
  return (
    <div className="comment-identity">
      <span className="avatar">{(state.data?.display_name || "M")[0]}</span>
      <div>
        <strong>
          {state.data?.display_name || state.data?.email || "Membre CHOLOTO"}
        </strong>
        <small>{dateLabel(date, true)}</small>
      </div>
    </div>
  );
}
