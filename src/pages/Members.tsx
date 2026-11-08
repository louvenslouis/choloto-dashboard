import { useEffect, useState } from "react";
import { NavLink, useLocation } from "react-router-dom";
import { doc, updateDoc, serverTimestamp } from "firebase/firestore";
import {
  Sprout,
  ShieldCheck,
  Compass,
  HeartHandshake,
  Star,
  Trophy,
  Download,
  Search,
  Gift,
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
import { compareMembers, isVip, vipBadgeIndex } from "../services/members";
import { useVipBadgeTiers } from "../services/vipBadges";
import { formatVipTime, measureVipTime } from "../services/vipDuration";
import { useVipHistory } from "../services/useVipHistory";
import { useMemberDirectory } from "../services/MemberDirectory";
import LineChart from "../components/TrendChart";
import Calendar from "../components/Calendar";
import CompensationDialog from "../components/CompensationDialog";
import { exportReceipt } from "../services/receipt";
import { exportMembers } from "../services/export";
import { useNotificationTarget } from "../services/useNotificationTarget";
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
  cancelMembership,
  adjustMembership,
  adjustmentEnd,
  type ExpiryAdjustment,
  newReceiptId,
  paymentMethods,
  recordPayment,
  paymentEnd,
  type PaymentTerm,
  rejectPayment,
  isCompensation,
  isPayment,
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
    [sort, setSort] = useState("name");
  const [search, setSearch] = useState(""),
    [filter, setFilter] = useState("all");
  const [selected, setSelected] = useState<Row | null>(null),
    [initialPayment, setInitialPayment] = useState(false);
  const [compensation, setCompensation] = useState(false),
    [filtersOpen, setFiltersOpen] = useState(false),
    [actionsOpen, setActionsOpen] = useState(false);
  const state = useMemberDirectory(),
    action = useAction();
  const [historyRevision, setHistoryRevision] = useState(0);
  const { history, error: historyError } = useVipHistory(historyRevision);
  const [, tick] = useState(0);
  useEffect(() => {
    const timer = window.setInterval(() => tick((n) => n + 1), 60_000);
    return () => window.clearInterval(timer);
  }, []);
  const now = Date.now();
  const { tiers, loading: badgesLoading, error: badgeError } = useVipBadgeTiers();
  const membership = new Map(
    state.rows.map((member) => {
      const time =
        history && measureVipTime(member, history.get(member.id) ?? [], now);
      const rank = time ? vipBadgeIndex(time.days, tiers) : -1;
      return [
        member.id,
        {
          duration: time ? formatVipTime(time) : "—",
          rank,
          badge: tiers[rank]?.name ?? "",
        },
      ];
    }),
  );
  const vipCount = state.rows.filter((r) => isVip(r, now)).length;
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
  const selectedMember =
    selected && (state.rows.find((r) => r.id === selected.id) || selected);
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
    state.refresh();
    setHistoryRevision((revision) => revision + 1);
    setActionsOpen(false);
  };
  const exportDisabled =
    action.busy ||
    state.loading ||
    !!state.error ||
    !history ||
    badgesLoading ||
    !rows.length;
  const exportRows = () => {
    setActionsOpen(false);
    void action.run(
      () =>
        exportMembers(
          rows.map((row) => ({
            ...row,
            vipDuration: membership.get(row.id)?.duration,
            vipBadge: membership.get(row.id)?.badge,
          })),
        ),
      "",
    );
  };
  return (
    <div className="members-directory">
      <div className="members-page-action">
        <button
          disabled={state.loading || !!state.error}
          onClick={() => setCompensation(true)}
        >
          <Gift size={16} />
          Compensation
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
            disabled={exportDisabled}
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
                <button disabled={exportDisabled} onClick={exportRows}>
                  Exporter Excel
                </button>
                <button
                  disabled={state.loading || !!state.error}
                  onClick={() => {
                    setActionsOpen(false);
                    setCompensation(true);
                  }}
                >
                  Compensation
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
      {action.feedback}
      <Status
        loading={state.loading}
        error={state.error || historyError || badgeError}
      />
      {(state.error || historyError) && (
        <button onClick={refresh}>Réessayer</button>
      )}
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
                <MemberRank membership={membership.get(r.id)} />
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
                <small>Durée VIP</small>
                <strong>{membership.get(r.id)?.duration}</strong>
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
      {selectedMember && (
        <Modal
          title={initialPayment ? "Paiement" : "Profil du membre"}
          onClose={() => setSelected(null)}
        >
          <MemberEditor
            row={selectedMember}
            membership={membership.get(selectedMember.id)}
            initialPayment={initialPayment}
          />
        </Modal>
      )}
      {compensation && (
        <CompensationDialog
          rows={state.rows}
          onClose={() => setCompensation(false)}
        />
      )}
    </div>
  );
}
type Membership = { duration: string; rank: number; badge: string };
const rankIcons = [
  UserRound,
  Sprout,
  ShieldCheck,
  Compass,
  HeartHandshake,
  Crown,
  Star,
  Trophy,
];

