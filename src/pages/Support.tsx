import { useEffect, useRef, useState } from "react";
import { doc, updateDoc } from "firebase/firestore";
import { ImagePlus, Mic, Send, Square, X } from "lucide-react";
import { db } from "../services/firebase";
import {
  dateLabel,
  useCollection,
  useDocument,
  type Row,
} from "../services/data";
import {
  audioAttachment,
  deleteConversation,
  deleteMessage,
  editMessage,
  imageAttachment,
  sendReply,
  type Attachment,
} from "../services/support";
import { Badge, Modal, Panel, Status, useAction } from "../components/ui";
import BotEditor from "./SupportBot";
export default function Support() {
  const [count, setCount] = useState(40),
    [selected, setSelected] = useState<Row | null>(null),
    [filter, setFilter] = useState("all"),
    [bot, setBot] = useState(false);
  const state = useCollection("support_conversations", "updated_at", count);
  const rows = state.rows.filter(
    (r) =>
      r.status !== "deleting" &&
      (filter === "all" ||
        (filter === "waiting"
          ? r.last_sender_role === "user" && r.status !== "treated"
          : r.status === "treated")),
  );
  return (
    <>
      <div className="toolbar">
        <select
          aria-label="Filtrer les conversations"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        >
          <option value="all">Toutes les conversations</option>
          <option value="waiting">En attente</option>
          <option value="treated">Traitées</option>
        </select>
        <button onClick={() => setBot(true)}>Configurer le bot</button>
      </div>
      <div className={`inbox ${selected ? "has-selection" : ""}`}>
        <Panel title="Conversations">
          <Status {...state} empty={!rows.length} />
          {rows.map((r) => (
            <button
              className={`conversation ${selected?.id === r.id ? "selected" : ""}`}
              key={r.id}
              onClick={() => setSelected(r)}
            >
              <div>
                <strong>
                  {r.user_display_name || r.user_email || "Visiteur anonyme"}
                </strong>
                <small>{dateLabel(r.updated_at, true)}</small>
              </div>
              <p>{r.last_message}</p>
              {r.status === "treated" ? (
                <Badge>Traité</Badge>
              ) : r.last_sender_role === "user" ? (
                <Badge tone="amber">En attente</Badge>
              ) : null}
            </button>
          ))}
          {state.rows.length === count && (
            <button onClick={() => setCount(count + 40)}>Charger plus</button>
          )}
        </Panel>
        {selected ? (
          <Conversation
            key={selected.id}
            row={selected}
            close={() => setSelected(null)}
          />
        ) : (
          <Panel>
            <p className="empty">Sélectionnez une conversation</p>
          </Panel>
        )}
      </div>
      {bot && (
        <Modal title="Assistant CHOLOTO" onClose={() => setBot(false)}>
          <BotEditor />
        </Modal>
      )}
    </>
  );
}
function Conversation({ row, close }: { row: Row; close: () => void }) {
  const [count, setCount] = useState(50),
    [text, setText] = useState(""),
    [attachment, setAttachment] = useState<Attachment | null>(null),
    [recording, setRecording] = useState(false),
    [messageId, setMessageId] = useState(() => crypto.randomUUID());
  const messages = useCollection(
      `support_conversations/${row.id}/messages`,
      "created_at",
      count,
    ),
    action = useAction(),
    bottom = useRef<HTMLDivElement>(null),
    recorder = useRef<MediaRecorder | null>(null),
    timer = useRef<ReturnType<typeof setTimeout> | null>(null),
    mounted = useRef(true);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
      if (timer.current) clearTimeout(timer.current);
      const current = recorder.current;
      if (current && current.state !== "inactive") current.stop();
      current?.stream.getTracks().forEach((track) => track.stop());
    };
  }, []);
  useEffect(() => {
    bottom.current?.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }, [messages.rows.length]);
  async function startRecording() {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    if (!mounted.current) {
      stream.getTracks().forEach((t) => t.stop());
      return;
    }
    const rec = new MediaRecorder(stream),
      chunks: BlobPart[] = [];
    recorder.current = rec;
    rec.ondataavailable = (e) => chunks.push(e.data);
    rec.onstop = () => {
      stream.getTracks().forEach((t) => t.stop());
      if (timer.current) clearTimeout(timer.current);
      if (!mounted.current) return;
      setRecording(false);
      void action.run(
        async () =>
          setAttachment(
            await audioAttachment(new Blob(chunks, { type: rec.mimeType })),
          ),
        "",
      );
    };
    rec.start();
    setRecording(true);
    timer.current = setTimeout(() => {
      if (rec.state !== "inactive") rec.stop();
    }, 30000);
  }
  return (
    <Panel
      title={row.user_display_name || row.user_email || "Conversation"}
      action={
        <button aria-label="Fermer la conversation" onClick={close}>
          <X size={18} />
        </button>
      }
    >
      <div className="actions">
        <button
          disabled={action.busy}
          onClick={() =>
            void action.run(
              () =>
                updateDoc(doc(db, "support_conversations", row.id), {
                  status: "treated",
                }),
              "Conversation traitée",
            )
          }
        >
          Marquer comme traité
        </button>
        <button
          disabled={action.busy}
          onClick={() => {
            if (confirm("Supprimer cette conversation et ses messages ?"))
              void action.run(async () => {
                await deleteConversation(row.id);
                close();
              });
          }}
        >
          Supprimer
        </button>
      </div>
      <div className="messages">
        <Status {...messages} />
        {messages.rows.length === count && (
          <button onClick={() => setCount(count + 50)}>
            Messages précédents
          </button>
        )}
        {[...messages.rows].reverse().map((m) => (
          <article
            className={`message ${m.sender_role === "admin" ? "admin" : ""}`}
            key={m.id}
          >
            <p>{m.text}</p>
            {m.attachment_type && (
              <MessageAttachment
                path={`support_conversations/${row.id}/messages/${m.id}/attachments/${m.attachment_type}`}
              />
            )}
            <small>
              {dateLabel(m.created_at, true)}
              {m.edited_at ? " · modifié" : ""}
            </small>
            {m.sender_role === "admin" && (
              <button
                className="text-button"
                onClick={() => {
                  const value = prompt("Modifier le message", m.text);
                  if (value !== null)
                    void action.run(() => editMessage(row.id, m.id, value));
                }}
              >
                Modifier
              </button>
            )}
            {m.sender_role === "admin" && (
              <button
                className="text-button"
                disabled={action.busy}
                onClick={() => {
                  if (confirm("Supprimer ce message ?"))
                    void action.run(
                      () =>
                        deleteMessage(
                          row.id,
                          m.id,
                          messages.rows.find((r) => r.id !== m.id)?.id,
                        ),
                      "",
                    );
                }}
              >
                Supprimer
              </button>
            )}
          </article>
        ))}
        <div ref={bottom} />
      </div>
      {action.feedback}
      <form
        onSubmit={(e) => {
          e.preventDefault();
          void action.run(async () => {
            await sendReply(
              row.id,
              messageId,
              text.trim() ||
                (attachment?.mime_type === "audio/wav"
                  ? "Message vocal"
                  : "Image"),
              attachment,
            );
            setText("");
            setAttachment(null);
            setMessageId(crypto.randomUUID());
          }, "");
        }}
      >
        {attachment && (
          <div className="attachment-preview">
            {attachment.mime_type === "audio/wav" ? (
              <audio
                controls
                src={`data:audio/wav;base64,${attachment.base64}`}
              />
            ) : (
              <img
                alt="Pièce jointe"
                src={`data:image/jpeg;base64,${attachment.base64}`}
              />
            )}
            <button
              type="button"
              aria-label="Retirer la pièce jointe"
              onClick={() => setAttachment(null)}
            >
              <X size={16} />
            </button>
          </div>
        )}
        <textarea
          aria-label="Message"
          placeholder="Écrire un message…"
          maxLength={1000}
          value={text}
          onChange={(e) => setText(e.target.value)}
        />
        <div className="form-actions">
          <label className="file-button" aria-label="Joindre une image">
            <ImagePlus size={18} />
            <input
              type="file"
              accept="image/*"
              disabled={action.busy || recording}
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file)
                  void action.run(
                    async () => setAttachment(await imageAttachment(file)),
                    "",
                  );
                e.target.value = "";
              }}
            />
          </label>
          <button
            type="button"
            disabled={action.busy}
            aria-label={
              recording
                ? "Arrêter l’enregistrement"
                : "Enregistrer un message vocal"
            }
            onClick={() =>
              recording
                ? recorder.current?.stop()
                : void action.run(startRecording, "")
            }
          >
            {recording ? <Square size={18} /> : <Mic size={18} />}
          </button>
          <button
            className="primary"
            disabled={action.busy || recording || (!text.trim() && !attachment)}
          >
            <Send size={17} />
            Envoyer
          </button>
        </div>
      </form>
    </Panel>
  );
}
function MessageAttachment({ path }: { path: string }) {
  const state = useDocument(path);
  return (
    <>
      <Status loading={state.loading} error={state.error} />
      {state.data &&
        (state.data.mime_type === "audio/wav" ? (
          <audio
            controls
            preload="none"
            src={`data:audio/wav;base64,${state.data.base64}`}
          />
        ) : state.data.mime_type === "image/jpeg" ? (
          <a
            href={`data:image/jpeg;base64,${state.data.base64}`}
            download="image.jpg"
          >
            <img
              alt="Image envoyée"
              src={`data:image/jpeg;base64,${state.data.base64}`}
            />
          </a>
        ) : (
          <p>Pièce jointe indisponible</p>
        ))}
    </>
  );
}
