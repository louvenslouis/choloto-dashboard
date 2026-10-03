import { useState } from "react";
import { NavLink, useLocation } from "react-router-dom";
import { doc, updateDoc, serverTimestamp } from "firebase/firestore";
import {
  Download,
  Search,
  Plus,
  LayoutGrid,
  List,
  ArrowUpRight,
  Mail,
  Copy,
  Check,
  Crown,
  RefreshCw,
  SlidersHorizontal,
  MoreVertical,
  X,
  UserRound,
  CreditCard,
  CalendarDays,
  Hash,
  Wallet,
  Pencil,
  ArrowLeft,
} from "lucide-react";
import { compareMembers, isVip, isNewMember } from "../services/members";
import LineChart from "../components/TrendChart";
import Calendar from "../components/Calendar";
import { exportReceipt } from "../services/receipt";
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
  const pending = useCollection(
    "payment_requests",
    "",
    0,
    0,
    "status",
    "pending",
  );
  return (
    <>
      <nav className="tabs members-tabs">
        <NavLink to="/users">Membres</NavLink>
        <NavLink to="/payment-reviews">
          <span className="desktop-tab-label">Preuves de paiement</span>
          <span className="mobile-tab-label">Preuves</span>
          {!pending.error && !pending.loading && pending.rows.length > 0 && (
            <span className="pending-count">
              {pending.rows.length > 99 ? "99+" : pending.rows.length}
            </span>
          )}
        </NavLink>
        <NavLink to="/payments">
          <span className="desktop-tab-label">Paiements clients</span>
          <span className="mobile-tab-label">Paiements</span>
        </NavLink>
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
  const [view, setView] = useState("cards"),
    [sort, setSort] = useState("name"),
    [revision, setRevision] = useState(0);
  const [search, setSearch] = useState(""),
    [filter, setFilter] = useState("all");
  const [selected, setSelected] = useState<Row | null>(null),
    [initialPayment, setInitialPayment] = useState(false);
  const [create, setCreate] = useState(false),
    [filtersOpen, setFiltersOpen] = useState(false),
    [actionsOpen, setActionsOpen] = useState(false);
  const state = useCollection("user", "", 0, 0, "", "", revision),
    action = useAction();
  const now = Date.now(),
    vipCount = state.rows.filter((r) => isVip(r, now)).length;
  const rows = state.rows
    .filter(
      (r) =>
        `${r.display_name || ""} ${r.email || ""} ${r.code_personnel || ""} ${r.phone_number || ""}`
          .toLowerCase()
          .includes(search.trim().toLowerCase()) &&
        (filter === "all" || (filter === "vip") === isVip(r, now)),
    )
    .sort((a, b) => compareMembers(a, b, sort, now));
  const open = (r: Row, payment = false) => {
    setInitialPayment(payment);
    setSelected(r);
  };
  const filters = (
    <div className="member-filter-chips">
      {[
        ["all", "Tous", state.rows.length],
        ["vip", "VIP", vipCount],
        ["free", "Gratuit", state.rows.length - vipCount],
      ].map(([value, label, count]) => (
        <button
          key={value}
          aria-pressed={filter === value}
          onClick={() => setFilter(String(value))}
        >
          {label}
          <span>{state.loading ? "—" : count}</span>
        </button>
      ))}
    </div>
  );
  const sorting = (
    <select
      aria-label="Trier les membres"
      value={sort}
      onChange={(e) => setSort(e.target.value)}
    >
      <option value="name">Ordre alphabétique</option>
      <option value="updated_time">Dernière modification</option>
      <option value="end_sub">Expiration proche</option>
      <option value="created_time">Nouveaux utilisateurs</option>
    </select>
  );
  const refresh = () => {
    setRevision((v) => v + 1);
    setActionsOpen(false);
  };
  const exportRows = () => {
    setActionsOpen(false);
    void action.run(() => exportMembers(rows), "");
  };
  return (
    <div className="members-directory">
      <div className="members-page-action">
        <button onClick={() => setCreate(true)}>
          <Plus size={16} />
          Ajouter un utilisateur
        </button>
      </div>
      <div className="members-toolbar">
        <div className="search">
          <Search size={18} />
          <input
            aria-label="Rechercher un membre"
            placeholder="Nom, e-mail, téléphone ou code"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          {search && (
            <button
              aria-label="Effacer la recherche"
              onClick={() => setSearch("")}
            >
              <X size={16} />
            </button>
          )}
        </div>
        <div className="members-desktop-controls">
          {filters}
          <button
            aria-label="Actualiser les utilisateurs"
            disabled={state.loading}
            onClick={refresh}
          >
            <RefreshCw size={19} className={state.loading ? "spin" : ""} />
          </button>
          {sorting}
          <div className="member-view-toggle">
            <button
              aria-label="Vue cartes"
              aria-pressed={view === "cards"}
              onClick={() => setView("cards")}
            >
              <LayoutGrid size={18} />
            </button>
            <button
              aria-label="Vue liste"
              aria-pressed={view === "list"}
              onClick={() => setView("list")}
            >
              <List size={18} />
            </button>
          </div>
          <button
            aria-label="Exporter Excel"
            title="Exporter Excel"
            disabled={
              action.busy || state.loading || !!state.error || !rows.length
            }
            onClick={exportRows}
          >
            <Download size={18} />
          </button>
        </div>
        <div className="members-mobile-controls">
          <button
            aria-label="Filtres et tri"
            className={filter !== "all" || sort !== "name" ? "has-filter" : ""}
            onClick={() => setFiltersOpen(true)}
          >
            <SlidersHorizontal size={20} />
          </button>
          <div className="member-actions-menu">
            <button
              aria-label="Actions des membres"
              aria-expanded={actionsOpen}
              onClick={() => setActionsOpen(!actionsOpen)}
            >
              <MoreVertical size={20} />
            </button>
            {actionsOpen && (
              <div className="member-menu">
                <button disabled={state.loading} onClick={refresh}>
                  Actualiser
                </button>
                <button
                  disabled={
                    action.busy ||
                    state.loading ||
                    !!state.error ||
                    !rows.length
                  }
                  onClick={exportRows}
                >
                  Exporter Excel
                </button>
                <button
                  onClick={() => {
                    setActionsOpen(false);
                    setCreate(true);
                  }}
                >
                  Ajouter un utilisateur
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
      {action.feedback}
      <Status loading={state.loading} error={state.error} />
      {state.error && <button onClick={refresh}>Réessayer</button>}
      {!state.loading && !state.error && !rows.length && (
        <div className="members-empty">
          <UserRound size={32} />
          <h2>Aucun membre trouvé</h2>
          <button
            onClick={() => {
              setSearch("");
              setFilter("all");
            }}
          >
            Réinitialiser
          </button>
        </div>
      )}
      <div
        className={`members-results ${view === "cards" ? "cards-view" : "list-view"}`}
      >
        {view === "list" && (
          <div className="members-list-heading">
            <span>Membre</span>
            <span>E-mail</span>
            <span>Abonnement</span>
            <span>Actions</span>
          </div>
        )}
        {rows.map((r) => (
          <article className="member-card" key={r.id}>
            <div className="member-card-top">
              <MemberAvatar row={r} />
              <button className="member-identity" onClick={() => open(r)}>
                <strong>{r.display_name || "Membre CHOLOTO"}</strong>
                <small className="member-phone">
                  {r.phone_number || "Téléphone non renseigné"}
                </small>
                <span className="member-mobile-status">
                  <span className={isVip(r) ? "vip-text" : ""}>
                    {isVip(r) ? "VIP" : "Gratuit"}
                  </span>
                  {r.end_sub && <span> · {dateLabel(r.end_sub)}</span>}
                </span>
              </button>
              <button
                className="member-profile-arrow"
                aria-label={`Voir le profil de ${r.display_name || r.email}`}
                onClick={() => open(r)}
              >
                <ArrowUpRight size={18} />
              </button>
            </div>
            <div className="member-contact">
              <Mail size={16} />
              <span>{r.email || "E-mail non renseigné"}</span>
              {r.email && <CopyValue value={r.email} label="Copier l’e-mail" />}
            </div>
            <div className="member-metrics">
              <div>
                <small>Échéance</small>
                <strong>
                  {r.end_sub ? dateLabel(r.end_sub) : "Non définie"}
                </strong>
              </div>
              <div>
                <small>Mois actifs</small>
                <strong>{r.member_time ?? 0}</strong>
              </div>
            </div>
            <div className="member-card-actions">
              <button onClick={() => open(r)}>
                <UserRound size={18} />
                <span>Profil</span>
              </button>
              <button onClick={() => open(r, true)}>
                <CreditCard size={18} />
                <span>Paiement</span>
              </button>
            </div>
          </article>
        ))}
      </div>
      {filtersOpen && (
        <Modal title="Filtres et tri" onClose={() => setFiltersOpen(false)}>
          <div className="member-filter-dialog">
            {filters}
            {sorting}
            <button className="primary" onClick={() => setFiltersOpen(false)}>
              Appliquer
            </button>
          </div>
        </Modal>
      )}
      {selected && (
        <Modal
          title={initialPayment ? "Paiement" : "Profil du membre"}
          onClose={() => setSelected(null)}
        >
          <MemberEditor
            row={state.rows.find((r) => r.id === selected.id) || selected}
            initialPayment={initialPayment}
          />
        </Modal>
      )}
      {create && (
        <Modal title="Ajouter un utilisateur" onClose={() => setCreate(false)}>
          <CreateUser
            done={() => {
              setCreate(false);
              setRevision((v) => v + 1);
            }}
          />
        </Modal>
      )}
    </div>
  );
}
function MemberAvatar({ row }: { row: Row }) {
  const [failed, setFailed] = useState(false);
  return (
    <span className={`member-avatar ${isVip(row) ? "is-vip" : ""}`}>
      <span className="member-avatar-image">
        {row.photo_url && !failed ? (
          <img src={row.photo_url} alt="" onError={() => setFailed(true)} />
        ) : (
          (row.display_name || row.email || "M")[0].toUpperCase()
        )}
      </span>
      {isVip(row) && (
        <span className="vip-medal" title="Membre VIP">
          <Crown size={13} />
        </span>
      )}
      {isNewMember(row) && <span className="new-member">NOUVEAU</span>}
    </span>
  );
}
function CopyValue({ value, label }: { value: string; label: string }) {
  const [copied, setCopied] = useState(false),
    action = useAction();
  return (
    <>
      <button
        type="button"
        aria-label={copied ? "Copié" : label}
        title={label}
        onClick={() =>
          void action.run(async () => {
            await navigator.clipboard.writeText(value);
            setCopied(true);
          }, "")
        }
      >
        {copied ? <Check size={15} /> : <Copy size={15} />}
      </button>
      {action.feedback}
    </>
  );
}
function CreateUser({ done }: { done: () => void }) {
  const [email, setEmail] = useState("");
  const action = useAction();
  return (
    <Form
      onSubmit={() =>
        void action.run(async () => {
          await callAdmin("ensureUserDocumentByEmail", {
            email: email.trim().toLowerCase(),
          });
          done();
        }, "Compte vérifié et profil enregistré")
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
function MemberEditor({
  row,
  initialPayment = false,
}: {
  row: Row;
  initialPayment?: boolean;
}) {
  const [editing, setEditing] = useState(false);
  const [plan, setPlan] = useState(initialPayment && isVip(row));
  const [name, setName] = useState(row.display_name || ""),
    [phone, setPhone] = useState(row.phone_number || ""),
    [payment, setPayment] = useState(initialPayment),
    [cancel, setCancel] = useState(false),
    [adjust, setAdjust] = useState(false),
    [providers, setProviders] = useState<string[] | null>(null);
  const action = useAction();
  return (
    <>
      {(adjust || cancel || payment || editing) && (
        <button
          className="profile-back"
          onClick={() => {
            setAdjust(false);
            setCancel(false);
            setPayment(false);
            setEditing(false);
            setPlan(false);
          }}
        >
          <ArrowLeft size={16} />
          Profil
        </button>
      )}
      {plan ? (
        <CurrentPlan
          row={row}
          renew={() => setPlan(false)}
          adjust={() => {
            setPlan(false);
            setPayment(false);
            setAdjust(true);
          }}
          cancel={() => {
            setPlan(false);
            setPayment(false);
            setCancel(true);
          }}
        />
      ) : adjust ? (
        <AdjustForm row={row} />
      ) : cancel ? (
        <CancelForm uid={row.id} />
      ) : payment ? (
        <PaymentForm
          uid={row.id}
          previous={asDate(row.end_sub)}
          currentMethod={row.method}
        />
      ) : !editing ? (
        <div className="member-profile">
          <div className="member-profile-identity">
            <MemberAvatar row={row} />
            <div>
              <h3>{row.display_name || "Membre CHOLOTO"}</h3>
              <div className="profile-email">
                <span>{row.email || "E-mail non renseigné"}</span>
                {row.email && (
                  <CopyValue value={row.email} label="Copier l’e-mail" />
                )}
              </div>
              <Badge tone={isVip(row) ? "green" : "gold"}>
                {isVip(row) ? "ABONNEMENT ACTIF" : "ABONNEMENT INACTIF"}
              </Badge>
            </div>
          </div>
          <div className="member-profile-tiles">
            {[
              {
                label: "Mois actifs",
                value: row.member_time ?? 0,
                icon: CalendarDays,
              },
              {
                label: "Code personnel",
                value: row.code_personnel || "Non renseigné",
                icon: Hash,
              },
              {
                label: "Fin de l’abonnement",
                value: row.end_sub ? dateLabel(row.end_sub) : "Non définie",
                icon: CalendarDays,
              },
              {
                label: "Paiement",
                value:
                  (
                    {
                      moncash: "MonCash",
                      cash: "Espèces",
                      stripe: "Carte / Stripe",
                      natcash: "Natcash",
                      zelle: "Zelle",
                      cashapp: "CashApp",
                      virement: "Virement",
                    } as Record<string, string>
                  )[row.method] ||
                  row.method ||
                  "Non renseigné",
                icon: Wallet,
              },
            ].map((item) => (
              <div key={item.label}>
                <span className="profile-tile-icon">
                  <item.icon size={20} />
                </span>
                <div>
                  <small>{item.label}</small>
                  <strong>{item.value}</strong>
                </div>
              </div>
            ))}
          </div>
          <div className="profile-secondary-info">
            <span>{row.phone_number || "Téléphone non renseigné"}</span>
            {row.created_time && (
              <span>Inscription : {dateLabel(row.created_time)}</span>
            )}
          </div>
          <div className="form-actions">
            <button onClick={() => setEditing(true)}>
              <Pencil size={16} />
              Modifier
            </button>
            <button className="primary" onClick={() => setPayment(true)}>
              <CreditCard size={17} />
              Abonner / renouveler
            </button>
            <button onClick={() => setAdjust(true)}>Ajuster l’échéance</button>
            {row.end_sub && (
              <button onClick={() => setCancel(true)}>
                Annuler l’abonnement
              </button>
            )}
            <button
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
          </div>
          {providers && (
            <div className="provider-badges">
              {providers.length ? (
                providers.map((provider) => (
                  <span className="badge" key={provider}>
                    {(
                      {
                        "google.com": "Google",
                        "apple.com": "Apple",
                        password: "E-mail",
                        phone: "Téléphone",
                      } as Record<string, string>
                    )[provider] || provider}
                  </span>
                ))
              ) : (
                <small>Connexion inconnue</small>
              )}
            </div>
          )}
          {action.feedback}
        </div>
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
      <div className="proof-cards">
        {rows.map((r) => (
          <button
            className="proof-card"
            key={r.id}
            onClick={() => setSelected(r)}
          >
            <span className="proof-icon">
              <CreditCard size={24} />
            </span>
            <div>
              <strong>
                {r.user_display_name || r.user_email || "Demande de paiement"}
              </strong>
              <small>{dateLabel(r.created_at, true)}</small>
              <small>{r.payment_reference || r.payment_method}</small>
            </div>
            <div>
              <strong>
                {r.amount} {r.currency}
              </strong>
              <Badge
                tone={
                  r.status === "approved"
                    ? "green"
                    : r.status === "rejected"
                      ? "orange"
                      : "gold"
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
            </div>
            <ArrowUpRight size={18} />
          </button>
        ))}
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
  currentMethod,
  uid,
  previous,
  request,
  done,
}: {
  currentMethod?: string;
  uid: string;
  previous: Date | null;
  request?: Row;
  done?: () => void;
}) {
  const [id] = useState(newReceiptId),
    [amount, setAmount] = useState(request?.amount?.toString() || ""),
    [currency, setCurrency] = useState(request?.currency || "GDS"),
    [method, setMethod] = useState(
      request?.payment_method || currentMethod || "moncash",
    ),
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
      <div className="payment-editor-layout">
        <Calendar
          value={end}
          onChange={setEnd}
          min={localDateInput(
            new Date(Math.max(Date.now(), previous?.getTime() || 0) + 86400000),
          )}
        />
        <div className="payment-editor-fields">
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
      </div>
      {action.feedback}
      <Submit busy={action.busy || !!action.success}>
        {request ? "Approuver le paiement" : "Enregistrer le paiement"}
      </Submit>
    </Form>
  );
}
function Transactions() {
  const [search, setSearch] = useState(""),
    [period, setPeriod] = useState("month"),
    [status, setStatus] = useState("all"),
    [method, setMethod] = useState("all"),
    [selected, setSelected] = useState<Row | null>(null),
    [revision, setRevision] = useState(0);
  const today = new Date(),
    [from, setFrom] = useState(
      localDateInput(new Date(today.getFullYear(), today.getMonth(), 1)),
    ),
    [to, setTo] = useState(localDateInput());
  const start =
    period === "custom"
      ? new Date(`${from}T00:00:00`)
      : period === "year"
        ? new Date(today.getFullYear(), 0, 1)
        : period === "month"
          ? new Date(today.getFullYear(), today.getMonth(), 1)
          : new Date(
              today.getFullYear(),
              today.getMonth(),
              today.getDate() - (period === "7" ? 6 : 29),
            );
  const finish =
    period === "custom"
      ? new Date(`${to}T23:59:59`)
      : new Date(
          today.getFullYear(),
          today.getMonth(),
          today.getDate(),
          23,
          59,
          59,
        );
  const state = useCollection(
    "payment_transactions",
    "created_at",
    0,
    start.getTime(),
    "",
    "",
    revision,
  );
  const records = state.rows.filter(
    (r) => (asDate(r.created_at)?.getTime() || 0) <= finish.getTime(),
  );
  const cancelled = new Map(
    records
      .filter(
        (r) =>
          r.transaction_type === "cancellation" &&
          r.payment_cancelled &&
          r.related_transaction_ref?.id,
      )
      .map((r) => [r.related_transaction_ref.id, r]),
  );
  const payments = records.filter((r) => r.transaction_type !== "cancellation");
  const rows = payments.filter(
    (r) =>
      `${r.user_display_name || ""} ${r.user_email || ""} ${r.receipt_code || ""}`
        .toLowerCase()
        .includes(search.toLowerCase()) &&
      (status === "all" || (status === "cancelled") === cancelled.has(r.id)) &&
      (method === "all" || r.payment_method === method),
  );
  const totals: Record<string, number> = {};
  payments
    .filter(
      (r) => !cancelled.has(r.id) && r.currency && Number.isFinite(r.amount),
    )
    .forEach(
      (r) => (totals[r.currency] = (totals[r.currency] || 0) + r.amount),
    );
  const days = Math.max(
    1,
    Math.round(
      (Date.UTC(finish.getFullYear(), finish.getMonth(), finish.getDate()) -
        Date.UTC(start.getFullYear(), start.getMonth(), start.getDate())) /
        86400000,
    ) + 1,
  );
  const series = Array.from(
    { length: days },
    (_, i) =>
      payments.filter(
        (r) =>
          !cancelled.has(r.id) &&
          asDate(r.created_at)?.toDateString() ===
            new Date(
              start.getFullYear(),
              start.getMonth(),
              start.getDate() + i,
            ).toDateString(),
      ).length,
  );
  return (
    <div className="transactions-page">
      <section className="payment-trend">
        <div>
          <h2>Transactions</h2>
          <strong>
            {state.loading || state.error
              ? "—"
              : payments.filter((r) => !cancelled.has(r.id)).length}
          </strong>
          <small>Paiements encaissés</small>
          <div className="payment-totals">
            {Object.entries(totals).map(([currency, amount]) => (
              <span key={currency}>
                {amount.toLocaleString("fr-FR")} {currency}
              </span>
            ))}
          </div>
        </div>
        <div
          className="legacy-chart"
          style={{ "--chart-color": "#8B7CF6" } as React.CSSProperties}
        >
          <LineChart values={series} start={start.getTime()} />
        </div>
      </section>
      <div className="transaction-toolbar">
        <div className="search">
          <Search size={18} />
          <input
            aria-label="Rechercher une transaction"
            placeholder="Nom, e-mail ou reçu"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <select
          aria-label="Période des paiements"
          value={period}
          onChange={(e) => setPeriod(e.target.value)}
        >
          {[
            ["7", "7 derniers jours"],
            ["30", "30 derniers jours"],
            ["month", "Mois en cours"],
            ["year", "Année en cours"],
            ["custom", "Période personnalisée"],
          ].map(([v, t]) => (
            <option key={v} value={v}>
              {t}
            </option>
          ))}
        </select>
        <select
          aria-label="Statut des paiements"
          value={status}
          onChange={(e) => setStatus(e.target.value)}
        >
          <option value="all">Tous</option>
          <option value="active">Encaissés</option>
          <option value="cancelled">Annulés</option>
        </select>
        <select
          aria-label="Méthode de paiement"
          value={method}
          onChange={(e) => setMethod(e.target.value)}
        >
          <option value="all">Tous les moyens</option>
          {paymentMethods.map((m) => (
            <option key={m}>{m}</option>
          ))}
        </select>
        <button
          aria-label="Actualiser les paiements"
          onClick={() => setRevision((v) => v + 1)}
        >
          <RefreshCw size={18} />
        </button>
        <button
          onClick={() =>
            exportCsv(
              rows,
              [
                "receipt_code",
                "user_display_name",
                "user_email",
                "amount",
                "currency",
                "created_at",
              ],
              "transactions",
            )
          }
        >
          <Download size={17} />
          CSV
        </button>
      </div>
      {period === "custom" && (
        <div className="form-grid">
          <Field label="Du">
            <input
              type="date"
              value={from}
              max={to}
              onChange={(e) => setFrom(e.target.value)}
            />
          </Field>
          <Field label="Au">
            <input
              type="date"
              value={to}
              min={from}
              onChange={(e) => setTo(e.target.value)}
            />
          </Field>
        </div>
      )}
      <Status {...state} empty={!rows.length} />
      <div className="payment-records">
        {rows.map((r) => (
          <article className="payment-record" key={r.id}>
            <span className="avatar">
              <UserRound size={22} />
            </span>
            <div>
              <strong>
                {r.user_display_name || r.user_email || "Membre CHOLOTO"}
              </strong>
              <small>{r.user_email}</small>
              <small>
                {r.receipt_code} · {dateLabel(r.created_at, true)}
              </small>
            </div>
            <div>
              <strong>
                {r.amount ?? "—"} {r.currency}
              </strong>
              <small>{r.payment_method}</small>
            </div>
            <Badge tone={cancelled.has(r.id) ? "orange" : "green"}>
              {cancelled.has(r.id) ? "Annulé" : "Encaissé"}
            </Badge>
            <button
              onClick={() =>
                setSelected({
                  ...r,
                  cancellation_reason: cancelled.get(r.id)?.cancellation_reason,
                })
              }
            >
              Reçu
            </button>
          </article>
        ))}
      </div>
      {selected && (
        <Modal title="Reçu de paiement" onClose={() => setSelected(null)}>
          <div className="receipt">
            <img src={`${import.meta.env.BASE_URL}logo.png`} alt="CHOLOTO" />
            <h2>{selected.receipt_code}</h2>
            <p>
              {selected.user_display_name}
              <br />
              {selected.user_email}
            </p>
            <h2>
              {selected.amount ?? "—"} {selected.currency}
            </h2>
            <div className="member-profile-tiles">
              {[
                ["Type", transactionLabel(selected.transaction_type)],
                ["Moyen", selected.payment_method || "—"],
                ["Enregistré le", dateLabel(selected.created_at, true)],
                ["Échéance", dateLabel(selected.new_end_sub)],
              ].map(([label, value]) => (
                <div key={label}>
                  <div>
                    <small>{label}</small>
                    <strong>{value}</strong>
                  </div>
                </div>
              ))}
            </div>
            {selected.cancellation_reason && (
              <p>{selected.cancellation_reason}</p>
            )}
          </div>
          <ReceiptDownload row={selected} />
        </Modal>
      )}
    </div>
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
  const [method, setMethod] = useState(row.method || "");
  const action = useAction();
  return (
    <Form
      onSubmit={() =>
        void action.run(
          () =>
            adjustMembership(row.id, new Date(`${end}T23:59:59`), id, method),
          "Échéance ajustée",
        )
      }
    >
      <Field label="Méthode de paiement">
        <select value={method} onChange={(e) => setMethod(e.target.value)}>
          <option value="">Aucune méthode</option>
          {paymentMethods.map((m) => (
            <option key={m}>{m}</option>
          ))}
        </select>
      </Field>
      <Calendar value={end} onChange={setEnd} min={localDateInput()} />
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

function ReceiptDownload({ row }: { row: Row }) {
  const action = useAction();
  return (
    <>
      {action.feedback}
      <button
        disabled={action.busy}
        onClick={() => void action.run(() => exportReceipt(row), "")}
      >
        <Download size={17} />
        Télécharger le reçu PDF
      </button>
    </>
  );
}
function CurrentPlan({
  row,
  renew,
  adjust,
  cancel,
}: {
  row: Row;
  renew: () => void;
  adjust: () => void;
  cancel: () => void;
}) {
  const transactions = useCollection(
    "payment_transactions",
    "",
    0,
    0,
    "user_uid",
    row.id,
  );
  const latest = [...transactions.rows]
    .filter((r) => ["subscription", "renewal"].includes(r.transaction_type))
    .sort(
      (a, b) =>
        (asDate(b.created_at)?.getTime() || 0) -
        (asDate(a.created_at)?.getTime() || 0),
    )[0];
  return (
    <div className="current-plan">
      <div className="current-plan-title">
        <Crown size={30} />
        <div>
          <h3>Abonnement VIP</h3>
          <Badge tone="green">PLAN ACTIF</Badge>
        </div>
      </div>
      <div className="member-profile-tiles">
        {[
          ["Échéance actuelle", dateLabel(row.end_sub)],
          ["Méthode actuelle", row.method || "Non renseignée"],
          ["Ancienneté VIP", `${row.member_time || 0} mois`],
        ].map(([label, value]) => (
          <div key={label}>
            <div>
              <small>{label}</small>
              <strong>{value}</strong>
            </div>
          </div>
        ))}
      </div>
      <div className="current-plan-actions">
        <button className="primary" onClick={renew}>
          Prolonger l’abonnement
        </button>
        <button onClick={adjust}>Modifier le plan actuel</button>
        {latest && <ReceiptDownload row={latest} />}
        <Status loading={transactions.loading} error={transactions.error} />
        <button className="danger" onClick={cancel}>
          Annuler paiement / abonnement
        </button>
      </div>
    </div>
  );
}
