import { useEffect, useState } from "react";
import { doc, runTransaction } from "firebase/firestore";
import {
  ArrowUp,
  ArrowDown,
  RefreshCw,
  CheckCircle2,
  Bot,
  Plus,
  Pencil,
  Trash2,
  ChevronRight,
  ArrowLeft,
  Smartphone,
  GitBranch,
  Wallet,
  Crown,
} from "lucide-react";
import { db } from "../services/firebase";
import { useDocument } from "../services/data";
import {
  initialBot,
  validateBot,
  type BotConfig,
  type BotNode,
  type Plan,
  type Method,
} from "../services/bot";
import {
  Field,
  Form,
  Status,
  Submit,
  Modal,
  useAction,
} from "../components/ui";
export default function BotEditor({
  onDirtyChange,
}: {
  onDirtyChange?: (dirty: boolean) => void;
}) {
  const state = useDocument("support_bot/config");
  if (state.loading || state.error)
    return <Status loading={state.loading} error={state.error} />;
  return (
    <Editor
      onDirtyChange={onDirtyChange}
      initial={
        state.data
          ? {
              enabled: state.data.enabled,
              greeting: state.data.greeting,
              revision: state.data.revision,
              nodes: state.data.nodes,
              plans: state.data.plans || [],
              paymentMethods: state.data.paymentMethods || [],
            }
          : initialBot
      }
    />
  );
}
function Editor({
  initial,
  onDirtyChange,
}: {
  initial: BotConfig;
  onDirtyChange?: (dirty: boolean) => void;
}) {
  const [config, setConfig] = useState(initial),
    [edit, setEdit] = useState<{
      kind: "nodes" | "plans" | "paymentMethods";
      value: BotNode | Plan | Method;
    } | null>(null),
    [preview, setPreview] = useState<string[]>([]),
    [saved, setSaved] = useState(JSON.stringify(initial));
  const action = useAction(),
    dirty = JSON.stringify(config) !== saved;
  useEffect(() => {
    onDirtyChange?.(dirty);
    const warn = (event: BeforeUnloadEvent) => {
      if (dirty) {
        event.preventDefault();
        event.returnValue = "";
      }
    };
    window.addEventListener("beforeunload", warn);
    return () => window.removeEventListener("beforeunload", warn);
  }, [dirty, onDirtyChange]);
  const change = (key: keyof BotConfig, value: unknown) =>
    setConfig({ ...config, [key]: value });
  const removeBranch = (id: string) => {
    const ids = new Set([id]);
    let size = 0;
    while (size !== ids.size) {
      size = ids.size;
      config.nodes.forEach((n) => {
        if (ids.has(n.parent)) ids.add(n.id);
      });
    }
    if (confirm("Supprimer cette branche et ses choix ?"))
      change(
        "nodes",
        config.nodes.filter((n) => !ids.has(n.id)),
      );
  };
  const addNode = (parent = "") =>
    setEdit({
      kind: "nodes",
      value: {
        ...initialBot.nodes[0],
        id: crypto.randomUUID(),
        parent,
        label: "",
        answer: "",
      },
    });
  const move = (node: BotNode, direction: number) => {
    const siblings = config.nodes.filter((n) => n.parent === node.parent),
      i = siblings.findIndex((n) => n.id === node.id),
      other = siblings[i + direction];
    if (!other) return;
    const next = [...config.nodes],
      first = next.indexOf(node),
      second = next.indexOf(other);
    [next[first], next[second]] = [next[second], next[first]];
    change("nodes", next);
  };
  const branch = (parent: string, depth = 0): React.ReactNode =>
    depth > 5
      ? null
      : config.nodes
          .filter((n) => n.parent === parent)
          .map((n, i, siblings) => (
            <details className="bot-branch" key={n.id} open={depth === 0}>
              <summary>
                <span className="bot-node-number">
                  {String(i + 1).padStart(2, "0")}
                </span>
                <strong>{n.label}</strong>
                <ChevronRight size={17} />
              </summary>
              <div className="bot-branch-answer">{n.answer}</div>
              <div className="bot-branch-actions">
                <button
                  aria-label={`Modifier ${n.label}`}
                  onClick={() => setEdit({ kind: "nodes", value: n })}
                >
                  <Pencil size={17} />
                </button>
                <button
                  aria-label={`Ajouter sous ${n.label}`}
                  onClick={() => addNode(n.id)}
                >
                  <Plus size={18} />
                </button>
                <button
                  aria-label={`Monter ${n.label}`}
                  disabled={i === 0}
                  onClick={() => move(n, -1)}
                >
                  <ArrowUp size={17} />
                </button>
                <button
                  aria-label={`Descendre ${n.label}`}
                  disabled={i === siblings.length - 1}
                  onClick={() => move(n, 1)}
                >
                  <ArrowDown size={17} />
                </button>
                <button
                  aria-label={`Supprimer ${n.label}`}
                  onClick={() => removeBranch(n.id)}
                >
                  <Trash2 size={17} />
                </button>
              </div>
              <div className="bot-children">{branch(n.id, depth + 1)}</div>
            </details>
          ));
  const current = config.nodes.find((n) => n.id === preview.at(-1));
  return (
    <div className="bot-builder">
      <div className="bot-builder-top">
        <span>
          <Bot size={20} />
          Bot du service client
        </span>
        <button
          className="primary"
          disabled={action.busy}
          onClick={() =>
            void action.run(async () => {
              const valid = validateBot(config);
              await runTransaction(db, async (tx) => {
                const ref = doc(db, "support_bot", "config"),
                  snapshot = await tx.get(ref),
                  revision = snapshot.data()?.revision || 0;
                if (revision !== config.revision)
                  throw new Error(
                    "Le bot a été modifié ailleurs. Fermez puis rouvrez l’éditeur.",
                  );
                tx.set(ref, { ...valid, revision: revision + 1 });
              });
              const next = { ...valid, revision: valid.revision + 1 };
              setConfig(next);
              setSaved(JSON.stringify(next));
            }, "Bot publié")
          }
        >
          {action.busy ? "Publication…" : "Publier"}
        </button>
      </div>
      {action.feedback}
      <div className="bot-overview">
        <div>
          <Bot size={28} />
          <div>
            <h2>Un bot à votre image</h2>
            <div className="bot-hero-pills">
              <span>{config.nodes.length} choix</span>
              <span>{dirty ? "Modifications non publiées" : "Enregistré"}</span>
            </div>
          </div>
        </div>
      </div>
      <div className="bot-layout">
        <div className="bot-workbench">
          <section className="bot-surface">
            <div className="bot-greeting-heading">
              <h3>Message d’accueil</h3>{" "}
              <label className="check">
                <input
                  type="checkbox"
                  checked={config.enabled}
                  onChange={(e) => change("enabled", e.target.checked)}
                />
                Bot actif
              </label>
            </div>
            <textarea
              aria-label="Message d’accueil"
              maxLength={1000}
              value={config.greeting}
              onChange={(e) => change("greeting", e.target.value)}
            />
          </section>
          <h3 className="bot-section-title">
            <GitBranch size={19} />
            Le parcours
          </h3>
          {branch("")}
          <button
            className="bot-add"
            disabled={config.nodes.length >= 80}
            onClick={() => addNode()}
          >
            <Plus size={18} />
            Ajouter un choix
          </button>
          <details className="bot-surface bot-plans">
            <summary>
              <Crown size={19} />
              Plans
            </summary>
            {config.plans.map((p) => (
              <button
                className="bot-list-row"
                key={p.id}
                onClick={() => setEdit({ kind: "plans", value: p })}
              >
                <span>
                  <strong>{p.name}</strong>
                  <small>
                    {p.enabled
                      ? `${p.months} mois · ${p.amountHtgMinor / 100} HTG · ${p.amountUsdMinor / 100} USD`
                      : "Inactif"}
                  </small>
                </span>
                <ChevronRight size={18} />
              </button>
            ))}
            <button
              onClick={() =>
                setEdit({
                  kind: "plans",
                  value: {
                    id: crypto.randomUUID(),
                    name: "",
                    months: 1,
                    amountHtgMinor: 0,
                    amountUsdMinor: 0,
                    enabled: true,
                  },
                })
              }
            >
              <Plus size={16} />
              Ajouter un plan
            </button>
          </details>
          <details className="bot-surface bot-payments">
            <summary>
              <Wallet size={19} />
              Informations de paiement
            </summary>
            {config.paymentMethods.map((m) => (
              <button
                className="bot-list-row"
                key={m.id}
                onClick={() => setEdit({ kind: "paymentMethods", value: m })}
              >
                <span>
                  <strong>{m.name}</strong>
                  <small>{m.enabled ? m.currency : "Inactif"}</small>
                </span>
                <ChevronRight size={18} />
              </button>
            ))}
            <button
              onClick={() =>
                setEdit({
                  kind: "paymentMethods",
                  value: {
                    id: crypto.randomUUID(),
                    name: "",
                    currency: "HTG",
                    months: 1,
                    amountMinor: 0,
                    account: "",
                    recipient: "",
                    enabled: false,
                  },
                })
              }
            >
              <Plus size={16} />
              Ajouter un moyen de paiement
            </button>
          </details>
        </div>
        <div className="bot-preview">
          <h3>
            <Smartphone size={18} />
            Aperçu des réponses
            <button
              aria-label="Recommencer l’aperçu"
              onClick={() => setPreview([])}
            >
              <RefreshCw size={17} />
            </button>
          </h3>
          <div className="bot-phone">
            <div className="bot-phone-header">
              <Bot size={22} />
              <strong>CHOLOTO</strong>
              <small>{config.enabled ? "● Actif" : "En pause"}</small>
            </div>
            <div className="bot-phone-content">
              <div className="bot-answer">
                {current?.answer || config.greeting}
              </div>
              {config.nodes
                .filter((n) => n.parent === (current?.id || ""))
                .map((n) => (
                  <button
                    key={n.id}
                    onClick={() => setPreview([...preview, n.id])}
                  >
                    {n.label}
                    <ChevronRight size={15} />
                  </button>
                ))}
              {current?.requestImage && (
                <span className="badge">Envoyer une image</span>
              )}
              {current?.requiresAuth && (
                <span className="badge">Connexion requise</span>
              )}
              {preview.length > 0 && (
                <button onClick={() => setPreview(preview.slice(0, -1))}>
                  <ArrowLeft size={14} />
                  Retour
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
      {edit && (
        <Modal
          title={
            edit.kind === "nodes"
              ? "Modifier le choix"
              : edit.kind === "plans"
                ? "Plan"
                : "Moyen de paiement"
          }
          onClose={() => setEdit(null)}
        >
          <BotItemEditor
            kind={edit.kind}
            value={edit.value}
            config={config}
            save={(value) => {
              const existing = config[edit.kind] as (BotNode | Plan | Method)[];
              change(
                edit.kind,
                existing.some((v) => v.id === value.id)
                  ? existing.map((v) => (v.id === value.id ? value : v))
                  : [...existing, value],
              );
              setEdit(null);
            }}
            remove={() => {
              if (edit.kind === "nodes") removeBranch(edit.value.id);
              else if (confirm("Supprimer cet élément ?"))
                change(
                  edit.kind,
                  config[edit.kind].filter((v) => v.id !== edit.value.id),
                );
              setEdit(null);
            }}
          />
        </Modal>
      )}
    </div>
  );
}
function BotItemEditor({
  kind,
  value,
  config,
  save,
  remove,
}: {
  kind: "nodes" | "plans" | "paymentMethods";
  value: BotNode | Plan | Method;
  config: BotConfig;
  save: (value: BotNode | Plan | Method) => void;
  remove: () => void;
}) {
  const [draft, setDraft] = useState<Record<string, any>>({ ...value });
  const change = (key: string, v: unknown) => setDraft({ ...draft, [key]: v });
  return (
    <Form onSubmit={() => save(draft as BotNode | Plan | Method)}>
      <Field label={kind === "nodes" ? "Titre" : "Nom"}>
        <input
          required
          maxLength={100}
          value={draft.label ?? draft.name}
          onChange={(e) =>
            change(kind === "nodes" ? "label" : "name", e.target.value)
          }
        />
      </Field>
      {kind === "nodes" ? (
        <>
          <Field label="Parent">
            <select
              value={draft.parent}
              onChange={(e) => change("parent", e.target.value)}
            >
              <option value="">Menu principal</option>
              {config.nodes
                .filter((n) => n.id !== draft.id)
                .map((n) => (
                  <option key={n.id} value={n.id}>
                    {n.label}
                  </option>
                ))}
            </select>
          </Field>
          <Field label="Réponse">
            <textarea
              required
              maxLength={1500}
              value={draft.answer}
              onChange={(e) => change("answer", e.target.value)}
            />
          </Field>
          {[
            ["requiresAuth", "Connexion requise"],
            ["requestImage", "Demander une image"],
            ["requestPaymentProof", "Demander une preuve de paiement"],
          ].map(([key, label]) => (
            <label className="check" key={key}>
              <input
                type="checkbox"
                checked={draft[key]}
                onChange={(e) => change(key, e.target.checked)}
              />
              {label}
            </label>
          ))}
          <Field label="Moyen de paiement">
            <select
              value={draft.paymentMethodId}
              onChange={(e) => change("paymentMethodId", e.target.value)}
            >
              <option value="">Aucun</option>
              {config.paymentMethods.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.name}
                </option>
              ))}
            </select>
          </Field>
        </>
      ) : (
        <>
          <label className="check">
            <input
              type="checkbox"
              checked={draft.enabled}
              onChange={(e) => change("enabled", e.target.checked)}
            />
            Actif
          </label>
          {kind === "paymentMethods" ? (
            <>
              {[
                ["account", "Compte"],
                ["recipient", "Bénéficiaire"],
              ].map(([key, label]) => (
                <Field key={key} label={label}>
                  <input
                    required
                    value={draft[key]}
                    onChange={(e) => change(key, e.target.value)}
                  />
                </Field>
              ))}
              <Field label="Devise">
                <select
                  value={draft.currency}
                  onChange={(e) => change("currency", e.target.value)}
                >
                  <option>HTG</option>
                  <option>USD</option>
                </select>
              </Field>
            </>
          ) : null}
          {(kind === "plans" || !config.plans.length) && (
            <>
              <Field label="Durée (mois)">
                <input
                  type="number"
                  required
                  min={1}
                  max={36}
                  value={draft.months}
                  onChange={(e) => change("months", Number(e.target.value))}
                />
              </Field>
              {(kind === "plans"
                ? [
                    ["amountHtgMinor", "Prix HTG"],
                    ["amountUsdMinor", "Prix USD"],
                  ]
                : [["amountMinor", `Prix ${draft.currency}`]]
              ).map(([key, label]) => (
                <Field key={key} label={label}>
                  <input
                    type="number"
                    min={0}
                    max={1000000}
                    required
                    step="0.01"
                    value={draft[key] / 100}
                    onChange={(e) =>
                      change(key, Math.round(Number(e.target.value) * 100))
                    }
                  />
                </Field>
              ))}
            </>
          )}
        </>
      )}
      <div className="form-actions">
        <button type="button" className="danger" onClick={remove}>
          Supprimer
        </button>
        <Submit busy={false} />
      </div>
    </Form>
  );
}
