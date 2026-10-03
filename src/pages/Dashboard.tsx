import { useEffect, useState, type ReactNode, type CSSProperties } from "react";
import { Link } from "react-router-dom";
import { collection, getCountFromServer } from "firebase/firestore";
import {
  Crown,
  Users,
  Trophy,
  Receipt,
  Headphones,
  MessageCircle,
  ChevronRight,
  ArrowUpRight,
  RefreshCw,
  Ticket,
  ChartNoAxesCombined,
  Clover,
} from "lucide-react";
import { auth, db } from "../services/firebase";
import { asDate, dateLabel, useCollection, type Row } from "../services/data";
import { Panel, Status } from "../components/ui";
const day = 86400000;
export default function Dashboard() {
  const [now, setNow] = useState(() => new Date());
  const [statistics, setStatistics] = useState(false);
  const [horizon, setHorizon] = useState(30);
  const start = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate(),
  ).getTime();
  const month = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
  const vip = useCollection("user", "end_sub", 0, now.getTime());
  const members = useCollection("user", "created_time", 0, start - 29 * day);
  const bingo = useCollection("bingo", "date", 0, month);
  const recent = useCollection("bingo", "date", 10);
  const payments = useCollection(
    "payment_requests",
    "",
    0,
    0,
    "status",
    "pending",
  );
  const support = useCollection(
    "support_conversations",
    "",
    0,
    0,
    "last_sender_role",
    "user",
  );
  const draws = useCollection("resultats", "date", 0, start);
  const predictions = useCollection("prediction", "date", 0, start);
  const cross = useCollection("croix", "date", 0, start);
  const [activity, setActivity] = useState<{
    comments: number;
    reactions: number;
  } | null>(null);
  const [activityError, setActivityError] = useState("");
  useEffect(() => {
    let active = true;
    setActivity(null);
    setActivityError("");
    if (recent.loading || recent.error) return;
    Promise.all(
      recent.rows.map(async (r) => {
        const counts = await Promise.all(
          ["comments", "hiddenComments", "bingostats"].map((name) =>
            getCountFromServer(collection(db, `bingo/${r.id}/${name}`)),
          ),
        );
        return {
          comments: counts[0].data().count + counts[1].data().count,
          reactions: counts[2].data().count,
        };
      }),
    )
      .then((rows) => {
        if (active)
          setActivity(
            rows.reduce(
              (a, b) => ({
                comments: a.comments + b.comments,
                reactions: a.reactions + b.reactions,
              }),
              { comments: 0, reactions: 0 },
            ),
          );
      })
      .catch((e) => {
        if (active) setActivityError(e.message);
      });
    return () => {
      active = false;
    };
  }, [recent.rows, recent.loading, recent.error, now]);
  const registrations = members.rows.filter(
    (r) => (asDate(r.created_time)?.getTime() ?? Infinity) <= now.getTime(),
  );
  const monthBingo = bingo.rows.filter(
    (r) => (asDate(r.date)?.getTime() ?? Infinity) <= now.getTime(),
  );
  const validVip = vip.rows.filter(
    (r) => (asDate(r.end_sub)?.getTime() ?? 0) >= now.getTime(),
  );
  const renewal = validVip.filter(
    (r) => (asDate(r.end_sub)?.getTime() ?? 0) <= now.getTime() + 7 * day,
  ).length;
  const waiting = support.rows.filter(
    (r) => !["treated", "deleting"].includes(r.status),
  ).length;
  const periods = new Set(predictions.rows.map((r) => r.periode));
  const activeBingo = monthBingo.some(
    (r) => (asDate(r.expiration)?.getTime() ?? 0) > now.getTime(),
  );
  const operations = [
    {
      label: "Tirages",
      path: "/tirages",
      icon: Ticket,
      color: "#E6B800",
      ready: draws.rows.length > 0,
      detail: draws.rows[0]
        ? `${draws.rows[0].tirage?.toUpperCase()} · ${draws.rows[0].periode}`
        : "Aucun tirage aujourd’hui",
      status: draws.rows.length ? `${draws.rows.length} publiés` : "À publier",
      state: draws,
    },
    {
      label: "Prédictions",
      path: "/predictions",
      icon: ChartNoAxesCombined,
      color: "#6D5BD0",
      ready: periods.size >= 3,
      detail:
        ["Matin", "Midi", "Soir"].filter((p) => !periods.has(p)).join(" · ") ||
        "Matin · Midi · Soir",
      status: periods.size >= 3 ? "Complet" : `${periods.size}/3`,
      state: predictions,
    },
    {
      label: "BINGO",
      path: "/publications",
      icon: Trophy,
      color: "#E34D59",
      ready: activeBingo,
      detail: monthBingo[0]
        ? dateLabel(monthBingo[0].date, true)
        : "Aucune publication active",
      status: activeBingo ? "Actif" : "À publier",
      state: bingo,
    },
    {
      label: "Croix de la chance",
      path: "/croix",
      icon: Clover,
      color: "#3A7CA5",
      ready: cross.rows.length > 0,
      detail: cross.rows[0]
        ? dateLabel(cross.rows[0].date, true)
        : "Aucune publication aujourd’hui",
      status: cross.rows.length ? "Publié" : "À publier",
      state: cross,
    },
  ];
  const user = auth.currentUser;
  const metric = (state: { loading: boolean; error: string }, count: number) =>
    state.loading || state.error ? "—" : count.toLocaleString("fr-HT");
  return (
    <div
      className={`overview ${statistics ? "show-statistics" : "show-tasks"}`}
    >
      <div className="overview-header">
        <div>
          <h1>Vue d’ensemble</h1>
          <small>
            {now.toLocaleDateString("fr-HT", { dateStyle: "full" })}
          </small>
        </div>
        <div className="actions">
          <button
            className="refresh-dashboard"
            aria-label="Actualiser"
            onClick={() => setNow(new Date())}
          >
            <RefreshCw size={19} />
          </button>
          <span className="avatar">
            {(user?.email || "A")[0].toUpperCase()}
          </span>
          <span className="overview-email">{user?.email}</span>
        </div>
      </div>
      <div className="mobile-segments">
        <button
          className={!statistics ? "active" : ""}
          onClick={() => setStatistics(false)}
        >
          À traiter
        </button>
        <button
          className={statistics ? "active" : ""}
          onClick={() => setStatistics(true)}
        >
          Statistiques
        </button>
      </div>
      <div className="task-tiles">
        {[
          {
            title: "Paiements à traiter",
            detail: `${metric(payments, payments.rows.length)} en attente`,
            icon: Receipt,
            path: "/payment-reviews",
            tone: "gold",
          },
          {
            title: "Service client",
            detail: `${metric(support, waiting)} à traiter`,
            icon: Headphones,
            path: "/support-inbox",
            tone: "blue",
          },
          {
            title: "Activité BINGO",
            detail: activity
              ? `${activity.comments} commentaire${activity.comments === 1 ? "" : "s"} • ${activity.reactions} réaction${activity.reactions === 1 ? "" : "s"}`
              : "—",
            icon: MessageCircle,
            path: "/publications/history",
            tone: "green",
          },
        ].map((item) => (
          <Link className="task-tile" to={item.path} key={item.title}>
            <span className={`task-icon ${item.tone}`}>
              <item.icon size={21} />
            </span>
            <div>
              <strong>{item.title}</strong>
              <small>{item.detail}</small>
            </div>
            <ChevronRight size={18} />
          </Link>
        ))}
      </div>
      <Status
        error={[
          payments.error,
          support.error,
          recent.error,
          activityError,
          vip.error,
          members.error,
          bingo.error,
          draws.error,
          predictions.error,
          cross.error,
        ]
          .filter(Boolean)
          .join(" · ")}
      />
      <div className="legacy-stats">
        <Stat
          title="VIP actifs"
          value={metric(vip, validVip.length)}
          detail={`${renewal} à renouveler sous 7 jours`}
          color="#16805C"
          icon={<Crown size={20} />}
          path="/users"
          footer={
            <select
              aria-label="Période VIP"
              value={horizon}
              onChange={(e) => setHorizon(Number(e.target.value))}
            >
              <option value={30}>30 jours</option>
              <option value={90}>3 mois</option>
              <option value={180}>6 mois</option>
            </select>
          }
        >
          <LineChart
            values={Array.from(
              { length: horizon },
              (_, i) =>
                validVip.filter(
                  (r) =>
                    (asDate(r.end_sub)?.getTime() || 0) >=
                    now.getTime() + i * day,
                ).length,
            )}
            start={now.getTime()}
          />
        </Stat>
        <Stat
          title="Nouveaux membres"
          value={metric(members, registrations.length)}
          detail="inscriptions sur 30 jours"
          color="#3A7CA5"
          icon={<Users size={20} />}
          path="/users"
          footer={
            <span>
              {new Date(start - 29 * day).toLocaleDateString("fr-FR")} –{" "}
              {now.toLocaleDateString("fr-FR")}
            </span>
          }
        >
          <LineChart
            values={Array.from(
              { length: 30 },
              (_, i) =>
                registrations.filter((r) => {
                  const t = asDate(r.created_time)?.getTime() || 0;
                  return (
                    t >= start - (29 - i) * day && t < start - (28 - i) * day
                  );
                }).length,
            )}
            start={start - 29 * day}
          />
        </Stat>
        <Stat
          title="Bingo mensuel"
          value={metric(bingo, monthBingo.length)}
          detail="validés ce mois"
          color="#4AC77D"
          icon={<Trophy size={20} />}
          path="/publications/history"
          footer={
            <span>
              {now.toLocaleDateString("fr-FR", {
                month: "long",
                year: "numeric",
              })}
            </span>
          }
        >
          <MonthGrid now={now} rows={monthBingo} />
        </Stat>
      </div>
      <div className="operational-panels">
        <Panel
          title="Aujourd’hui"
          action={
            <span className="badge">
              {operations.filter((o) => o.ready).length}/4 prêtes
            </span>
          }
        >
          {operations.map((o) => (
            <Link className="operation-row" key={o.label} to={o.path}>
              <span
                className="task-icon"
                style={{ background: `${o.color}18`, color: o.color }}
              >
                <o.icon size={21} />
              </span>
              <div>
                <strong>{o.label}</strong>
                <small>{o.detail}</small>
              </div>
              <span className={`badge ${o.ready ? "green" : ""}`}>
                {o.state.loading || o.state.error ? "—" : o.status}
              </span>
              <ChevronRight size={16} />
            </Link>
          ))}
          <details className="pending-actions">
            <summary>
              Actions à traiter{" "}
              <span className="badge">
                {operations.filter((o) => !o.ready).length}
              </span>
            </summary>
            {operations
              .filter((o) => !o.ready)
              .map((o) => (
                <Link key={o.path} to={o.path}>
                  {o.label}
                  <ChevronRight size={16} />
                </Link>
              ))}
          </details>
        </Panel>
        <Panel title="Actions rapides">
          <div className="original-quick-actions">
            {[
              {
                label: "Saisir un tirage",
                path: "/tirages",
                icon: Ticket,
                color: "#E6B800",
              },
              {
                label: "Créer une prédiction",
                path: "/predictions",
                icon: ChartNoAxesCombined,
                color: "#6D5BD0",
              },
              {
                label: "Gérer les membres",
                path: "/users",
                icon: Users,
                color: "#3A7CA5",
              },
            ].map((o) => (
              <Link to={o.path} key={o.path}>
                <span
                  className="task-icon"
                  style={{ background: `${o.color}18`, color: o.color }}
                >
                  <o.icon size={21} />
                </span>
                <strong>{o.label}</strong>
                <ChevronRight size={18} />
              </Link>
            ))}
          </div>
        </Panel>
      </div>
    </div>
  );
}
function Stat({
  title,
  value,
  detail,
  color,
  icon,
  path,
  footer,
  children,
}: {
  title: string;
  value: string;
  detail: string;
  color: string;
  icon: ReactNode;
  path: string;
  footer: ReactNode;
  children: ReactNode;
}) {
  return (
    <section
      className="legacy-stat"
      style={{ "--chart-color": color } as CSSProperties}
    >
      <Link className="legacy-stat-title" to={path}>
        <span>{icon}</span>
        <strong>{title}</strong>
        <ArrowUpRight size={18} />
      </Link>
      <div className="legacy-stat-value">{value}</div>
      <small>{detail}</small>
      <div className="legacy-chart">{children}</div>
      <div className="legacy-stat-footer">{footer}</div>
    </section>
  );
}
function LineChart({ values, start }: { values: number[]; start: number }) {
  const step = Math.max(1, Math.ceil(Math.max(...values) / 3)),
    max = step * 3;
  const points = values.map((v, i) => [
    30 + (i * 260) / (values.length - 1),
    145 - (v / max) * 130,
  ]);
  const path = points.map(([x, y], i) => `${i ? "L" : "M"}${x},${y}`).join(" ");
  return (
    <svg viewBox="0 0 310 180" role="img" aria-label="Évolution sur la période">
      {[0, 1, 2, 3].map((i) => (
        <g key={i}>
          <line
            x1="30"
            x2="295"
            y1={145 - (i * 130) / 3}
            y2={145 - (i * 130) / 3}
            stroke="#ffffff12"
          />
          <text x="0" y={149 - (i * 130) / 3}>
            {i * step}
          </text>
        </g>
      ))}
      <path
        d={`${path} L290,145 L30,145 Z`}
        fill="var(--chart-color)"
        opacity=".16"
      />
      <path
        d={path}
        fill="none"
        stroke="var(--chart-color)"
        strokeWidth="2.5"
        strokeLinejoin="round"
      />
      <circle
        cx="290"
        cy={points.at(-1)![1]}
        r="4"
        fill="var(--chart-color)"
        stroke="white"
      />
      {[0, Math.floor((values.length - 1) / 2), values.length - 1].map(
        (v, i) => (
          <text
            key={i}
            x={30 + i * 130}
            y="174"
            textAnchor={i === 0 ? "start" : i === 2 ? "end" : "middle"}
          >
            {new Date(start + v * day).toLocaleDateString("fr-FR", {
              day: "2-digit",
              month: "2-digit",
            })}
          </text>
        ),
      )}
    </svg>
  );
}
function MonthGrid({ now, rows }: { now: Date; rows: Row[] }) {
  const offset =
    (new Date(now.getFullYear(), now.getMonth(), 1).getDay() + 6) % 7;
  const days = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  return (
    <div className="month-grid">
      <span />
      {["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"].map((d) => (
        <small key={d}>{d}</small>
      ))}
      {Array.from({ length: Math.ceil((offset + days) / 7) }, (_, week) => (
        <div className="month-week" key={week}>
          <small>S{week + 1}</small>
          {Array.from({ length: 7 }, (_, weekday) => {
            const d = week * 7 + weekday - offset + 1;
            const count = rows.filter(
              (r) => asDate(r.date)?.getDate() === d,
            ).length;
            return d < 1 || d > days ? (
              <span key={weekday} />
            ) : (
              <span
                key={weekday}
                className={`month-day ${count ? "won" : ""} ${d > now.getDate() ? "future" : ""}`}
                style={
                  count
                    ? {
                        background: `rgba(74,199,125,${Math.min(0.95, 0.3 + count * 0.16)})`,
                      }
                    : undefined
                }
                title={`${d} : ${count} BINGO`}
              >
                {d}
              </span>
            );
          })}
        </div>
      ))}
    </div>
  );
}
