import { useState } from "react";
import { Search } from "lucide-react";
import { auth } from "../services/firebase";
import { dateLabel, type Row } from "../services/data";
import { compareMembers, isVip } from "../services/members";
import {
  applyCompensation,
  prepareCompensation,
  type Compensation,
  type CompensationResult,
  type CompensationScope,
} from "../services/compensation";
import { Field, Form, Modal, Submit, useAction } from "./ui";

export default function CompensationDialog({
  rows,
  onClose,
}: {
  rows: Row[];
  onClose: () => void;
}) {
  const storageKey = `choloto.compensation.${auth.currentUser?.uid}`;
  const [operation, setOperation] = useState<Compensation | null>(() => {
    try {
      const saved = JSON.parse(sessionStorage.getItem(storageKey) || "null");
      return saved?.adminUid === auth.currentUser?.uid &&
        Array.isArray(saved?.uids)
        ? saved
        : null;
    } catch {
      return null;
    }
  });
  const [scope, setScope] = useState<CompensationScope>(
    operation?.scope || "vip",
  );
  const [days, setDays] = useState(operation ? String(operation.days) : "");
  const [selected, setSelected] = useState(
    new Set<string>(operation?.uids || []),
  );
  const [search, setSearch] = useState("");
  const [progress, setProgress] = useState(0);
  const [result, setResult] = useState<CompensationResult | null>(null);
  const action = useAction();
  const complete = !!result && result.failed === 0;
  const locked = action.busy || !!operation;
  const count =
    operation?.uids.length ??
    (scope === "vip" ? rows.filter((row) => isVip(row)).length : selected.size);
  const visible = rows
    .filter((row) =>
      `${row.display_name || ""} ${row.email || ""} ${row.phone_number || ""} ${row.code_personnel || ""}`
        .toLowerCase()
        .includes(search.trim().toLowerCase()),
    )
    .sort((a, b) => compareMembers(a, b, "name"));
  const allSelected =
    visible.length > 0 && visible.every((row) => selected.has(row.id));
  const toggle = (id: string) =>
    setSelected((current) => {
      const next = new Set(current);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  const submit = () =>
    void action.run(async () => {
      const current =
        operation ||
        (await prepareCompensation(Number(days), scope, [...selected]));
      // Persist the audience and operation ID before the first write, including on reload.
      sessionStorage.setItem(storageKey, JSON.stringify(current));
      setOperation(current);
      setProgress(0);
      const outcome = await applyCompensation(current, setProgress);
      setResult(outcome);
      if (outcome.failed)
        throw new Error(
          `${outcome.failed} échec${outcome.failed > 1 ? "s" : ""}. ${outcome.error}`,
        );
      sessionStorage.removeItem(storageKey);
    }, "");
  return (
    <Modal title="Compensation" onClose={onClose} dismissible={!action.busy}>
      <div className="compensation-dialog">
        <Form onSubmit={submit}>
          <Field label="Bénéficiaires">
            <select
              value={scope}
              disabled={locked}
              onChange={(e) => setScope(e.target.value as CompensationScope)}
            >
              <option value="vip">Tous les VIP actifs</option>
              <option value="selected">Membres sélectionnés</option>
            </select>
          </Field>
          {scope === "selected" && !operation && (
            <div className="compensation-picker">
              <div className="search">
                <Search size={18} />
                <input
                  aria-label="Rechercher des bénéficiaires"
                  placeholder="Nom, e-mail, téléphone ou code"
                  value={search}
                  disabled={locked}
                  onChange={(e) => setSearch(e.target.value)}
                />
              </div>
              <label className="compensation-select-all">
                <input
                  type="checkbox"
                  checked={allSelected}
                  disabled={locked || !visible.length}
                  onChange={() =>
                    setSelected((current) => {
                      const next = new Set(current);
                      visible.forEach((row) =>
                        allSelected ? next.delete(row.id) : next.add(row.id),
                      );
                      return next;
                    })
                  }
                />
                Tout sélectionner{search.trim() ? " dans les résultats" : ""}
              </label>
              <div className="compensation-members">
                {visible.map((row) => (
                  <label className="compensation-member" key={row.id}>
                    <input
                      type="checkbox"
                      checked={selected.has(row.id)}
                      disabled={locked}
                      onChange={() => toggle(row.id)}
                    />
                    <span>
                      <strong>
                        {row.display_name || row.email || "Membre CHOLOTO"}
                      </strong>
                      <small>
                        {row.email || row.phone_number || row.code_personnel}
                      </small>
                    </span>
                    <span className="compensation-expiry">
                      {isVip(row) ? "VIP" : "Gratuit"}
                      <small>{dateLabel(row.end_sub)}</small>
                    </span>
                  </label>
                ))}
                {!visible.length && (
                  <p className="empty">Aucun membre trouvé</p>
                )}
              </div>
            </div>
          )}
          <Field label="Nombre de jours">
            <input
              type="number"
              min="1"
              max="3650"
              step="1"
              required
              inputMode="numeric"
              value={days}
              disabled={locked}
              onChange={(e) => setDays(e.target.value)}
            />
          </Field>
          <div className="compensation-summary">
            <strong>
              {count} membre{count > 1 ? "s" : ""}
            </strong>
            {Number(days) > 0 && (
              <span>
                +{days} jour{Number(days) > 1 ? "s" : ""}
              </span>
            )}
          </div>
          {action.busy && (
            <p role="status">
              {progress} / {operation?.uids.length ?? count}
            </p>
          )}
          {result && (
            <p className={complete ? "success" : ""} role="status">
              {result.applied} membre{result.applied > 1 ? "s" : ""} compensé
              {result.applied > 1 ? "s" : ""}
              {result.skipped > 0 &&
                ` · ${result.skipped} non éligible${result.skipped > 1 ? "s" : ""}`}
            </p>
          )}
          {action.feedback}
          <div className="form-actions">
            {complete ? (
              <button type="button" className="primary" onClick={onClose}>
                Terminer
              </button>
            ) : (
              <Submit busy={action.busy} disabled={!count || !days}>
                {action.busy
                  ? "Application…"
                  : operation
                    ? "Réessayer"
                    : "Appliquer la compensation"}
              </Submit>
            )}
          </div>
        </Form>
      </div>
    </Modal>
  );
}
