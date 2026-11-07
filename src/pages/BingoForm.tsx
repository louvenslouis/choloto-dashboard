import { useEffect, useRef, useState } from "react";
import {
  addDoc,
  collection,
  doc,
  runTransaction,
  Timestamp,
  updateDoc,
} from "firebase/firestore";
import {
  Layers3,
  Moon,
  Plus,
  Send,
  Sun,
  Sunrise,
  Trash2,
  Trophy,
} from "lucide-react";
import { Field, Submit, useAction } from "../components/ui";
import { db } from "../services/firebase";
import type { Row } from "../services/data";
import type { BingoItem } from "../services/bingoSuggestions";

const lotteries = [
  "NEW YORK",
  "GEORGIA",
  "FLORIDA",
  "NEW JERSEY",
  "TEXAS",
  "TENNESSEE",
  "MARYLAND",
  "PENNSYLVANIA",
];
const prizes = [
  "1er lot",
  "2e lot",
  "3e lot",
  "2 lots",
  "LOTO 3",
  "LOTO 4",
  "2 Kabès",
  "MARIAGE",
  "BOLOTO",
];
const periods = [
  { label: "Matin", icon: Sunrise },
  { label: "Midi", icon: Sun },
  { label: "Soir", icon: Moon },
];
const emptyBingo = (): BingoItem => ({
  valeur: "1er lot",
  tirage: "NEW YORK",
  boul: "",
  periode: "Midi",
});
type DraftResult = { key: number; value: BingoItem };

