import { useState } from "react";
import { useLocation } from "react-router-dom";
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  serverTimestamp,
  updateDoc,
} from "firebase/firestore";
import {
  History,
  Plus,
  Trash2,
  Pencil,
  Minus,
  Star,
  Heart,
  Trophy,
  Clover,
  Hash,
} from "lucide-react";
import { auth, db } from "../services/firebase";
import { dateLabel, asDate, useCollection, type Row } from "../services/data";
import { predictionGroups, predictionPeriods } from "../services/publications";
import {
  Form,
  Panel,
  Submit,
  useAction,
  Status,
  Modal,
} from "../components/ui";
import Comments from "./comments";
import BingoActivity from "./BingoActivity";
import BingoSuggestions from "./BingoSuggestions";
import BingoForm from "./BingoForm";
import type { BingoItem } from "../services/bingoSuggestions";
import "./bingo.css";
export default function Publications() {
  const path = useLocation().pathname;
  const kind = path.startsWith("/croix")
    ? "croix"
    : path.startsWith("/predictions")
      ? "prediction"
      : "bingo";
  const [history, setHistory] = useState(path.endsWith("/history"));
  const [suggestion, setSuggestion] = useState<Row | null>(null);
  return (
    <div className={`publication-page ${kind}-page`}>
      {kind === "prediction" && (
        <div className="tabs publication-tabs">
          <button
            className={!history ? "active" : ""}
            onClick={() => setHistory(false)}
          >
            {kind === "prediction"
              ? "Prédictions"
              : kind === "croix"
                ? "Croix de la chance"
                : "BINGO"}
          </button>
          <button
            className={history ? "active" : ""}
            onClick={() => setHistory(true)}
          >
            Historique
          </button>
        </div>
      )}
      {kind === "bingo" ? (
        <>
          <nav className="bingo-navigation" aria-label="Publications BINGO">
            <button
              type="button"
              aria-pressed={!history}
              onClick={() => setHistory(false)}
            >
              <Plus size={18} /> Nouvelle publication
            </button>
            <button
              type="button"
              aria-pressed={history}
              onClick={() => setHistory(true)}
            >
              <History size={18} /> Historique
            </button>
          </nav>
          <div hidden={history}>
            <BingoSuggestions onChoose={setSuggestion} />
            <BingoForm />
          </div>
          {history && <PublicationHistory kind={kind} />}
          {suggestion && (
            <Modal
              title="Vérifier le BINGO"
              onClose={() => setSuggestion(null)}
            >
              <BingoForm
                key={suggestion.id}
                initial={suggestion}
                done={() => setSuggestion(null)}
              />
            </Modal>
          )}
        </>
      ) : history ? (
        <PublicationHistory kind={kind} />
      ) : kind === "croix" ? (
        <CroixForm />
      ) : (
        <PredictionForm />
      )}
      {kind === "croix" && (
        <button
          className="bingo-history-shortcut"
          onClick={() => setHistory(!history)}
        >
          <History size={18} />
          {history ? "Nouvelle publication" : "Historique des publications"}
        </button>
      )}
    </div>
  );
}
function CroixForm({ row, done }: { row?: Row; done?: () => void }) {
  const [values, setValues] = useState<string[]>(
    row?.numeros || Array(9).fill(""),
  );
  const action = useAction();
  const [confirming, setConfirming] = useState(false);
  const publish = () => {
    void action.run(async () => {
      if (values.some((v, i) => i !== 4 && !/^\d{1,2}$/.test(v)))
        throw new Error("Renseignez les huit numéros.");
      const payload = {
        numeros: values.map((v, i) => (i === 4 ? "0" : v)),
        created_by: auth.currentUser!.uid,
      };
      if (row) await updateDoc(doc(db, "croix", row.id), payload);
      else
        await addDoc(collection(db, "croix"), {
          ...payload,
          date: serverTimestamp(),
        });
      if (done) done();
      else setValues(Array(9).fill(""));
    }, "Croix publiée");
  };
  return (
    <Panel title="Croix de la chance">
      <Form onSubmit={() => setConfirming(true)}>
        <div className="cross-grid">
          {values.map((v, i) =>
            i === 4 ? (
              <span key={i} className="cross-center">
                0
              </span>
            ) : (
              <input
                key={i}
                placeholder={
                  ["11", "12", "13", "21", "", "22", "31", "32", "33"][i]
                }
                aria-label={`Numéro ${i < 4 ? i + 1 : i}`}
                value={v}
                required
                inputMode="numeric"
                pattern="[0-9]{1,2}"
                maxLength={2}
                onChange={(e) =>
                  setValues(
                    values.map((x, j) => (i === j ? e.target.value : x)),
                  )
                }
              />
            ),
          )}
        </div>
        {action.feedback}
        <Submit busy={action.busy}>
          {row ? "Enregistrer" : "Publier la mise à jour"}
        </Submit>
      </Form>
      {confirming && (
        <Modal
          title="Vérifier la publication"
          onClose={() => setConfirming(false)}
        >
          <div className="cross-grid small">
            {values.map((v, i) => (
              <span key={i}>{i === 4 ? "0" : v}</span>
            ))}
          </div>
          {action.feedback}
          <div className="form-actions">
            <button onClick={() => setConfirming(false)}>Annuler</button>
            <button
              className="primary"
              disabled={action.busy}
              onClick={() => {
                publish();
                setConfirming(false);
              }}
            >
              Publier
            </button>
          </div>
        </Modal>
      )}
    </Panel>
  );
}
function PredictionForm({ row, done }: { row?: Row; done?: () => void }) {
  const [values, setValues] = useState<Record<string, string[]>>(() =>
    Object.fromEntries(
      predictionGroups.map(([key]) => [
        key,
        row?.[key]?.boul || ["", "", "", ""],
      ]),
    ),
  );
  const [period, setPeriod] = useState<string>(
      row
        ? predictionPeriods.includes(row.periode)
          ? row.periode
          : ""
        : predictionPeriods[0],
    ),
    [percent, setPercent] = useState(row?.pourcentage ?? 80);
  const action = useAction();
  return (
    <Panel title="Prédictions">
      <Form
        onSubmit={() => {
          if (!period) return;
          void action.run(async () => {
            const payload = {
              periode: period,
              pourcentage: Number(percent),
              created_by: auth.currentUser!.uid,
              ...Object.fromEntries(
                predictionGroups.map(([key, name]) => [
                  key,
                  { name, boul: values[key] },
                ]),
              ),
            };
            if (row) await updateDoc(doc(db, "prediction", row.id), payload);
            else
              await addDoc(collection(db, "prediction"), {
                ...payload,
                date: serverTimestamp(),
              });
            done?.();
          }, "Prédictions publiées");
        }}
      >
        <div className="prediction-controls">
          <div className="period-selector">
            {predictionPeriods.map((p) => (
              <button
                type="button"
                aria-pressed={period === p}
                key={p}
                onClick={() => setPeriod(p)}
              >
                {p}
              </button>
            ))}
          </div>
          <div className="percentage-control">
            <span>Pourcentage</span>
            <button
              type="button"
              aria-label="Diminuer le pourcentage"
              disabled={percent <= 0}
              onClick={() => setPercent(Math.max(0, percent - 5))}
            >
              <Minus size={17} />
            </button>
            <strong>{percent} %</strong>
            <button
              type="button"
              aria-label="Augmenter le pourcentage"
              disabled={percent >= 100}
              onClick={() => setPercent(Math.min(100, percent + 5))}
            >
              <Plus size={17} />
            </button>
          </div>
        </div>
        <div className="prediction-grid">
          {[...predictionGroups]
            .sort(
              (a, b) =>
                [
                  "favori",
                  "soutni",
                  "boloto",
                  "mariage",
                  "chif3",
                  "chif4",
                  "extra",
                ].indexOf(a[0]) -
                [
                  "favori",
                  "soutni",
                  "boloto",
                  "mariage",
                  "chif3",
                  "chif4",
                  "extra",
                ].indexOf(b[0]),
            )
            .map(([key, name]) => (
              <fieldset key={key}>
                <legend>
                  <Star size={18} />
                  {
                    (
                      {
                        favori: "Boul favoris",
                        soutni: "Soutni",
                        boloto: "Boloto",
                        mariage: "Mariages",
                        chif3: "3 chiffres",
                        chif4: "4 chiffres",
                        extra: "Extra",
                      } as Record<string, string>
                    )[key]
                  }
                </legend>
                <div className="numbers-input">
                  {values[key].map((v, i) => (
                    <input
                      key={i}
                      placeholder={`N°${i + 1}`}
                      aria-label={`${name} ${i + 1}`}
                      inputMode="numeric"
                      maxLength={10}
                      value={v}
                      onChange={(e) =>
                        setValues({
                          ...values,
                          [key]: values[key].map((x, j) =>
                            j === i ? e.target.value : x,
                          ),
                        })
                      }
                    />
                  ))}
                </div>
              </fieldset>
            ))}
        </div>
        {action.feedback}
        <div className="publication-submit">
          <Submit busy={action.busy} disabled={!period}>
            {row ? "Enregistrer" : "Publier"}
          </Submit>
        </div>
      </Form>
    </Panel>
  );
}
export function PublicationHistory({ kind }: { kind: string }) {
  const [count, setCount] = useState(50),
    [edit, setEdit] = useState<Row | null>(null),
    [comments, setComments] = useState<Row | null>(null);
  const state = useCollection(kind, "date", count),
    action = useAction();
  return (
    <Panel title="Historique des publications">
      <Status {...state} empty={!state.rows.length} />
      {action.feedback}
      <div className="stack">
        {state.rows.map((row) => (
          <article
            className={`publication history-card ${kind}-history-card`}
            key={row.id}
          >
            <div className="panel-heading">
              <strong>
                {dateLabel(row.date, true)} {row.periode}
              </strong>
              <div className="actions">
                <button aria-label="Modifier" onClick={() => setEdit(row)}>
                  <Pencil size={16} />
                </button>
                <button
                  aria-label="Supprimer"
                  disabled={action.busy}
                  onClick={() => {
                    if (confirm("Supprimer cette publication ?"))
                      void action.run(
                        () => deleteDoc(doc(db, kind, row.id)),
                        "Publication supprimée",
                      );
                  }}
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </div>
            {kind === "prediction" && (
              <div className="history-status">
                <span className="badge">{row.periode}</span>
                <span className="badge green">{row.pourcentage} %</span>
              </div>
            )}
            {kind === "bingo" && (
              <div className="history-status">
                <Trophy size={18} />
                <span
                  className={`badge ${(asDate(row.expiration)?.getTime() || 0) > Date.now() ? "green" : ""}`}
                >
                  {(asDate(row.expiration)?.getTime() || 0) > Date.now()
                    ? "Actif"
                    : "Expiré"}
                </span>
                <small>{row.dataStack?.length || 0} résultat(s)</small>
              </div>
            )}
            {kind === "croix" ? (
              <div className="cross-grid small">
                {row.numeros?.map((v: string, i: number) => (
                  <span key={i}>{v}</span>
                ))}
              </div>
            ) : kind === "prediction" ? (
              <div className="prediction-grid">
                {[...predictionGroups]
                  .sort(
                    (a, b) =>
                      [
                        "favori",
                        "soutni",
                        "boloto",
                        "mariage",
                        "chif3",
                        "chif4",
                        "extra",
                      ].indexOf(a[0]) -
                      [
                        "favori",
                        "soutni",
                        "boloto",
                        "mariage",
                        "chif3",
                        "chif4",
                        "extra",
                      ].indexOf(b[0]),
                  )
                  .map(([key, name]) => (
                    <div key={key}>
                      <small>{name}</small>
                      <div className="balls">
                        {row[key]?.boul?.map((v: string, i: number) => (
                          <span key={i}>{v}</span>
                        ))}
                      </div>
                    </div>
                  ))}
              </div>
            ) : (
              <>
                {row.dataStack?.map((r: BingoItem, i: number) => (
                  <div className="result-line" key={i}>
                    <span>
                      {r.tirage} · {r.periode}
                    </span>
                    <strong>{r.boul}</strong>
                    <span>{r.valeur}</span>
                  </div>
                ))}
                <BingoActivity id={row.id} />
              </>
            )}
          </article>
        ))}
      </div>
      {state.rows.length === count && (
        <button onClick={() => setCount(count + 50)}>Charger plus</button>
      )}
      {edit && (
        <Modal title="Modifier la publication" onClose={() => setEdit(null)}>
          {kind === "croix" ? (
            <CroixForm row={edit} done={() => setEdit(null)} />
          ) : kind === "prediction" ? (
            <PredictionForm row={edit} done={() => setEdit(null)} />
          ) : (
            <BingoForm row={edit} done={() => setEdit(null)} />
          )}
        </Modal>
      )}
      {comments && (
        <Modal title="Commentaires" onClose={() => setComments(null)}>
          <Comments bingoId={comments.id} />
        </Modal>
      )}
    </Panel>
  );
}
