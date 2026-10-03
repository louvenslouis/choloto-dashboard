import { useState } from "react";
import { deleteDoc, doc } from "firebase/firestore";
import { RefreshCw, Trash2 } from "lucide-react";
import { db } from "../services/firebase";
import { dateLabel, useCollection } from "../services/data";
import {
  lotteries,
  periods,
  publishOfficial,
  publishResult,
} from "../services/publications";
import { useOfficial } from "../services/OfficialProvider";
import {
  Field,
  Form,
  Panel,
  Status,
  Submit,
  useAction,
} from "../components/ui";
export default function Draws() {
  const [count, setCount] = useState(100);
  const state = useCollection("resultats", "date", count),
    action = useAction();
  const {
    proposals,
    warnings,
    loading,
    published,
    automatic,
    setAutomatic,
    refresh,
  } = useOfficial();
  return (
    <>
      {action.feedback}

      <Panel
        title="Résultats officiels"
        action={
          <button disabled={loading} onClick={() => void refresh()}>
            <RefreshCw size={17} className={loading ? "spin" : ""} />
            Actualiser
          </button>
        }
      >
        <label className="check">
          <input
            type="checkbox"
            checked={automatic}
            onChange={(e) => setAutomatic(e.target.checked)}
          />
          Publication automatique
        </label>
        <Status loading={loading} empty={!loading && !proposals.length} />
        {warnings.map((w) => (
          <p key={w} className="error">
            {w}
          </p>
        ))}
        <div className="cards-grid">
          {proposals.map((p) => (
            <article className="draw-card" key={p.id}>
              <div className="panel-heading">
                <h3>{lotteries[p.code]}</h3>
                <span className="badge">{p.period}</span>
              </div>
              <small>
                {dateLabel(p.date)} · {p.source}
              </small>
              <div className="balls">
                {p.numbers.map((n, i) => (
                  <span key={i}>{n}</span>
                ))}
              </div>
              <button
                className="primary"
                disabled={
                  action.busy ||
                  published.has(p.id) ||
                  state.rows.some((r) => r.id === p.id)
                }
                onClick={() =>
                  void action.run(() => publishOfficial(p), "Tirage publié")
                }
              >
                {published.has(p.id) || state.rows.some((r) => r.id === p.id)
                  ? "Publié"
                  : "Publier"}
              </button>
            </article>
          ))}
        </div>
      </Panel>
      <h2 className="manual-heading">Saisie manuelle</h2>
      <div className="manual-results-grid">
        {Object.entries(lotteries).map(([code, name]) => (
          <ManualResult key={code} code={code} name={name} />
        ))}
      </div>
      <details className="draw-history">
        <summary>Historique des tirages</summary>

        <Panel title="Historique des tirages">
          <Status {...state} empty={!state.rows.length} />
          <div className="table-scroll">
            <table>
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Tirage</th>
                  <th>Période</th>
                  <th>Numéros</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {state.rows.map((r) => (
                  <tr key={r.id}>
                    <td>{dateLabel(r.date, true)}</td>
                    <td>{lotteries[r.tirage] || r.tirage}</td>
                    <td>{r.periode}</td>
                    <td>
                      <div className="balls">
                        {r.numeros?.map((n: string, i: number) => (
                          <span key={i}>{n}</span>
                        ))}
                      </div>
                    </td>
                    <td>
                      <button
                        disabled={action.busy}
                        aria-label="Supprimer le tirage"
                        onClick={() => {
                          if (confirm("Supprimer ce tirage ?"))
                            void action.run(() =>
                              deleteDoc(doc(db, "resultats", r.id)),
                            );
                        }}
                      >
                        <Trash2 size={16} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {state.rows.length === count && (
            <button onClick={() => setCount(count + 100)}>Charger plus</button>
          )}
        </Panel>
      </details>
    </>
  );
}

function ManualResult({ code, name }: { code: string; name: string }) {
  const [period, setPeriod] = useState(periods[code][0]);
  const [numbers, setNumbers] = useState(
    code === "fl" ? ["", "", "", ""] : ["", "", ""],
  );
  const action = useAction();
  return (
    <Panel title={name}>
      <Form
        onSubmit={() =>
          void action.run(async () => {
            await publishResult(code, period, numbers);
            setNumbers(numbers.map(() => ""));
          }, "Tirage publié")
        }
      >
        <div className="form-grid">
          <Field label="Période">
            <select value={period} onChange={(e) => setPeriod(e.target.value)}>
              {periods[code].map((p) => (
                <option key={p}>{p}</option>
              ))}
            </select>
          </Field>
        </div>
        <div className="form-grid">
          {numbers.map((n, i) => {
            const labels =
                code === "fl"
                  ? ["PK2", "PK3", "PK4 · 1–2", "PK4 · 3–4"]
                  : ["3CF", "2LO", "3LO"],
              widths = code === "fl" ? [2, 3, 2, 2] : [3, 2, 2];
            return (
              <Field key={i} label={labels[i]}>
                <input
                  required
                  inputMode="numeric"
                  pattern={`[0-9]{${widths[i]}}`}
                  maxLength={widths[i]}
                  value={n}
                  onChange={(e) =>
                    setNumbers(
                      numbers.map((x, j) => (i === j ? e.target.value : x)),
                    )
                  }
                />
              </Field>
            );
          })}
        </div>
        {action.feedback}
        <Submit busy={action.busy}>Publier</Submit>
      </Form>
    </Panel>
  );
}
