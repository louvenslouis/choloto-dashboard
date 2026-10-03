import { Fragment, useEffect, useRef, useState } from "react";
import { doc, updateDoc } from "firebase/firestore";
import {
  ImagePlus,
  Mic,
  Send,
  Square,
  X,
  Search,
  Bot,
  MessagesSquare,
  Clock,
  CheckCircle2,
  Trash2,
  ArrowLeft,
  Zap,
  Headphones,
  UserRound,
  CheckCheck,
  MoreHorizontal,
  Pencil,
  ArrowDown,
} from "lucide-react";
import { db } from "../services/firebase";
import {
  dateLabel,
  asDate,
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
import {
  Badge,
  Modal,
  Field,
  Form,
  Submit,
  Status,
  useAction,
} from "../components/ui";
import BotEditor from "./SupportBot";
const memberLabel = (r: Row) =>
  r.user_display_name || r.user_email || "Visiteur anonyme";
const memberReference = (r: Row) =>
  r.guest_access || (!r.user_display_name && !r.user_email)
    ? `Réf. ${String(r.user_uid || r.id)
        .replaceAll("-", "")
        .slice(-6)
        .toUpperCase()}`
    : "";
const waiting = (r: Row) =>
  r.status !== "treated" &&
  r.status !== "deleting" &&
  r.last_sender_role === "user";
const supportStatus = (r: Row) =>
  r.status === "deleting"
    ? "Suppression…"
    : r.status === "treated"
      ? "Traité"
      : waiting(r)
        ? "À répondre"
        : "Répondu";
function SupportAvatar({ row }: { row: Row }) {
  return (
    <span className="support-avatar">
      {memberLabel(row)
        .split(/\s+/)
        .slice(0, 2)
        .map((s: string) => s[0])
        .join("")
        .toUpperCase()}
    </span>
  );
}
export default function Support() {
  const [botDirty, setBotDirty] = useState(false);
  const [count, setCount] = useState(40),
    [selected, setSelected] = useState<string | null>(null),
    [filter, setFilter] = useState("all"),
    [search, setSearch] = useState(""),
    [bot, setBot] = useState(false);
  const state = useCollection("support_conversations", "updated_at", count);
  const conversations = state.rows.filter((r) => r.status !== "deleting");
  const pending = conversations.filter(waiting).length,
    treated = conversations.filter((r) => r.status === "treated").length;
  const rows = conversations.filter(
    (r) =>
      (filter === "all" ||
        (filter === "waiting" ? waiting(r) : r.status === "treated")) &&
      `${memberLabel(r)} ${r.user_email || ""} ${memberReference(r)} ${r.user_uid || r.id} ${r.last_message || ""}`
        .toLowerCase()
        .includes(search.trim().toLowerCase()),
  );
  const active = conversations.find((r) => r.id === selected);
  return (
    <div className={`support-workspace ${active ? "has-selection" : ""}`}>
      <section className="support-sidebar" aria-label="Conversations">
        <div className="support-inbox-heading">
          <div>
            <h1>Service client</h1>
            <span className="badge">
              {state.loading || state.error ? "—" : conversations.length}{" "}
              conversations
            </span>
          </div>
          <button onClick={() => setBot(true)}>
            <Bot size={18} />
            Bot du service client
          </button>
        </div>
        <div className="support-list-scroll">
          <div className="search">
            <Search size={19} />
            <input
              aria-label="Rechercher une conversation"
              placeholder="Rechercher un membre, email ou message…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
            {search && (
              <button
                aria-label="Effacer la recherche"
                onClick={() => setSearch("")}
              >
                <X size={16} />
              </button>
            )}
          </div>
          <div className="support-filters">
            {[
              ["all", "Tous", conversations.length],
              ["waiting", "À répondre", pending],
              ["treated", "Traités", treated],
            ].map(([value, label, total]) => (
              <button
                className={String(value)}
                aria-pressed={filter === value}
                key={value}
                onClick={() => setFilter(String(value))}
              >
                {label} ({state.loading || state.error ? "—" : total})
              </button>
            ))}
          </div>
          <Status loading={state.loading} error={state.error} />
          {!state.loading && !state.error && !rows.length && (
            <div className="support-no-results">
              <MessagesSquare size={32} />
              <p>
                {conversations.length
                  ? "Aucune conversation ne correspond à vos filtres."
                  : "Aucune conversation pour le moment."}
              </p>
              {(search || filter !== "all") && (
                <button
                  onClick={() => {
                    setSearch("");
                    setFilter("all");
                  }}
                >
                  Réinitialiser les filtres
                </button>
              )}
            </div>
          )}
          {rows.map((r) => (
            <button
              className={`support-conversation ${selected === r.id ? "selected" : ""} ${waiting(r) ? "waiting" : ""}`}
              key={r.id}
              onClick={() => setSelected(r.id)}
            >
              <span className="support-card-avatar">
                <SupportAvatar row={r} />
                {waiting(r) && <i />}
              </span>
              <span className="support-card-body">
                <strong>{memberLabel(r)}</strong>
                {r.user_email && r.user_email !== memberLabel(r) && (
                  <small>{r.user_email}</small>
                )}
                {memberReference(r) && <small>{memberReference(r)}</small>}
                <span className="support-preview">{r.last_message}</span>
              </span>
              <span className="support-card-meta">
                <Badge tone={waiting(r) ? "gold" : "green"}>
                  {supportStatus(r)}
                </Badge>
                <small>{shortDate(r.updated_at)}</small>
              </span>
            </button>
          ))}
          {state.rows.length === count && (
            <button onClick={() => setCount(count + 40)}>Charger plus</button>
          )}
        </div>
      </section>
      {active ? (
        <Conversation
          key={active.id}
          row={active}
          close={() => setSelected(null)}
        />
      ) : (
        <section className="support-empty-pane">
          <span className="support-empty-icon">
            <MessagesSquare size={40} />
          </span>
          <h2>Sélectionnez une conversation</h2>
          <div className="support-quick-stats">
            <div>
              <Clock size={22} />
              <strong>{state.loading || state.error ? "—" : pending}</strong>
              <small>À répondre</small>
            </div>
            <div>
              <CheckCircle2 size={22} />
              <strong>{state.loading || state.error ? "—" : treated}</strong>
              <small>Traitées</small>
            </div>
          </div>
        </section>
      )}
      {bot && (
        <Modal
          title="Bot du service client"
          onClose={() => {
            if (!botDirty || confirm("Quitter sans publier ?")) {
              setBot(false);
              setBotDirty(false);
            }
          }}
        >
          <BotEditor onDirtyChange={setBotDirty} />
        </Modal>
      )}
    </div>
  );
}
function shortDate(value: unknown) {
  const date = asDate(value);
  return date
    ? date.toLocaleDateString() === new Date().toLocaleDateString()
      ? date.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })
      : date.toLocaleDateString("fr-FR", { day: "2-digit", month: "2-digit" })
    : "—";
}
const cannedResponses = [
  "Bonjou fanmi! Byenveni sou CHOLOTO. Ou vle antre nan VIP a oswa renouvle plan ou?",
  "Nan ki peyi ou ye, tanpri? Konsa n ap ka ba ou pri ak mwayen peman ki disponib pou ou.",
  "Ou vle peye pa MonCash, NatCash oswa Zelle? Di nou kiyès pou nou voye enfòmasyon peman yo ba ou.",
  "Anvan ou voye kòb la, mande nou konfime nimewo ak non moun k ap resevwa peman an.",
  "Pou nou ka aktive VIP a sou kont ou, kreye yon kont CHOLOTO oswa konekte sou kont ou deja genyen an.",
  "Lè ou fin peye, voye yon foto oswa yon kaptire ekran resi tranzaksyon an isit la. Fòk montan, dat ak referans tranzaksyon an parèt klè.",
  "Mèsi pou enfòmasyon yo. N ap verifye peman an anvan nou konfime aktivasyon VIP ou a.",
  "Si ou deja peye men VIP a toujou bloke, voye resi a ak yon kaptire ekran sa ki parèt sou kont ou pou nou verifye.",
  "Se sou kont CHOLOTO ou w ap jwenn kontni VIP a, tankou boul ak maryaj yo. Konekte sou kont ki gen abònman an.",
  "Ki mesaj erè ou wè sou ekran an? Voye yon kaptire ekran isit la pou nou ka ede ou.",
];
function Conversation({ row, close }: { row: Row; close: () => void }) {
  const [editing, setEditing] = useState<Row | null>(null);
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
    <section className="support-chat">
      <div className="support-chat-heading">
        <button
          className="support-back"
          aria-label="Retour aux conversations"
          onClick={close}
        >
          <ArrowLeft size={20} />
        </button>
        <SupportAvatar row={row} />
        <div>
          <h2>{memberLabel(row)}</h2>
          <small>{row.user_email || memberReference(row)}</small>
        </div>
        <Badge tone={waiting(row) ? "gold" : "green"}>
          {supportStatus(row)}
        </Badge>
        <button
          className="support-close"
          aria-label="Fermer la conversation"
          onClick={close}
        >
          <X size={18} />
        </button>
      </div>
      <div className="support-chat-actions">
        <button
          disabled={action.busy || row.status === "treated"}
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
          <CheckCircle2 size={17} />
          {row.status === "treated" ? "Traité" : "Marquer traité"}
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
          <Trash2 size={17} />
          Effacer
        </button>
      </div>
      <div className="messages">
        <Status {...messages} />
        {messages.rows.length === count && (
          <button onClick={() => setCount(count + 50)}>
            Messages précédents
          </button>
        )}
        {[...messages.rows].reverse().map((m, index, ordered) => (
          <Fragment key={m.id}>
            {(index === 0 ||
              asDate(m.created_at)?.toDateString() !==
                asDate(ordered[index - 1].created_at)?.toDateString()) && (
              <div className="support-date-divider">
                {dateLabel(m.created_at)}
              </div>
            )}
            <article
              className={`message ${m.sender_role === "admin" ? "admin" : ""}`}
              key={m.id}
            >
              <div className="message-author">
                {m.sender_role === "admin" ? (
                  <Headphones size={14} />
                ) : (
                  <UserRound size={14} />
                )}
                <strong>
                  {m.sender_role === "admin"
                    ? "Administration CHOLOTO"
                    : memberLabel(row)}
                </strong>
              </div>
              <p>{m.text}</p>
              {m.attachment_type && (
                <MessageAttachment
                  path={`support_conversations/${row.id}/messages/${m.id}/attachments/${m.attachment_type}`}
                />
              )}
              <small>
                {shortDate(m.created_at)}
                {m.edited_at ? " · Modifié" : ""}
                {m.sender_role === "admin" && <CheckCheck size={14} />}
              </small>
              {m.sender_role === "admin" && (
                <details className="support-message-menu">
                  <summary aria-label="Actions du message">
                    <MoreHorizontal size={17} />
                  </summary>
                  <div>
                    <button
                      disabled={action.busy}
                      onClick={() => setEditing(m)}
                    >
                      <Pencil size={14} />
                      Modifier
                    </button>
                    <button
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
                      <Trash2 size={14} />
                      Supprimer
                    </button>
                  </div>
                </details>
              )}
            </article>
          </Fragment>
        ))}
        <div ref={bottom} />
      </div>
      <div className="support-composer">
        {action.feedback}
        {!recording && (
          <div className="quick-replies">
            {cannedResponses.map((reply) => (
              <button
                key={reply}
                disabled={action.busy}
                onClick={() => setText(reply)}
              >
                <Zap size={14} />
                {reply}
              </button>
            ))}
          </div>
        )}
        {recording && (
          <div className="recording-status">
            <span />
            Enregistrement…
          </div>
        )}
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
          <div className="support-compose-row">
            <textarea
              aria-label="Message"
              placeholder="Écrire une réponse…"
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
                disabled={
                  action.busy || recording || (!text.trim() && !attachment)
                }
              >
                <Send size={17} />
                <span>Envoyer</span>
              </button>
            </div>
          </div>
        </form>
      </div>
      {editing && (
        <Modal title="Modifier le message" onClose={() => setEditing(null)}>
          <EditSupportMessage
            row={editing}
            conversationId={row.id}
            done={() => setEditing(null)}
          />
        </Modal>
      )}
    </section>
  );
}
function EditSupportMessage({
  row,
  conversationId,
  done,
}: {
  row: Row;
  conversationId: string;
  done: () => void;
}) {
  const [text, setText] = useState(row.text || ""),
    action = useAction();
  return (
    <Form
      onSubmit={() =>
        void action.run(async () => {
          await editMessage(conversationId, row.id, text);
          done();
        }, "")
      }
    >
      <Field label="Message à modifier">
        <textarea
          required
          maxLength={1000}
          value={text}
          onChange={(e) => setText(e.target.value)}
        />
      </Field>
      {action.feedback}
      <Submit busy={action.busy} />
    </Form>
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