export default function BingoForm({
  row,
  initial,
  done,
}: {
  row?: Row;
  initial?: Row;
  done?: () => void;
}) {
  const [items, setItems] = useState<DraftResult[]>(() =>
    (row?.dataStack || initial?.dataStack || [emptyBingo()]).map(
      (value: BingoItem, key: number) => ({ key, value }),
    ),
  );
  const nextKey = useRef(items.length);
  const focusKey = useRef<number | null>(null);
  const inputs = useRef(new Map<number, HTMLInputElement>());
  const action = useAction();

  useEffect(() => {
    if (focusKey.current !== null) {
      inputs.current.get(focusKey.current)?.focus();
      focusKey.current = null;
    }
  }, [items]);

  const edit = (key: number, field: keyof BingoItem, value: string) =>
    setItems((current) =>
      current.map((item) =>
        item.key === key
          ? { ...item, value: { ...item.value, [field]: value } }
          : item,
      ),
    );

  const publish = () => {
    void action.run(
      async () => {
        const dataStack = items.map(({ value }) => ({
          ...value,
          boul: value.boul.trim(),
        }));
        if (
          !dataStack.length ||
          dataStack.length > 32 ||
          dataStack.some((item) => !item.boul)
        )
          throw new Error("Renseignez le numéro de chaque résultat.");
        const payload = { dataStack };
        if (row) await updateDoc(doc(db, "bingo", row.id), payload);
        else {
          const now = new Date();
          const publication = {
            ...payload,
            date: Timestamp.fromDate(now),
            expiration: Timestamp.fromMillis(now.getTime() + 86400000),
          };
          if (initial) {
            const ref = doc(db, "bingo", `suggested_${initial.id}`);
            await runTransaction(db, async (transaction) => {
              if ((await transaction.get(ref)).exists())
                throw new Error("Ce BINGO a déjà été publié.");
              transaction.set(ref, publication);
            });
          } else await addDoc(collection(db, "bingo"), publication);
          setItems([{ key: nextKey.current++, value: emptyBingo() }]);
        }
        done?.();
      },
      row ? "BINGO enregistré" : "BINGO publié",
    );
  };

  return (
    <section className="bingo-composer" aria-label="Publication BINGO">
      <form
        onSubmit={(event) => {
          event.preventDefault();
          publish();
        }}
      >
        <section className="bingo-editor">
          <div className="bingo-editor-heading">
            <span className="bingo-heading-icon">
              <Trophy size={21} />
            </span>
            <h2>Publication BINGO</h2>
            <span className="bingo-count">
              {items.length}
              <span> / 32</span>
            </span>
          </div>
          <div className="bingo-results">
            {items.map(({ key, value: item }, index) => (
              <fieldset
                className="bingo-result"
                key={key}
                disabled={action.busy}
                aria-label={`Résultat ${index + 1}`}
              >
                <div className="bingo-result-heading">
                  <h3>
                    <span>{String(index + 1).padStart(2, "0")}</span> Résultat{" "}
                    {index + 1}
                  </h3>
                  <button
                    type="button"
                    className="bingo-remove"
                    disabled={items.length === 1}
                    aria-label={`Retirer le résultat ${index + 1}`}
                    title="Retirer le résultat"
                    onClick={() => {
                      focusKey.current =
                        items[index + 1]?.key ??
                        items[index - 1]?.key ??
                        null;
                      setItems((current) =>
                        current.filter((item) => item.key !== key),
                      );
                    }}
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
                <div className="bingo-result-fields">
                  <label className="bingo-number-field">
                    <span>Numéro</span>
                    <input
                      ref={(element) => {
                        if (element) inputs.current.set(key, element);
                        else inputs.current.delete(key);
                      }}
                      required
                      inputMode="numeric"
                      maxLength={30}
                      placeholder="00"
                      autoComplete="off"
                      value={item.boul}
                      onChange={(event) =>
                        edit(key, "boul", event.target.value)
                      }
                    />
                  </label>
                  <div className="bingo-result-selects">
                    <Field label="Tirage">
                      <select
                        aria-label="Tirage"
                        value={item.tirage}
                        onChange={(event) =>
                          edit(key, "tirage", event.target.value)
                        }
                      >
                        {lotteries.map((lottery) => (
                          <option key={lottery}>{lottery}</option>
                        ))}
                      </select>
                    </Field>
                    <Field label="Lot">
                      <select
                        aria-label="Lot"
                        value={item.valeur}
                        onChange={(event) =>
                          edit(key, "valeur", event.target.value)
                        }
                      >
                        {prizes.map((prize) => (
                          <option key={prize}>{prize}</option>
                        ))}
                      </select>
                    </Field>
                  </div>
                </div>
                <div className="bingo-period-row">
                  <span>Période</span>
                  <div
                    className="bingo-periods"
                    role="group"
                    aria-label={`Période du résultat ${index + 1}`}
                  >
                    {periods.map(({ label, icon: Icon }) => (
                      <button
                        key={label}
                        type="button"
                        aria-pressed={item.periode === label}
                        onClick={() => edit(key, "periode", label)}
                      >
                        <Icon size={16} />
                        {label}
                      </button>
                    ))}
                  </div>
                </div>
              </fieldset>
            ))}
            <button
              type="button"
              className="bingo-add"
              disabled={items.length >= 32 || action.busy}
              onClick={() => {
                const key = nextKey.current++;
                const last = items.at(-1)?.value;
                focusKey.current = key;
                setItems((current) => [
                  ...current,
                  {
                    key,
                    value: {
                      ...emptyBingo(),
                      tirage: last?.tirage || "NEW YORK",
                      periode: last?.periode || "Midi",
                    },
                  },
                ]);
              }}
            >
              <Plus size={18} /> Ajouter un résultat
            </button>
          </div>
        </section>
        <div className="bingo-feedback">{action.feedback}</div>
        <div className="bingo-publish-bar">
          <span>
            <Layers3 size={18} />
            <strong>{items.length}</strong> résultat
            {items.length > 1 ? "s" : ""}
          </span>
          <Submit busy={action.busy}>
            <Send size={17} />
            {row ? "Enregistrer" : "Publier le BINGO"}
          </Submit>
        </div>
      </form>
    </section>
  );
}
