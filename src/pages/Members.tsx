import { useState } from "react";
import { NavLink, useLocation } from "react-router-dom";
import { doc, updateDoc, serverTimestamp } from "firebase/firestore";
import { Download, Search, Plus } from "lucide-react";
import { exportMembers } from "../services/export";
import { db } from "../services/firebase";
import {
  useCollection,
  useDocument,
  asDate,
  dateLabel,
  localDateInput,
  type Row,
} from "../services/data";
import {
  callAdmin,
  cancelMembership,
  adjustMembership,
  newReceiptId,
  paymentMethods,
  recordPayment,
  rejectPayment,
  suggestedEnd,
} from "../services/payments";
import {
  Badge,
  Field,
  Form,
  Modal,
  Panel,
  Status,
  Submit,
  useAction,
} from "../components/ui";
export default function Members() {
  const path = useLocation().pathname;
  return (
    <>
      <nav className="tabs">
        <NavLink to="/users">Membres</NavLink>
        <NavLink to="/payment-reviews">Paiements à vérifier</NavLink>
        <NavLink to="/payments">Transactions</NavLink>
      </nav>
      {path === "/payments" ? (
        <Transactions />
      ) : path === "/payment-reviews" ? (
        <Reviews />
      ) : (
        <Users />
      )}
    </>
  );
}
function Users() {
  const [count, setCount] = useState(200),
    [search, setSearch] = useState(""),
    [filter, setFilter] = useState("all"),
    [selected, setSelected] = useState<Row | null>(null),
    [create, setCreate] = useState(false);
  const state = useCollection("user", "", 0),
    action = useAction();
  const rows = state.rows.filter(
    (r) =>
      `${r.display_name || ""} ${r.email || ""} ${r.code_personnel || ""} ${r.phone_number || ""}`
        .toLowerCase()
        .includes(search.toLowerCase()) &&
      (filter === "all" ||
        (filter === "vip") ===
          (asDate(r.end_sub)?.getTime() || 0) > Date.now()),
  );
  return (
    <>
      <div className="toolbar">
        <div className="search">
          <Search size={18} />
          <input
            aria-label="Rechercher un membre"
            placeholder="Rechercher un membre…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <select
          aria-label="Abonnement"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        >
          <option value="all">Tous les membres</option>
          <option value="vip">VIP actifs</option>
          <option value="expired">Sans abonnement actif</option>
        </select>
        <button
          disabled={action.busy}
          onClick={() => void action.run(() => exportMembers(rows), "")}
        >
          <Download size={17} />
          Exporter Excel
        </button>
        <button className="primary" onClick={() => setCreate(true)}>
          <Plus size={17} />
          Ajouter
        </button>
      </div>
      <Panel>
        {action.feedback}
        <Status {...state} empty={!rows.length} />
        <div className="table-scroll">
          <table>
            <thead>
              <tr>
                <th>Membre</th>
                <th>Code</th>
                <th>Téléphone</th>
                <th>Abonnement</th>
                <th>Échéance</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id}>
                  <td>
                    <strong>{r.display_name || "—"}</strong>
                    <small>{r.email}</small>
                  </td>
                  <td>{r.code_personnel || "—"}</td>
                  <td>{r.phone_number || "—"}</td>
                  <td>
                    <Badge
                      tone={
                        (asDate(r.end_sub)?.getTime() || 0) > Date.now()
                          ? "green"
                          : ""
                      }
                    >
                      {(asDate(r.end_sub)?.getTime() || 0) > Date.now()
                        ? "VIP"
                        : "Standard"}
                    </Badge>
                  </td>
                  <td>{dateLabel(r.end_sub)}</td>
                  <td>
                    <button onClick={() => setSelected(r)}>Gérer</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {state.rows.length === count && (
          <button onClick={() => setCount(count + 200)}>Charger plus</button>
        )}
      </Panel>
      {selected && (
        <Modal
          title={selected.display_name || selected.email || "Membre"}
          onClose={() => setSelected(null)}
        >
          <MemberEditor row={selected} />
        </Modal>
      )}
      {create && (
        <Modal title="Ajouter un membre" onClose={() => setCreate(false)}>
          <CreateUser />
        </Modal>
      )}
    </>
  );
}
function CreateUser() {
  const [email, setEmail] = useState("");
  const action = useAction();
  return (
    <Form
      onSubmit={() =>
        void action.run(
          () =>
            callAdmin("ensureUserDocumentByEmail", {
              email: email.trim().toLowerCase(),
            }),
          "Compte vérifié et profil enregistré",
        )
      }
    >
      <Field label="Adresse e-mail">
        <input
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
      </Field>
      {action.feedback}
      <Submit busy={action.busy} />
    </Form>
  );
}
function MemberEditor({ row }: { row: Row }) {
  const [name, setName] = useState(row.display_name || ""),
    [phone, setPhone] = useState(row.phone_number || ""),
    [payment, setPayment] = useState(false),
    [cancel, setCancel] = useState(false),
    [adjust, setAdjust] = useState(false),
    [providers, setProviders] = useState<string[] | null>(null);
  const action = useAction();
  return (
    <>
      {adjust ? (
        <AdjustForm row={row} />
      ) : cancel ? (
        <CancelForm uid={row.id} />
      ) : payment ? (
        <PaymentForm uid={row.id} previous={asDate(row.end_sub)} />
      ) : (
        <Form
          onSubmit={() =>
            void action.run(() =>
              updateDoc(doc(db, "user", row.id), {
                display_name: name.trim(),
                phone_number: phone.trim(),
                updated_time: serverTimestamp(),
              }),
            )
          }
        >
          <Field label="Nom">
            <input
              value={name}
              maxLength={256}
              onChange={(e) => setName(e.target.value)}
            />
          </Field>
          <Field label="Téléphone">
            <input
              value={phone}
              maxLength={40}
              onChange={(e) => setPhone(e.target.value)}
            />
          </Field>
          {action.feedback}
          <div className="form-actions">
            <Submit busy={action.busy} />
            <button type="button" onClick={() => setPayment(true)}>
              Abonner / renouveler
            </button>
            <button type="button" onClick={() => setAdjust(true)}>
              Ajuster l’échéance
            </button>
            {row.end_sub && (
              <button type="button" onClick={() => setCancel(true)}>
                Annuler l’abonnement
              </button>
            )}
            <button
              type="button"
              disabled={action.busy}
              onClick={() =>
                void action.run(async () => {
                  const data = await callAdmin("getUserAuthProviders", {
                    uids: [row.id],
                  });
                  setProviders(data.providers?.[row.id] || []);
                }, "")
              }
            >
              Méthodes de connexion
            </button>
            {providers && <p>{providers.join(" · ") || "Aucune méthode"}</p>}
          </div>
        </Form>
      )}
    </>
  );
}
function Reviews() {
  const [count, setCount] = useState(100),
    [filter, setFilter] = useState("pending"),
    [selected, setSelected] = useState<Row | null>(null);
  const state = useCollection(
      "payment_requests",
      "created_at",
      count,
      0,
      filter === "all" ? "" : "status",
      filter,
    ),
    rows = state.rows.filter((r) => filter === "all" || r.status === filter);
  return (
    <Panel
      title="Paiements à vérifier"
      action={
        <select
          aria-label="Statut"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        >
          <option value="pending">En attente</option>
          <option value="approved">Approuvés</option>
          <option value="rejected">Refusés</option>
          <option value="all">Tous</option>
        </select>
      }
    >
      <Status {...state} empty={!rows.length} />
      <div className="table-scroll">
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Membre</th>
              <th>Montant</th>
              <th>Méthode</th>
              <th>Statut</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td>{dateLabel(r.created_at, true)}</td>
                <td>{r.user_uid}</td>
                <td>
                  {r.amount ?? "—"} {r.currency}
                </td>
                <td>{r.payment_method}</td>
                <td>
                  <Badge
                    tone={
                      r.status === "approved"
                        ? "green"
                        : r.status === "pending"
                          ? "amber"
                          : ""
                    }
                  >
                    {(
                      {
                        pending: "En attente",
                        approved: "Approuvé",
                        rejected: "Refusé",
                      } as Record<string, string>
                    )[r.status] || r.status}
                  </Badge>
                </td>
                <td>
                  <button onClick={() => setSelected(r)}>Examiner</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {state.rows.length === count && (
        <button onClick={() => setCount(count + 100)}>Charger plus</button>
      )}
      {selected && (
        <Modal title="Vérifier le paiement" onClose={() => setSelected(null)}>
          <Review row={selected} done={() => setSelected(null)} />
        </Modal>
      )}
    </Panel>
  );
}
function Review({ row, done }: { row: Row; done: () => void }) {
  const proof = useDocument(`payment_requests/${row.id}/evidence/image`),
    profile = useDocument(`user/${row.user_uid}`),
    [reason, setReason] = useState("");
  const action = useAction();
  return (
    <>
      <p>
        {profile.data?.display_name} · {profile.data?.email}
      </p>
      <p>{row.note}</p>
      <p>{row.payment_reference}</p>
      <Status
        loading={proof.loading || profile.loading}
        error={proof.error || profile.error}
      />
      {proof.data && (
        <img
          className="proof"
          alt="Justificatif de paiement"
          src={`data:image/jpeg;base64,${proof.data.base64}`}
        />
      )}
      <p>{row.rejection_reason}</p>
      {row.status === "pending" && !profile.loading && profile.data && (
        <>
          <PaymentForm
            uid={row.user_uid}
            previous={asDate(profile.data.end_sub)}
            request={row}
            done={done}
          />
          <hr />
          <Form
            onSubmit={() =>
              void action.run(async () => {
                await rejectPayment(row.id, reason);
                done();
              })
            }
          >
            <Field label="Motif du refus">
              <textarea
                required
                maxLength={500}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
              />
            </Field>
            {action.feedback}
            <Submit busy={action.busy}>Refuser</Submit>
          </Form>
        </>
      )}
    </>
  );
}
function PaymentForm({
  uid,
  previous,
  request,
  done,
}: {
  uid: string;
  previous: Date | null;
  request?: Row;
  done?: () => void;
}) {
  const [id] = useState(newReceiptId),
    [amount, setAmount] = useState(request?.amount?.toString() || ""),
    [currency, setCurrency] = useState(request?.currency || "GDS"),
    [method, setMethod] = useState(request?.payment_method || "moncash"),
    [end, setEnd] = useState(localDateInput(suggestedEnd(previous)));
  const action = useAction();
  return (
    <Form
      onSubmit={() =>
        void action.run(async () => {
          await recordPayment({
            id,
            uid,
            requestId: request?.id,
            amount: Number(amount),
            currency,
            method,
            end: new Date(`${end}T23:59:59`),
          });
          done?.();
        }, "Paiement enregistré")
      }
    >
      <div className="form-grid">
        <Field label="Montant">
          <input
            type="number"
            min="0.01"
            max="999999999.99"
            step="0.01"
            required
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
        </Field>
        <Field label="Devise">
          <select
            value={currency}
            onChange={(e) => setCurrency(e.target.value)}
          >
            <option>GDS</option>
            <option>USD</option>
          </select>
        </Field>
        <Field label="Méthode">
          <select value={method} onChange={(e) => setMethod(e.target.value)}>
            {paymentMethods.map((m) => (
              <option key={m}>{m}</option>
            ))}
          </select>
        </Field>
        <Field label="Fin d’abonnement">
          <input
            type="date"
            required
            value={end}
            onChange={(e) => setEnd(e.target.value)}
          />
        </Field>
      </div>
      {action.feedback}
      <Submit busy={action.busy || !!action.success}>
        {request ? "Approuver le paiement" : "Enregistrer le paiement"}
      </Submit>
    </Form>
  );
}
function Transactions() {
  const [count, setCount] = useState(100),
    [search, setSearch] = useState(""),
    [selected, setSelected] = useState<Row | null>(null);
  const state = useCollection("payment_transactions", "created_at", count);
  const rows = state.rows.filter((r) =>
    `${r.user_display_name} ${r.user_email} ${r.receipt_code}`
      .toLowerCase()
      .includes(search.toLowerCase()),
  );
  return (
    <Panel
      title="Transactions"
      action={
        <button
          onClick={() =>
            exportCsv(
              rows,
              [
                "receipt_code",
                "transaction_type",
                "refunded_amount",
                "refund_currency",
                "cancellation_reason",
                "user_display_name",
                "user_email",
                "amount",
                "currency",
                "payment_method",
                "created_at",
              ],
              "transactions",
            )
          }
        >
          <Download size={17} />
          Exporter CSV
        </button>
      }
    >
      <input
        aria-label="Rechercher une transaction"
        placeholder="Rechercher…"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
      />
      <Status {...state} empty={!rows.length} />
      <div className="table-scroll">
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Membre</th>
              <th>Montant</th>
              <th>Méthode</th>
              <th>Échéance</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td>
                  {dateLabel(r.created_at, true)}
                  <small>{transactionLabel(r.transaction_type)}</small>
                </td>
                <td>
                  <strong>{r.user_display_name || "—"}</strong>
                  <small>{r.user_email}</small>
                </td>
                <td>
                  {r.transaction_type === "cancellation"
                    ? `${r.refunded_amount ?? "—"} ${r.refund_currency || ""}`
                    : `${r.amount ?? "—"} ${r.currency || ""}`}
                </td>
                <td>{r.payment_method}</td>
                <td>{dateLabel(r.new_end_sub)}</td>
                <td>
                  <button onClick={() => setSelected(r)}>Reçu</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {state.rows.length === count && (
        <button onClick={() => setCount(count + 100)}>Charger plus</button>
      )}
      {selected && (
        <Modal title="Reçu de paiement" onClose={() => setSelected(null)}>
          <div className="receipt">
            <h2>CHOLOTO</h2>
            <p>{selected.receipt_code}</p>
            <p>{transactionLabel(selected.transaction_type)}</p>
            <p>
              {selected.user_display_name}
              <br />
              {selected.user_email}
            </p>
            <h2>
              {selected.transaction_type === "cancellation"
                ? `${selected.refunded_amount ?? "—"} ${selected.refund_currency || ""}`
                : `${selected.amount ?? ""} ${selected.currency || ""}`}
            </h2>
            <p>
              {selected.payment_method} · {dateLabel(selected.created_at, true)}
            </p>
            {selected.new_end_sub && (
              <p>Échéance : {dateLabel(selected.new_end_sub)}</p>
            )}
            {selected.cancellation_reason && (
              <p>{selected.cancellation_reason}</p>
            )}
          </div>
          <button onClick={() => window.print()}>Imprimer / PDF</button>
        </Modal>
      )}
    </Panel>
  );
}
export function csvCell(value: unknown) {
  let text = asDate(value) ? dateLabel(value) : String(value ?? "");
  if (/^[=+@\-\t\r]/.test(text)) text = `'${text}`;
  return `"${text.replaceAll('"', '""')}"`;
}
function exportCsv(rows: Row[], fields: string[], name: string) {
  const csv =
    "\uFEFF" +
    [
      fields.map(csvCell).join(";"),
      ...rows.map((r) => fields.map((f) => csvCell(r[f])).join(";")),
    ].join("\r\n");
  const url = URL.createObjectURL(
    new Blob([csv], { type: "text/csv;charset=utf-8" }),
  );
  const link = document.createElement("a");
  link.href = url;
  link.download = `${name}-${localDateInput()}.csv`;
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function CancelForm({ uid }: { uid: string }) {
  const [id] = useState(newReceiptId),
    [reason, setReason] = useState(""),
    [refund, setRefund] = useState(""),
    [currency, setCurrency] = useState("GDS");
  const action = useAction();
  return (
    <Form
      onSubmit={() =>
        void action.run(
          () =>
            cancelMembership(
              uid,
              reason,
              refund.trim() ? Number(refund) : null,
              currency,
              id,
            ),
          "Abonnement annulé",
        )
      }
    >
      <Field label="Motif de l’annulation">
        <textarea
          required
          maxLength={500}
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
      </Field>
      <div className="form-grid">
        <Field label="Montant retourné">
          <input
            type="number"
            min="0"
            max="999999999.99"
            step="0.01"
            value={refund}
            onChange={(e) => setRefund(e.target.value)}
          />
        </Field>
        <Field label="Devise">
          <select
            value={currency}
            onChange={(e) => setCurrency(e.target.value)}
          >
            <option>GDS</option>
            <option>USD</option>
          </select>
        </Field>
      </div>
      {action.feedback}
      <Submit busy={action.busy || !!action.success}>
        Confirmer l’annulation
      </Submit>
    </Form>
  );
}

function transactionLabel(type: string) {
  return (
    (
      {
        subscription: "Abonnement",
        renewal: "Renouvellement",
        adjustment: "Ajustement",
        cancellation: "Annulation",
      } as Record<string, string>
    )[type] || "Paiement"
  );
}
function AdjustForm({ row }: { row: Row }) {
  const [id] = useState(newReceiptId),
    [end, setEnd] = useState(
      localDateInput(asDate(row.end_sub) || suggestedEnd(null)),
    );
  const action = useAction();
  return (
    <Form
      onSubmit={() =>
        void action.run(
          () => adjustMembership(row.id, new Date(`${end}T23:59:59`), id),
          "Échéance ajustée",
        )
      }
    >
      <Field label="Fin d’abonnement">
        <input
          type="date"
          required
          value={end}
          onChange={(e) => setEnd(e.target.value)}
        />
      </Field>
      {action.feedback}
      <Submit busy={action.busy || !!action.success} />
    </Form>
  );
}
