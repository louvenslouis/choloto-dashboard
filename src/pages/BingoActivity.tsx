import { useState } from "react";
import { MessageCircle, Heart, Trophy, UserRound } from "lucide-react";
import { useCollection, useDocument, type Row } from "../services/data";
import { auth } from "../services/firebase";
import { Badge, Modal, Status } from "../components/ui";
import Comments from "./comments";
export function seenKey(id: string, type: string) {
  return `bingo-seen:${auth.currentUser?.uid}:${id}:${type}`;
}
function readSeen(id: string, type: string): string[] {
  try {
    return JSON.parse(localStorage.getItem(seenKey(id, type)) || "[]");
  } catch {
    return [];
  }
}
export default function BingoActivity({ id }: { id: string }) {
  const comments = useCollection(`bingo/${id}/comments`, "", 0),
    hidden = useCollection(`bingo/${id}/hiddenComments`, "", 0),
    reactions = useCollection(`bingo/${id}/bingostats`, "", 0);
  const [open, setOpen] = useState<"comments" | "reactions" | null>(null),
    [seen, setSeen] = useState(() => ({
      comments: readSeen(id, "comments"),
      reactions: readSeen(id, "reactions"),
    }));
  const commentIds = [
    ...new Set([...comments.rows, ...hidden.rows].map((r) => r.id)),
  ];
  const newComments = commentIds.filter(
      (id) => !seen.comments.includes(id),
    ).length,
    newReactions = reactions.rows.filter(
      (r) => !seen.reactions.includes(r.id),
    ).length;
  const show = (type: "comments" | "reactions") => {
    const ids =
      type === "comments" ? commentIds : reactions.rows.map((r) => r.id);
    localStorage.setItem(seenKey(id, type), JSON.stringify(ids));
    setSeen({ ...seen, [type]: ids });
    setOpen(type);
  };
  return (
    <>
      <div className="bingo-interactions">
        <button onClick={() => show("comments")}>
          <MessageCircle size={17} />
          {comments.loading || hidden.loading ? "—" : commentIds.length}{" "}
          commentaires
          {newComments > 0 && <Badge tone="gold">+{newComments}</Badge>}
        </button>
        <button onClick={() => show("reactions")}>
          <Heart size={17} />
          {reactions.loading ? "—" : reactions.rows.length} réactions
          {newReactions > 0 && <Badge tone="gold">+{newReactions}</Badge>}
        </button>
      </div>
      <Status error={comments.error || hidden.error || reactions.error} />
      {open && (
        <Modal
          title={
            open === "comments" ? "Commentaires du BINGO" : "Réactions au BINGO"
          }
          onClose={() => setOpen(null)}
        >
          {open === "comments" ? (
            <Comments bingoId={id} />
          ) : (
            <>
              <div className="reaction-summary">
                <Badge>{reactions.rows.length} réactions</Badge>
                <Badge tone="green">
                  {reactions.rows.filter((r) => r.gain).length} gains
                </Badge>
                <Badge>
                  {reactions.rows.filter((r) => !r.gain).length} sans gain
                </Badge>
              </div>
              <Status {...reactions} empty={!reactions.rows.length} />
              {reactions.rows.map((r) => (
                <Reaction key={r.id} row={r} />
              ))}
            </>
          )}
        </Modal>
      )}
    </>
  );
}
function Reaction({ row }: { row: Row }) {
  const user = useDocument(`user/${row.user || row.id}`);
  return (
    <div className="reaction-person">
      <span className="avatar">
        <UserRound size={18} />
      </span>
      <div>
        <strong>
          {user.data?.display_name || user.data?.email || "Membre CHOLOTO"}
        </strong>
        <small>{user.data?.email}</small>
      </div>
      <Badge tone={row.gain ? "green" : ""}>
        {row.gain ? (
          <>
            <Trophy size={14} />
            Gain
          </>
        ) : (
          "Sans gain"
        )}
      </Badge>
    </div>
  );
}
