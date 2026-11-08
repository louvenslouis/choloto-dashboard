import {
  Component,
  Suspense,
  lazy,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { onIdTokenChanged, type User } from "firebase/auth";
import {
  Link,
  Navigate,
  NavLink,
  Route,
  Routes,
  useLocation,
} from "react-router-dom";
import {
  LayoutDashboard,
  Ticket,
  Newspaper,
  ChartNoAxesCombined,
  Headphones,
  Users,
  Settings,
  LogOut,
  Sun,
  Moon,
  UserRound,
  Check,
  ChevronsLeft,
  ChevronsRight,
} from "lucide-react";
import { auth, isAdministrator, login, logout } from "./services/firebase";
import PushSettings from "./components/PushSettings";
import VipBadgeSettings from "./components/VipBadgeSettings";
import { LuckyCross } from "./components/LuckyCross";
import { forgetSessionPush, reconcilePush } from "./services/adminPush";
import { MemberDirectoryProvider } from "./services/MemberDirectory";
import { OfficialProvider } from "./services/OfficialProvider";
import { Panel, Status, useAction } from "./components/ui";
const Dashboard = lazy(() => import("./pages/Dashboard"));
const Draws = lazy(() => import("./pages/Draws"));
const Publications = lazy(() => import("./pages/Publications"));
const Members = lazy(() => import("./pages/Members"));
const Support = lazy(() => import("./pages/Support"));
const links = [
  {
    path: "/dashboard",
    label: "Tableau de bord",
    tab: "Accueil",
    icon: LayoutDashboard,
  },
  { path: "/tirages", label: "Tirages", icon: Ticket },
  {
    path: "/publications",
    label: "Publications BINGO",
    tab: "Publications",
    publication: "BINGO",
    icon: Newspaper,
  },
  {
    path: "/predictions",
    label: "Prédictions",
    publication: "Prédictions",
    icon: ChartNoAxesCombined,
  },
  {
    path: "/croix",
    label: "Croix de la chance",
    publication: "Croix",
    icon: LuckyCross,
  },
  {
    path: "/support-inbox",
    label: "Service client",
    tab: "Support",
    icon: Headphones,
  },
  { path: "/users", label: "Membres & Paiements", tab: "Membres", icon: Users },
  { path: "/settings", label: "Paramètres", icon: Settings },
];
const memberPaths = ["/users", "/payments", "/payment-reviews"];

export default function App() {
  const [user, setUser] = useState<User | null>(null),
    [loading, setLoading] = useState(true),
    [error, setError] = useState("");
  useEffect(() => {
    let version = 0;
    let authorizedUid: string | null = null;
    const unsubscribe = onIdTokenChanged(auth, async (current) => {
      const active = ++version;
      // Keep drafts mounted during the hourly refresh of an authorized token.
      if (!current || current.uid !== authorizedUid) {
        setLoading(true);
        setUser(null);
      }
      try {
        if (current && !(await isAdministrator(current))) {
          if (active !== version) return;
          authorizedUid = null;
          setUser(null);
          setError("Accès administrateur requis.");
          await logout();
        } else if (active === version) {
          if (!current || authorizedUid !== current.uid) {
            void reconcilePush(current?.uid ?? null).catch(() => {});
          }
          authorizedUid = current?.uid ?? null;
          if (current) setError("");
          setUser(current);
        }
      } catch (e) {
        if (active === version) {
          authorizedUid = null;
          setUser(null);
          setError(e instanceof Error ? e.message : "Connexion impossible.");
        }
      } finally {
        if (active === version) setLoading(false);
      }
    });
    return () => {
      version++;
      unsubscribe();
    };
  }, []);
  if (loading)
    return (
      <div className="loading-page">
        <Status loading />
      </div>
    );
  return (
    <Boundary>
      {user ? (
        <OfficialProvider key={user.uid} uid={user.uid}>
          <MemberDirectoryProvider>
            <Shell user={user} />
          </MemberDirectoryProvider>
        </OfficialProvider>
      ) : (
        <Login error={error} />
      )}
    </Boundary>
  );
}
function Login({ error }: { error: string }) {
  const action = useAction();
  return (
    <main className="login-page">
      <section className="login-card">
        <img src={`${import.meta.env.BASE_URL}logo.png`} alt="CHOLOTO" />
        <span className="eyebrow">ESPACE ADMINISTRATEUR</span>
        <h1>Bienvenue sur CHOLOTO</h1>
        <Status error={error} />
        {action.feedback}
        <button
          className="primary"
          disabled={action.busy}
          onClick={() => void action.run(login, "")}
        >
          {action.busy ? "Connexion en cours…" : "Continuer avec Google"}
        </button>
      </section>
    </main>
  );
}
function Shell({ user }: { user: User }) {
  const [collapsed, setCollapsed] = useState(false);
  const [theme, setTheme] = useState(
    () => localStorage.getItem("choloto-theme") || "light",
  );
  const location = useLocation(),
    action = useAction();
  const cleanupStarted = useRef(false);
  useEffect(() => {
    if (cleanupStarted.current) return;
    cleanupStarted.current = true;
    void import("./services/support")
      .then(({ cleanExpiredSupport }) => cleanExpiredSupport(user.uid))
      .catch((error) => console.warn("Support cleanup:", error));
  }, [user.uid]);
  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem("choloto-theme", theme);
  }, [theme]);
  useEffect(() => {
    document.documentElement.scrollTop = 0;
    document.querySelector("main")?.scrollTo(0, 0);
  }, [location.pathname]);
  const isMembers = memberPaths.includes(location.pathname);
  const sectionPath = isMembers ? "/users" : location.pathname;
  const current =
    links.find(
      ({ path }) => sectionPath === path || sectionPath.startsWith(path + "/"),
    ) || links[0];
  const mobileSection = current.publication
    ? "/publications"
    : current.tab
      ? current.path
      : "/dashboard";
  const currentState = (path: string) =>
    current.path === path
      ? location.pathname === path
        ? "page"
        : "location"
      : undefined;
  return (
    <div className={`app ${collapsed ? "sidebar-collapsed" : ""}`}>
      <aside>
        <LinkBrand />
        <button
          className="collapse-sidebar"
          aria-label={collapsed ? "Développer le menu" : "Réduire le menu"}
          onClick={() => setCollapsed(!collapsed)}
        >
          {collapsed ? <ChevronsRight size={19} /> : <ChevronsLeft size={19} />}
        </button>
        <nav>
          {links.map((item, i) => (
            <div key={item.path}>
              {i === 0 && <span className="nav-label">VUE D’ENSEMBLE</span>}
              {i === 1 && <span className="nav-label">OPÉRATIONS</span>}
              {i === 5 && <span className="nav-label">COMMUNAUTÉ</span>}
              {i === 7 && <span className="nav-label">OUTILS</span>}
              <Link
                to={item.path}
                aria-label={item.label}
                aria-current={currentState(item.path)}
                className={current === item ? "active" : undefined}
              >
                <item.icon size={20} />
                <span>{item.label}</span>
              </Link>
            </div>
          ))}
        </nav>
      </aside>
      <div className="workspace">
        {location.pathname !== "/dashboard" &&
          location.pathname !== "/support-inbox" && (
            <header
              className={`section-header ${isMembers ? "members-section-header" : ""}`}
            >
              <span className="section-icon">
                <current.icon size={26} />
              </span>
              <img
                className="mobile-brand"
                src={`${import.meta.env.BASE_URL}logo.png`}
                alt="CHOLOTO"
              />
              <div>
                <span className="eyebrow">ESPACE DE GESTION</span>
                <h1>{current.label}</h1>
              </div>
              <span className="online-status">
                <i />
                En ligne
              </span>
            </header>
          )}
        <main
          id="main-content"
          className={
            location.pathname === "/dashboard"
              ? "dashboard-main"
              : location.pathname === "/support-inbox"
                ? "support-main"
                : isMembers
                  ? "members-main"
                  : ""
          }
        >
          {action.feedback}
          <Suspense fallback={<Status loading />}>
            <Routes>
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/tirages" element={<Draws />} />
              {[
                "/publications",
                "/publications/history",
                "/predictions",
                "/croix",
                "/croix/history",
              ].map((path) => (
                <Route
                  key={path}
                  path={path}
                  element={<Publications key={path} />}
                />
              ))}
              {memberPaths.map((path) => (
                <Route key={path} path={path} element={<Members />} />
              ))}
              <Route path="/support-inbox" element={<Support />} />
              <Route
                path="/settings"
                element={
                  <div className="settings-page">
                    <Panel title="Session administrateur">
                      <div className="settings-account">
                        <span className="settings-avatar">
                          {user.photoURL ? (
                            <img src={user.photoURL} alt="" />
                          ) : (
                            <UserRound size={28} />
                          )}
                        </span>
                        <div>
                          <strong>
                            {user.displayName || "Administrateur"}
                          </strong>
                          <small>{user.email}</small>
                        </div>
                        <span className="badge green">En ligne</span>
                      </div>
                    </Panel>
                    <Panel title="Apparence">
                      <div className="theme-selector">
                        <button
                          aria-pressed={theme === "light"}
                          onClick={() => setTheme("light")}
                        >
                          <Sun size={18} />
                          Clair
                        </button>
                        <button
                          aria-pressed={theme === "dark"}
                          onClick={() => setTheme("dark")}
                        >
                          <Moon size={18} />
                          Sombre
                        </button>
                      </div>
                    </Panel>
                    <PushSettings uid={user.uid} />
                    <VipBadgeSettings />
                    <Panel title="Sécurité">
                      <button
                        className="danger"
                        disabled={action.busy}
                        onClick={() => {
                          if (confirm("Se déconnecter ?"))
                            void action.run(async () => {
                              try {
                                await forgetSessionPush(user.uid);
                              } finally {
                                await logout();
                              }
                            }, "");
                        }}
                      >
                        <LogOut size={18} />
                        Déconnexion
                      </button>
                    </Panel>
                  </div>
                }
              />
              <Route path="*" element={<Navigate to="/dashboard" replace />} />
            </Routes>
          </Suspense>
        </main>
      </div>
      <nav className="bottom-nav" aria-label="Navigation mobile">
        {links
          .filter((item) => item.tab)
          .map((item) =>
            item.publication ? (
              <PublicationPicker
                key={item.path}
                active={Boolean(current.publication)}
                currentState={currentState}
              />
            ) : (
              <Link
                key={item.path}
                className="bottom-nav-item"
                to={item.path}
                aria-current={
                  mobileSection === item.path
                    ? currentState(item.path) || "location"
                    : undefined
                }
              >
                <item.icon size={22} />
                <span>{item.tab}</span>
              </Link>
            ),
          )}
      </nav>
    </div>
  );
}
function PublicationPicker({
  active,
  currentState,
}: {
  active: boolean;
  currentState: (path: string) => "page" | "location" | undefined;
}) {
  const [open, setOpen] = useState(false);
  const container = useRef<HTMLDivElement>(null);
  const trigger = useRef<HTMLButtonElement>(null);
  const location = useLocation();
  useEffect(() => setOpen(false), [location.key]);
  useEffect(() => {
    if (!open) return;
    const outside = (event: PointerEvent) => {
      if (
        event.target instanceof Node &&
        !container.current?.contains(event.target)
      )
        setOpen(false);
    };
    const desktop = window.matchMedia("(min-width: 992px)");
    const onResize = () => {
      if (desktop.matches) setOpen(false);
    };
    document.addEventListener("pointerdown", outside);
    desktop.addEventListener("change", onResize);
    return () => {
      document.removeEventListener("pointerdown", outside);
      desktop.removeEventListener("change", onResize);
    };
  }, [open]);
  return (
    <div
      className="publication-picker"
      ref={container}
      onBlur={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget)) setOpen(false);
      }}
      onKeyDown={(event) => {
        if (open && event.key === "Escape") {
          event.preventDefault();
          setOpen(false);
          trigger.current?.focus();
        }
      }}
    >
      <button
        className="bottom-nav-item"
        type="button"
        ref={trigger}
        aria-expanded={open}
        aria-controls="publication-choices"
        aria-current={active ? "location" : undefined}
        onClick={() => setOpen(!open)}
      >
        <Newspaper size={22} />
        <span>Publications</span>
      </button>
      <nav
        id="publication-choices"
        className="publication-choices"
        aria-label="Types de publication"
        hidden={!open}
      >
        {links
          .filter((item) => item.publication)
          .map((item) => (
            <Link
              key={item.path}
              to={item.path}
              aria-current={currentState(item.path)}
              onClick={() => {
                setOpen(false);
                trigger.current?.focus();
              }}
            >
              <span className="publication-choice-icon">
                <item.icon size={18} />
              </span>
              {item.publication}
              {currentState(item.path) && (
                <Check size={16} aria-hidden="true" />
              )}
            </Link>
          ))}
      </nav>
    </div>
  );
}
function LinkBrand() {
  return (
    <NavLink className="brand" to="/dashboard">
      <img src={`${import.meta.env.BASE_URL}logo.png`} alt="" />
      <div>
        <strong>CHOLOTO</strong>
        <span>ESPACE ADMIN</span>
      </div>
    </NavLink>
  );
}
class Boundary extends Component<{ children: ReactNode }, { error: boolean }> {
  state = { error: false };
  static getDerivedStateFromError() {
    return { error: true };
  }
  render() {
    return this.state.error ? (
      <main className="loading-page">
        <h1>Une erreur est survenue</h1>
        <button onClick={() => location.reload()}>Recharger</button>
      </main>
    ) : (
      this.props.children
    );
  }
}
