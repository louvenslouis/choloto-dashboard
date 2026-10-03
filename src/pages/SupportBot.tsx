import { useState } from "react";
import { doc, runTransaction } from "firebase/firestore";
import { db } from "../services/firebase";
import { useDocument } from "../services/data";
import { initialBot, validateBot, type BotConfig } from "../services/bot";
import { Field, Form, Status, Submit, useAction } from "../components/ui";
export default function BotEditor() {
  const state = useDocument("support_bot/config");
  if (state.loading || state.error)
    return <Status loading={state.loading} error={state.error} />;
  const data = state.data;
  return (
    <Editor
      initial={
        data
          ? {
              enabled: data.enabled,
              greeting: data.greeting,
              revision: data.revision,
              nodes: data.nodes,
              plans: data.plans || [],
              paymentMethods: data.paymentMethods || [],
            }
          : initialBot
      }
    />
  );
}
function Editor({ initial }: { initial: BotConfig }) {
  const [config, setConfig] = useState(initial),
    [tab, setTab] = useState("nodes");
  const action = useAction();
  const change = (key: keyof BotConfig, value: unknown) =>
    setConfig({ ...config, [key]: value });
  return (
    <Form
      onSubmit={() =>
        void action.run(async () => {
          const valid = validateBot(config),
            ref = doc(db, "support_bot", "config");
          await runTransaction(db, async (tx) => {
            const snapshot = await tx.get(ref),
              revision = snapshot.data()?.revision || 0;
            if (revision !== config.revision)
              throw new Error(
                "Le bot a été modifié ailleurs. Fermez puis rouvrez l’éditeur.",
              );
            tx.set(ref, { ...valid, revision: revision + 1 });
          });
          setConfig({ ...valid, revision: valid.revision + 1 });
        }, "Bot publié")
      }
    >
      <label className="check">
        <input
          type="checkbox"
          checked={config.enabled}
          onChange={(e) => change("enabled", e.target.checked)}
        />
        Bot actif
      </label>
      <Field label="Message d’accueil">
        <textarea
          required
          maxLength={1000}
          value={config.greeting}
          onChange={(e) => change("greeting", e.target.value)}
        />
      </Field>
      <div className="tabs">
        {[
          ["nodes", "Rubriques"],
          ["plans", "Plans"],
          ["paymentMethods", "Moyens de paiement"],
        ].map(([key, title]) => (
          <button
            type="button"
            className={tab === key ? "active" : ""}
            key={key}
            onClick={() => setTab(key)}
          >
            {title}
          </button>
        ))}
      </div>
      {tab === "nodes" ? (
        <>
          {config.nodes.map((node, i) => (
            <fieldset key={node.id}>
              <legend>{node.label || "Nouvelle rubrique"}</legend>
              <div className="form-grid">
                <Field label="Titre">
                  <input
                    required
                    maxLength={100}
                    value={node.label}
                    onChange={(e) =>
                      change(
                        "nodes",
                        config.nodes.map((n, j) =>
                          j === i ? { ...n, label: e.target.value } : n,
                        ),
                      )
                    }
                  />
                </Field>
                <Field label="Parent">
                  <select
                    value={node.parent}
                    onChange={(e) =>
                      change(
                        "nodes",
                        config.nodes.map((n, j) =>
                          j === i ? { ...n, parent: e.target.value } : n,
                        ),
                      )
                    }
                  >
                    <option value="">Menu principal</option>
                    {config.nodes
                      .filter((n) => n.id !== node.id)
                      .map((n) => (
                        <option key={n.id} value={n.id}>
                          {n.label}
                        </option>
                      ))}
                  </select>
                </Field>
              </div>
              <Field label="Réponse">
                <textarea
                  required
                  maxLength={1500}
                  value={node.answer}
                  onChange={(e) =>
                    change(
                      "nodes",
                      config.nodes.map((n, j) =>
                        j === i ? { ...n, answer: e.target.value } : n,
                      ),
                    )
                  }
                />
              </Field>
              <div className="actions">
                {[
                  ["requiresAuth", "Connexion requise"],
                  ["requestImage", "Demander une image"],
                  ["requestPaymentProof", "Preuve de paiement"],
                ].map(([key, label]) => (
                  <label className="check" key={key}>
                    <input
                      type="checkbox"
                      checked={Boolean(node[key as keyof typeof node])}
                      onChange={(e) =>
                        change(
                          "nodes",
                          config.nodes.map((n, j) =>
                            j === i ? { ...n, [key]: e.target.checked } : n,
                          ),
                        )
                      }
                    />
                    {label}
                  </label>
                ))}
              </div>
              <Field label="Moyen de paiement">
                <select
                  value={node.paymentMethodId || ""}
                  onChange={(e) =>
                    change(
                      "nodes",
                      config.nodes.map((n, j) =>
                        j === i ? { ...n, paymentMethodId: e.target.value } : n,
                      ),
                    )
                  }
                >
                  <option value="">Aucun</option>
                  {config.paymentMethods.map((m) => (
                    <option key={m.id} value={m.id}>
                      {m.name}
                    </option>
                  ))}
                </select>
              </Field>
              <button
                type="button"
                onClick={() => {
                  if (config.nodes.some((n) => n.parent === node.id)) {
                    alert("Retirez d’abord les sous-rubriques.");
                    return;
                  }
                  change(
                    "nodes",
                    config.nodes.filter((_, j) => i !== j),
                  );
                }}
              >
                Supprimer
              </button>
            </fieldset>
          ))}
          <button
            type="button"
            onClick={() =>
              change("nodes", [
                ...config.nodes,
                {
                  ...initialBot.nodes[0],
                  id: crypto.randomUUID(),
                  label: "",
                  answer: "",
                },
              ])
            }
          >
            Ajouter une rubrique
          </button>
        </>
      ) : tab === "plans" ? (
        <>
          {config.plans.map((plan, i) => (
            <fieldset key={plan.id}>
              <legend>{plan.name || "Nouveau plan"}</legend>
              <div className="form-grid">
                {[
                  ["name", "Nom", "text"],
                  ["months", "Durée (mois)", "number"],
                  ["amountHtgMinor", "Prix HTG", "number"],
                  ["amountUsdMinor", "Prix USD", "number"],
                ].map(([key, label, type]) => (
                  <Field label={label} key={key}>
                    <input
                      required
                      type={type}
                      min={key === "months" ? 1 : 0}
                      step={key.startsWith("amount") ? "0.01" : "1"}
                      value={
                        key.startsWith("amount")
                          ? Number(plan[key as keyof typeof plan]) / 100
                          : String(plan[key as keyof typeof plan])
                      }
                      onChange={(e) =>
                        change(
                          "plans",
                          config.plans.map((p, j) =>
                            j === i
                              ? {
                                  ...p,
                                  [key]:
                                    type === "number"
                                      ? key.startsWith("amount")
                                        ? Math.round(
                                            Number(e.target.value) * 100,
                                          )
                                        : Number(e.target.value)
                                      : e.target.value,
                                }
                              : p,
                          ),
                        )
                      }
                    />
                  </Field>
                ))}
              </div>
              <label className="check">
                <input
                  type="checkbox"
                  checked={plan.enabled}
                  onChange={(e) =>
                    change(
                      "plans",
                      config.plans.map((p, j) =>
                        j === i ? { ...p, enabled: e.target.checked } : p,
                      ),
                    )
                  }
                />
                Actif
              </label>
              <button
                type="button"
                onClick={() =>
                  change(
                    "plans",
                    config.plans.filter((_, j) => i !== j),
                  )
                }
              >
                Supprimer
              </button>
            </fieldset>
          ))}
          <button
            type="button"
            onClick={() =>
              change("plans", [
                ...config.plans,
                {
                  id: crypto.randomUUID(),
                  name: "",
                  months: 1,
                  amountHtgMinor: 0,
                  amountUsdMinor: 0,
                  enabled: true,
                },
              ])
            }
          >
            Ajouter un plan
          </button>
        </>
      ) : (
        <>
          {config.paymentMethods.map((method, i) => (
            <fieldset key={i}>
              <legend>{method.name || "Nouveau moyen"}</legend>
              <div className="form-grid">
                {[
                  ["name", "Nom"],
                  ["account", "Compte"],
                  ["recipient", "Bénéficiaire"],
                ].map(([key, label]) => (
                  <Field key={key} label={label}>
                    <input
                      required
                      value={String(method[key as keyof typeof method])}
                      onChange={(e) =>
                        change(
                          "paymentMethods",
                          config.paymentMethods.map((m, j) =>
                            j === i ? { ...m, [key]: e.target.value } : m,
                          ),
                        )
                      }
                    />
                  </Field>
                ))}
                <Field label="Devise">
                  <select
                    value={method.currency}
                    onChange={(e) =>
                      change(
                        "paymentMethods",
                        config.paymentMethods.map((m, j) =>
                          j === i ? { ...m, currency: e.target.value } : m,
                        ),
                      )
                    }
                  >
                    <option>HTG</option>
                    <option>USD</option>
                  </select>
                </Field>
                {!config.plans.length && (
                  <>
                    <Field label={`Prix ${method.currency}`}>
                      <input
                        type="number"
                        min={0.01}
                        step="0.01"
                        value={method.amountMinor / 100}
                        onChange={(e) =>
                          change(
                            "paymentMethods",
                            config.paymentMethods.map((m, j) =>
                              j === i
                                ? {
                                    ...m,
                                    amountMinor: Math.round(
                                      Number(e.target.value) * 100,
                                    ),
                                  }
                                : m,
                            ),
                          )
                        }
                      />
                    </Field>
                    <Field label="Durée (mois)">
                      <input
                        type="number"
                        min={1}
                        value={method.months}
                        onChange={(e) =>
                          change(
                            "paymentMethods",
                            config.paymentMethods.map((m, j) =>
                              j === i
                                ? { ...m, months: Number(e.target.value) }
                                : m,
                            ),
                          )
                        }
                      />
                    </Field>
                  </>
                )}
              </div>
              <label className="check">
                <input
                  type="checkbox"
                  checked={method.enabled}
                  onChange={(e) =>
                    change(
                      "paymentMethods",
                      config.paymentMethods.map((m, j) =>
                        j === i ? { ...m, enabled: e.target.checked } : m,
                      ),
                    )
                  }
                />
                Actif
              </label>
              <button
                type="button"
                onClick={() =>
                  change(
                    "paymentMethods",
                    config.paymentMethods.filter((_, j) => j !== i),
                  )
                }
              >
                Supprimer
              </button>
            </fieldset>
          ))}
          <button
            type="button"
            onClick={() =>
              change("paymentMethods", [
                ...config.paymentMethods,
                {
                  id: crypto.randomUUID(),
                  name: "",
                  currency: "HTG",
                  amountMinor: 0,
                  months: 1,
                  account: "",
                  recipient: "",
                  enabled: false,
                },
              ])
            }
          >
            Ajouter un moyen de paiement
          </button>
        </>
      )}
      {action.feedback}
      <div className="form-actions">
        <Submit busy={action.busy}>Publier le bot</Submit>
      </div>
    </Form>
  );
}
