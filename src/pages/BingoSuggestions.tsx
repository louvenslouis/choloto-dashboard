import { useMemo, useState } from "react";
import { useCollection, dateLabel, type Row } from "../services/data";
import { suggestBingo } from "../services/bingoSuggestions";
import { Panel, Status } from "../components/ui";
export default function BingoSuggestions({
  onChoose,
}: {
  onChoose: (row: Row) => void;
}) {
  const [enabled, setEnabled] = useState(false);
  return (
    <Panel
      title="BINGO proposés"
      action={
        <button
          type="button"
          aria-pressed={enabled}
          onClick={() => setEnabled(!enabled)}
        >
          {enabled ? "Désactiver" : "Activer"}
        </button>
      }
    >
      {enabled && <ActiveBingoSuggestions onChoose={onChoose} />}
    </Panel>
  );
}
function ActiveBingoSuggestions({
  onChoose,
}: {
  onChoose: (row: Row) => void;
}) {
  const [since] = useState(() => Date.now() - 3 * 86400000);
  const draws = useCollection("resultats", "date", 0, since);
  const predictions = useCollection("prediction", "date", 0, since);
  const bingo = useCollection("bingo", "date", 0, since);
  const suggestions = useMemo(
    () => suggestBingo(draws.rows, predictions.rows, bingo.rows),
    [draws.rows, predictions.rows, bingo.rows],
  );
  const error = draws.error || predictions.error || bingo.error;
  if (error) return <Status error={error} />;
  if (
    draws.loading ||
    predictions.loading ||
    bingo.loading ||
    !suggestions.length
  )
    return null;
  return (
    <div className="stack">
      {suggestions.map((s) => (
        <article className="publication" key={s.id}>
          <strong>
            {s.items[0].tirage} · {s.items[0].periode}
          </strong>
          <span> · {dateLabel(s.date, true)}</span>
          {s.items.map((item) => (
            <div className="result-line" key={`${item.valeur}:${item.boul}`}>
              <span>{item.valeur}</span> <strong>{item.boul}</strong>
            </div>
          ))}
          <button
            type="button"
            onClick={() => onChoose({ id: s.id, dataStack: s.items })}
          >
            Vérifier
          </button>
        </article>
      ))}
    </div>
  );
}
