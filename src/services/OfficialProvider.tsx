import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import {
  collection,
  getDocsFromServer,
  query,
  where,
  Timestamp,
} from "firebase/firestore";
import { auth, db } from "./firebase";
import { fetchOfficial } from "./official";
import {
  publishOfficial,
  matchesPublished,
  type Proposal,
} from "./publications";
import { errorMessage } from "./data";
type State = {
  proposals: Proposal[];
  warnings: string[];
  published: Set<string>;
  loading: boolean;
  automatic: boolean;
  setAutomatic: (value: boolean) => void;
  refresh: () => Promise<void>;
};
const Context = createContext<State | null>(null);
export function OfficialProvider({
  children,
  uid,
}: {
  children: ReactNode;
  uid: string;
}) {
  const key = `choloto-auto-publication-${uid}`;
  const [automatic, setAutomaticState] = useState(
      () =>
        (localStorage.getItem(key) ??
          localStorage.getItem(
            `flutter.tirages_automatic_publication_${uid}`,
          )) === "true",
    ),
    [proposals, setProposals] = useState<Proposal[]>([]),
    [warnings, setWarnings] = useState<string[]>([]),
    [published, setPublished] = useState(new Set<string>()),
    [loading, setLoading] = useState(false);
  const auto = useRef(automatic),
    pending = useRef(false),
    mounted = useRef(false);
  const refresh = useCallback(async () => {
    if (pending.current) return;
    pending.current = true;
    setLoading(true);
    try {
      const result = await fetchOfficial();
      if (!mounted.current || auth.currentUser?.uid !== uid) return;
      setProposals(result.proposals);
      setWarnings(result.warnings);
      if (!result.proposals.length) return;
      // Server reads are mandatory before automatic writes: cached history can miss legacy records.
      const since = Math.min(
        ...result.proposals.map((p) => {
          const midnight = new Date(p.date);
          midnight.setHours(0, 0, 0, 0);
          return Math.min(midnight.getTime(), p.date.getTime() - 18 * 3600000);
        }),
      );
      const history = await getDocsFromServer(
        query(
          collection(db, "resultats"),
          where("date", ">=", Timestamp.fromMillis(since)),
        ),
      );
      if (!mounted.current || auth.currentUser?.uid !== uid) return;
      const ids = new Set<string>();
      for (const p of result.proposals)
        if (
          history.docs.some((d) =>
            matchesPublished({ ...d.data(), id: d.id }, p),
          )
        )
          ids.add(p.id);
      setPublished(ids);
      for (const p of result.proposals) {
        if (!mounted.current || !auto.current || auth.currentUser?.uid !== uid)
          break;
        if (!ids.has(p.id)) {
          await publishOfficial(p, true);
          ids.add(p.id);
          setPublished(new Set(ids));
        }
      }
    } catch (error) {
      if (mounted.current)
        setWarnings((previous) => [
          ...previous,
          `Publication automatique suspendue : ${errorMessage(error)}`,
        ]);
    } finally {
      pending.current = false;
      if (mounted.current) setLoading(false);
    }
  }, [uid]);
  useEffect(() => {
    mounted.current = true;
    void refresh();
    const timer = setInterval(() => void refresh(), 600000);
    const wake = () => {
      if (document.visibilityState === "visible") void refresh();
    };
    document.addEventListener("visibilitychange", wake);
    return () => {
      mounted.current = false;
      clearInterval(timer);
      document.removeEventListener("visibilitychange", wake);
    };
  }, [refresh]);
  function setAutomatic(value: boolean) {
    auto.current = value;
    setAutomaticState(value);
    localStorage.setItem(key, String(value));
    if (value) void refresh();
  }
  return (
    <Context.Provider
      value={{
        proposals,
        warnings,
        published,
        loading,
        automatic,
        setAutomatic,
        refresh,
      }}
    >
      {children}
    </Context.Provider>
  );
}
export function useOfficial() {
  const context = useContext(Context);
  if (!context) throw new Error("OfficialProvider manquant");
  return context;
}
