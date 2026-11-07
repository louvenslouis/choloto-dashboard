import { useMemo, useState } from "react";
import { ArrowUpRight, Check, Sparkles } from "lucide-react";
import { useCollection, dateLabel, type Row } from "../services/data";
import { suggestBingo } from "../services/bingoSuggestions";
import { Status } from "../components/ui";
export default function BingoSuggestions({
  onChoose,
}: {
  onChoose: (row: Row) => void;
}) {
  const [enabled, setEnabled] = useState(false);
  return (
    <section
      className={`bingo-suggestions${enabled ? " is-enabled" : ""}`}
      aria-label="BINGO proposés"
    >
      <div className="bingo-suggestions-heading">
        <span className="bingo-suggestions-icon">
          <Sparkles size={19} />
        </span>
        <h2>BINGO proposés</h2>
        <button
          type="button"
          className="bingo-switch"
          role="switch"
          aria-checked={enabled}
          aria-label="Activer les BINGO proposés"
          onClick={() => setEnabled(!enabled)}
        >
          <span>{enabled && <Check size={12} />}</span>
        </button>
      </div>
      {enabled && <ActiveBingoSuggestions onChoose={onChoose} />}
    </section>
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
  if (draws.loading || predictions.loading || bingo.loading)
    return <Status loading />;
  if (!suggestions.length)
    return <p className="bingo-suggestions-empty">Aucun BINGO proposé</p>;
  return (
    <div className="bingo-suggestion-list">
      {suggestions.map((s) => (
        <article className="bingo-suggestion" key={s.id}>
          <div className="bingo-suggestion-info">
            <strong>
              {s.items[0].tirage} · {s.items[0].periode}
            </strong>
            <small>{dateLabel(s.date, true)}</small>
          </div>
          <div className="bingo-suggestion-numbers">
            {s.items.map((item) => (
              <div key={`${item.valeur}:${item.boul}`}>
                <strong>{item.boul}</strong>
                <small>{item.valeur}</small>
              </div>
            ))}
          </div>
          <button
            type="button"
            onClick={() => onChoose({ id: s.id, dataStack: s.items })}
          >
            Vérifier <ArrowUpRight size={16} />
          </button>
        </article>
      ))}
    </div>
  );
}