function MemberRank({ membership }: { membership?: Membership }) {
  if (!membership?.badge) return null;
  const Icon = rankIcons[membership.rank];
  return (
    <span className="member-rank" data-tier={membership.rank}>
      <Icon size={14} aria-hidden="true" />
      <span>{membership.badge}</span>
    </span>
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
function MemberEditor({
  row,
  membership,
  initialPayment = false,
}: {
  row: Row;
  membership?: Membership;
  initialPayment?: boolean;
}) {
  const [editing, setEditing] = useState(false);
  const [plan, setPlan] = useState(initialPayment && isVip(row));
  const [name, setName] = useState(row.display_name || ""),
    [phone, setPhone] = useState(row.phone_number || ""),
    [payment, setPayment] = useState(initialPayment),
    [cancel, setCancel] = useState(false),
    [adjust, setAdjust] = useState(false);
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
          duration={membership?.duration ?? "—"}
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
              <MemberRank membership={membership} />
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
                label: "Durée VIP",
                value: membership?.duration ?? "—",
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
          </div>
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
          </div>
        </Form>
      )}
    </>
  );
}
function Reviews() {
  const [count, setCount] = useState(100),
    [filter, setFilter] = useState("pending");
  const state = useCollection(
      "payment_requests",
      "created_at",
      count,
      0,
      filter === "all" ? "" : "status",
      filter,
    ),
    rows = state.rows.filter((r) => filter === "all" || r.status === filter);
  const {
    row: selected,
    select: setSelected,
    error: targetError,
  } = useNotificationTarget("request", "payment_requests", rows);
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
      <Status
        {...state}
        error={state.error || targetError}
        empty={!rows.length}
      />
      <div className="proof-cards">
        {rows.map((r) => (
          <button
            className="proof-card"
            key={r.id}
            onClick={() => setSelected(r.id)}
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
    [mode, setMode] = useState("month"),
    [days, setDays] = useState(""),
    [customDate, setCustomDate] = useState("");
  const term: PaymentTerm =
    mode === "days"
      ? { days: Number(days) }
      : mode === "custom"
        ? { end: new Date(`${customDate}T23:59:59`) }
        : { months: 1 };
  const expiry = paymentEnd(term, previous);
  const end =
    mode === "custom" ? customDate : expiry ? localDateInput(expiry) : "";
  const chooseDate = (value: string) => {
    setCustomDate(value);
    setMode("custom");
  };
  const action = useAction();
  if (action.success) return action.feedback;
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
            ...term,
          });
          done?.();
        }, "Paiement enregistré")
      }
    >
      <div className="payment-editor-layout">
        <Calendar
          key={end.slice(0, 7)}
          value={end}
          onChange={chooseDate}
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
          <Field label="Forfait">
            <select
              value={mode}
              onChange={(event) => {
                if (event.target.value === "custom") chooseDate(end);
                else setMode(event.target.value);
              }}
            >
              <option value="month">1 mois</option>
              <option value="days">Durée en jours</option>
              <option value="custom">Date personnalisée</option>
            </select>
          </Field>
          {mode === "days" && (
            <Field label="Nombre de jours">
              <input
                type="number"
                min="1"
                step="1"
                required
                value={days}
                onChange={(event) => setDays(event.target.value)}
              />
            </Field>
          )}
          <Field label="Fin d’abonnement">
            <input
              type="date"
              required
              value={end}
              onChange={(e) => chooseDate(e.target.value)}
            />
          </Field>
        </div>
      </div>
      {action.feedback}
      <Submit busy={action.busy} disabled={!end}>
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
      (status === "all" ||
        (status === "cancelled"
          ? cancelled.has(r.id)
          : isPayment(r) && !cancelled.has(r.id))) &&
      (method === "all" || r.payment_method === method),
  );
  const totals: Record<string, number> = {};
  const collected = payments.filter(
    (r) => isPayment(r) && !cancelled.has(r.id),
  );
  collected
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
      collected.filter(
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
      <div
        className="transaction-toolbar"
        role="group"
        aria-label="Filtres des paiements"
      >
        <div className="search">
          <Search size={18} />
          <input
            aria-label="Rechercher une transaction"
            placeholder="Nom, e-mail ou reçu"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div className="transaction-filters">
          <select
            data-active={period !== "month"}
            aria-label="Période des paiements"
            value={period}
            onChange={(e) => setPeriod(e.target.value)}
          >
            {[
              ["7", "7 jours"],
              ["30", "30 jours"],
              ["month", "Ce mois"],
              ["year", "Cette année"],
              ["custom", "Sur mesure"],
            ].map(([v, t]) => (
              <option key={v} value={v}>
                {t}
              </option>
            ))}
          </select>
          <select
            data-active={status !== "all"}
            aria-label="Statut des paiements"
            value={status}
            onChange={(e) => setStatus(e.target.value)}
          >
            <option value="all">Statut</option>
            <option value="active">Encaissés</option>
            <option value="cancelled">Annulés</option>
          </select>
          <select
            data-active={method !== "all"}
            aria-label="Méthode de paiement"
            value={method}
            onChange={(e) => setMethod(e.target.value)}
          >
            <option value="all">Moyen</option>
            {paymentMethods.map((m) => (
              <option key={m}>{m}</option>
            ))}
          </select>
        </div>
        <div className="transaction-actions">
          <button
            aria-label="Actualiser les paiements"
            title="Actualiser les paiements"
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
          <div className="transaction-dates">
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
      </div>
      <section className="payment-trend">
        <div>
          <h2>Transactions</h2>
          <strong>
            {state.loading || state.error ? "—" : collected.length}
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
            <Badge
              tone={
                cancelled.has(r.id) ? "orange" : isPayment(r) ? "green" : ""
              }
            >
              {cancelled.has(r.id)
                ? "Annulé"
                : isCompensation(r)
                  ? "Compensation"
                  : isPayment(r)
                    ? "Encaissé"
                    : "Ajustement"}
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
        <Modal
          title={isCompensation(selected) ? "Compensation" : "Reçu de paiement"}
          onClose={() => setSelected(null)}
        >
          <div className="receipt">
            <img src={`${import.meta.env.BASE_URL}logo.png`} alt="CHOLOTO" />
            <h2>{selected.receipt_code}</h2>
            <p>
              {selected.user_display_name}
              <br />
              {selected.user_email}
            </p>
            <h2>
              {isCompensation(selected)
                ? "Sans frais"
                : `${selected.amount ?? "—"} ${selected.currency || ""}`}
            </h2>
            <div className="member-profile-tiles">
              {[
                [
                  "Type",
                  isCompensation(selected)
                    ? "Compensation"
                    : transactionLabel(selected.transaction_type),
                ],
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
  const [id] = useState(newReceiptId);
  const [mode, setMode] = useState("date");
  const [date, setDate] = useState<string | null>(null);
  const [days, setDays] = useState("");
  const [method, setMethod] = useState<string>();
  const previous = asDate(row.end_sub);
  const signedDays =
    Number(days) > 0 ? Number(days) * (mode === "remove" ? -1 : 1) : 0;
  const change: ExpiryAdjustment =
    mode !== "date"
      ? { shiftDays: signedDays }
      : date === null
        ? null
        : new Date(`${date}T23:59:59`);
  const expiry = adjustmentEnd(change, previous);
  const end =
    mode === "date" && date !== null
      ? date
      : expiry
        ? localDateInput(expiry)
        : "";
  const chooseDate = (value: string) => {
    setDate(value);
    setMode("date");
  };
  const action = useAction();
  if (action.success) return action.feedback;
  return (
    <Form
      onSubmit={() =>
        void action.run(
          () => adjustMembership(row.id, change, id, method),
          "Échéance ajustée",
        )
      }
    >
      <Field label="Méthode de paiement">
        <select
          value={method ?? row.method ?? ""}
          onChange={(e) => setMethod(e.target.value)}
        >
          <option value="">Aucune méthode</option>
          {paymentMethods.map((m) => (
            <option key={m}>{m}</option>
          ))}
        </select>
      </Field>
      <Field label="Ajustement">
        <select value={mode} onChange={(event) => setMode(event.target.value)}>
          <option value="date">Choisir une date</option>
          <option value="add">Ajouter des jours</option>
          <option value="remove">Retirer des jours</option>
        </select>
      </Field>
      {mode !== "date" && (
        <Field label="Nombre de jours">
          <input
            type="number"
            min="1"
            step="1"
            required
            value={days}
            max={
              mode === "remove" && previous
                ? Math.ceil((previous.getTime() - Date.now()) / 86_400_000) - 1
                : undefined
            }
            onChange={(event) => setDays(event.target.value)}
          />
        </Field>
      )}
      <Calendar
        key={end.slice(0, 7)}
        value={end}
        onChange={chooseDate}
        min={localDateInput()}
      />
      <Field label="Fin d’abonnement">
        <input
          type="date"
          required
          value={end}
          onChange={(e) => chooseDate(e.target.value)}
        />
      </Field>
      {action.feedback}
      <Submit busy={action.busy} disabled={!expiry} />
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
  duration,
  renew,
  adjust,
  cancel,
}: {
  row: Row;
  duration: string;
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
          ["Durée VIP", duration],
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
