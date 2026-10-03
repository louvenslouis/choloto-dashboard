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
  Clover,
  Headphones,
  Users,
  Settings,
  LogOut,
  Menu,
  X,
  Sun,
  Moon,
  Shield,
  UserRound,
  ChevronsLeft,
  ChevronsRight,
} from "lucide-react";
import { auth, isAdministrator, login, logout } from "./services/firebase";
import { OfficialProvider } from "./services/OfficialProvider";
import { Panel, Status, useAction } from "./components/ui";
const Dashboard = lazy(() => import("./pages/Dashboard"));
const Draws = lazy(() => import("./pages/Draws"));
const Publications = lazy(() => import("./pages/Publications"));
const Members = lazy(() => import("./pages/Members"));
const Support = lazy(() => import("./pages/Support"));
const links = [
  { path: "/dashboard", label: "Tableau de bord", icon: LayoutDashboard },
  { path: "/tirages", label: "Tirages", icon: Ticket },
  { path: "/publications", label: "Publications BINGO", icon: Newspaper },
  { path: "/predictions", label: "Prédictions", icon: ChartNoAxesCombined },
  { path: "/croix", label: "Croix de la chance", icon: Clover },
  { path: "/support-inbox", label: "Service client", icon: Headphones },
  { path: "/users", label: "Membres & Paiements", icon: Users },
  { path: "/settings", label: "Paramètres", icon: Settings },
];
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
          <Shell user={user} />
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
  const [open, setOpen] = useState(false),
    [theme, setTheme] = useState(
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
    setOpen(false);
    document.querySelector("main")?.scrollTo(0, 0);
  }, [location.pathname]);
  useEffect(() => {
    const close = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("keydown", close);
    return () => window.removeEventListener("keydown", close);
  }, []);
  const current =
    links.find((l) => location.pathname.startsWith(l.path)) ||
    (["\/payments", "/payment-reviews"].includes(location.pathname)
      ? links[6]
      : links[0]);
  return (
    <div className={`app ${collapsed ? "sidebar-collapsed" : ""}`}>
      {open && (
        <button
          className="overlay"
          aria-label="Fermer le menu"
          onClick={() => setOpen(false)}
        />
      )}
      <aside className={open ? "open" : ""}>
        <LinkBrand />
        <button
          className="collapse-sidebar"
          aria-label={collapsed ? "Développer le menu" : "Réduire le menu"}
          onClick={() => setCollapsed(!collapsed)}
        >
          {collapsed ? <ChevronsRight size={19} /> : <ChevronsLeft size={19} />}
        </button>
        <button
          className="mobile-close"
          aria-label="Fermer le menu"
          onClick={() => setOpen(false)}
        >
          <X size={20} />
        </button>
        <nav>
          {links.map((item, i) => (
            <div key={item.path}>
              {i === 0 && <span className="nav-label">VUE D’ENSEMBLE</span>}
              {i === 1 && <span className="nav-label">OPÉRATIONS</span>}
              {i === 5 && <span className="nav-label">COMMUNAUTÉ</span>}
              {i === 7 && <span className="nav-label">OUTILS</span>}
              <NavLink
                to={item.path}
                aria-label={item.label}
                className={({ isActive }) =>
                  isActive ||
                  (item.path === "/users" &&
                    ["/payments", "/payment-reviews"].includes(
                      location.pathname,
                    ))
                    ? "active"
                    : ""
                }
              >
                <item.icon size={20} />
                <span>{item.label}</span>
              </NavLink>
            </div>
          ))}
        </nav>
      </aside>
      <div className="workspace">
        {location.pathname !== "/dashboard" &&
          location.pathname !== "/support-inbox" && (
            <header
              className={`section-header ${["/users", "/payments", "/payment-reviews"].includes(location.pathname) ? "members-section-header" : ""}`}
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
                : ["/users", "/payments", "/payment-reviews"].includes(
                      location.pathname,
                    )
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
              {["/users", "/payments", "/payment-reviews"].map((path) => (
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
                          className={theme === "light" ? "active" : ""}
                          onClick={() => setTheme("light")}
                        >
                          <Sun size={18} />
                          Clair
                        </button>
                        <button
                          className={theme === "dark" ? "active" : ""}
                          onClick={() => setTheme("dark")}
                        >
                          <Moon size={18} />
                          Sombre
                        </button>
                      </div>
                    </Panel>
                    <Panel title="Sécurité">
                      <button
                        className="danger"
                        disabled={action.busy}
                        onClick={() => {
                          if (confirm("Se déconnecter ?"))
                            void action.run(logout, "");
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
        {[
          { ...links[0], label: "Accueil" },
          links[1],
          links[3],
          { ...links[6], label: "Membres" },
        ].map((item) => (
          <NavLink key={item.path} to={item.path}>
            <item.icon size={23} />
            <span>{item.label}</span>
          </NavLink>
        ))}
        <button
          aria-label="Ouvrir le menu"
          aria-expanded={open}
          onClick={() => setOpen(true)}
        >
          <Menu size={23} />
          <span>Menu</span>
        </button>
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
