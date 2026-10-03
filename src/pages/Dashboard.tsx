import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  collection,
  getCountFromServer,
  query,
  where,
  Timestamp,
} from "firebase/firestore";
import { Users, Crown, Receipt, ArrowUpRight, Trophy } from "lucide-react";
import { db, getAnalyticsToken } from "../services/firebase";
import {
  asDate,
  dateLabel,
  numberLabel,
  useCollection,
} from "../services/data";
import { loadAnalytics, type AnalyticsOverview } from "../services/analytics";
import { lotteries } from "../services/publications";
import { Panel, Status, useAction } from "../components/ui";
export default function Dashboard() {
  const [stats, setStats] = useState<{
      members: number;
      vip: number;
      pending: number;
    } | null>(null),
    [error, setError] = useState("");
  const draws = useCollection("resultats", "date", 8),
    bingo = useCollection(
      "bingo",
      "date",
      0,
      new Date(new Date().getFullYear(), new Date().getMonth(), 1).getTime(),
    ),
    predictions = useCollection("prediction", "date", 3);
  useEffect(() => {
    let current = true;
    Promise.all([
      getCountFromServer(collection(db, "user")),
      getCountFromServer(
        query(collection(db, "user"), where("end_sub", ">=", Timestamp.now())),
      ),
      getCountFromServer(
        query(
          collection(db, "payment_requests"),
          where("status", "==", "pending"),
        ),
      ),
    ])
      .then(([members, vip, pending]) => {
        if (current)
          setStats({
            members: members.data().count,
            vip: vip.data().count,
            pending: pending.data().count,
          });
      })
      .catch((e) => {
        if (current) setError(e.message);
      });
    return () => {
      current = false;
    };
  }, []);
  const now = new Date(),
    monthBingos = bingo.rows.filter((r) => {
      const date = asDate(r.date);
      return (
        date &&
        date.getMonth() === now.getMonth() &&
        date.getFullYear() === now.getFullYear()
      );
    });
  return (
    <>
      <div className="welcome">
        <div>
          <h2>Aujourd’hui</h2>
        </div>
        <span>
          {new Intl.DateTimeFormat("fr-HT", { dateStyle: "full" }).format(now)}
        </span>
      </div>
      <Status error={error} />
      <div className="stats-grid">
        {[
          {
            label: "Membres",
            value: stats?.members,
            icon: Users,
            path: "/users",
            tone: "blue",
          },
          {
            label: "VIP actifs",
            value: stats?.vip,
            icon: Crown,
            path: "/users",
            tone: "gold",
          },
          {
            label: "Paiements en attente",
            value: stats?.pending,
            icon: Receipt,
            path: "/payment-reviews",
            tone: "orange",
          },
          {
            label: "BINGO ce mois",
            value:
              bingo.loading || bingo.error ? undefined : monthBingos.length,
            icon: Trophy,
            path: "/publications/history",
            tone: "green",
          },
        ].map((item) => (
          <Link to={item.path} className="stat-card" key={item.label}>
            <div className="stat-top">
              <span className={`stat-icon ${item.tone}`}>
                <item.icon size={21} />
              </span>
              <ArrowUpRight size={18} />
            </div>
            <strong>
              {item.value === undefined ? "—" : numberLabel(item.value)}
            </strong>
            <span>{item.label}</span>
          </Link>
        ))}
      </div>
      <div className="dashboard-columns">
        <Panel
          title="Derniers tirages"
          action={
            <Link to="/tirages">
              Voir tout <ArrowUpRight size={15} />
            </Link>
          }
        >
          <Status {...draws} empty={!draws.rows.length} />
          {draws.rows.slice(0, 6).map((r) => (
            <div className="draw-row" key={r.id}>
              <div>
                <strong>{lotteries[r.tirage] || r.tirage}</strong>
                <small>
                  {r.periode} · {dateLabel(r.date)}
                </small>
              </div>
              <div className="balls">
                {r.numeros?.map((n: string, i: number) => (
                  <span key={i}>{n}</span>
                ))}
              </div>
            </div>
          ))}
        </Panel>
        <div className="stack">
          <Panel title="Publier">
            <div className="quick-actions">
              {[
                ["/tirages", "Un tirage"],
                ["/predictions", "Des prédictions"],
                ["/publications", "Un BINGO"],
                ["/croix", "Une croix de la chance"],
              ].map(([path, title]) => (
                <Link key={path} to={path}>
                  <span>{title}</span>
                  <ArrowUpRight size={18} />
                </Link>
              ))}
            </div>
          </Panel>
          <Panel title="Dernières prédictions">
            <Status {...predictions} empty={!predictions.rows.length} />
            {predictions.rows.map((p) => (
              <div className="draw-row" key={p.id}>
                <div>
                  <strong>{p.periode}</strong>
                  <small>{dateLabel(p.date, true)}</small>
                </div>
                <span className="badge green">{p.pourcentage}%</span>
              </div>
            ))}
          </Panel>
        </div>
      </div>
      <Analytics />
      <Panel
        title="BINGO du mois"
        action={
          <Link to="/publications/history">
            Historique <ArrowUpRight size={15} />
          </Link>
        }
      >
        <Status error={bingo.error} />
        <div className="heatmap">
          {Array.from(
            {
              length: new Date(
                now.getFullYear(),
                now.getMonth() + 1,
                0,
              ).getDate(),
            },
            (_, i) => {
              const count = monthBingos.filter(
                (r) => asDate(r.date)?.getDate() === i + 1,
              ).length;
              return (
                <div
                  className={count ? "won" : ""}
                  title={`${i + 1} : ${count} BINGO`}
                  key={i}
                >
                  <span>{i + 1}</span>
                  <strong>{count || "·"}</strong>
                </div>
              );
            },
          )}
        </div>
      </Panel>
    </>
  );
}
function Analytics() {
  const [data, setData] = useState<AnalyticsOverview | null>(null);
  const action = useAction();
  return (
    <Panel
      title="Audience et engagement"
      action={
        <button
          disabled={action.busy}
          onClick={() =>
            void action.run(
              async () => setData(await loadAnalytics(!!action.error)),
              "",
            )
          }
        >
          {getAnalyticsToken() && !action.error
            ? "Actualiser"
            : "Autoriser Analytics"}
        </button>
      }
    >
      {action.feedback}
      {action.busy ? (
        <Status loading />
      ) : data ? (
        <>
          <div className="analytics-metrics">
            {[
              ["En ligne", data.realtime],
              ["Actifs aujourd’hui", data.today],
              ["Nouveaux utilisateurs", data.newUsers],
              ["Actifs sur 7 jours", data.week],
              ["Actifs sur 30 jours", data.month],
              ["Session moyenne (s)", Math.round(data.duration)],
            ].map(([label, value]) => (
              <div key={label}>
                <strong>{numberLabel(Number(value))}</strong>
                <small>{label}</small>
              </div>
            ))}
          </div>
          <div
            className="chart"
            role="img"
            aria-label="Utilisateurs actifs par jour sur les 30 derniers jours"
          >
            {data.daily.map((d) => (
              <div
                key={d.date}
                title={`${d.date.slice(6)}/${d.date.slice(4, 6)} : ${d.active} utilisateurs actifs`}
              >
                <span
                  style={{
                    height: `${Math.max(1, (d.active / Math.max(...data.daily.map((r) => r.active), 1)) * 100)}%`,
                  }}
                />
                <small>{d.date.slice(6)}</small>
              </div>
            ))}
          </div>
          {data.screens.length > 0 && (
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>Écran</th>
                    <th>Vues</th>
                    <th>Utilisateurs</th>
                  </tr>
                </thead>
                <tbody>
                  {data.screens.map((row) => (
                    <tr key={row.name}>
                      <td>{row.name}</td>
                      <td>{numberLabel(row.views)}</td>
                      <td>{numberLabel(row.users)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      ) : (
        <p className="empty">Google Analytics</p>
      )}
    </Panel>
  );
}
