import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import { useMatch } from "react-router-dom";
import { useCollection } from "./data";

const retention = 30 * 60_000;
const Directory = createContext<
  (ReturnType<typeof useCollection> & { refresh: () => void }) | null
>(null);

export function MemberDirectoryProvider({ children }: { children: ReactNode }) {
  const open = Boolean(useMatch("/users"));
  const [retained, setRetained] = useState(open);
  const [revision, setRevision] = useState(0);
  const state = useCollection(
    open || retained ? "user" : null,
    "",
    0,
    0,
    "",
    "",
    revision,
  );

  useEffect(() => {
    if (open) {
      setRetained(true);
    } else if (retained) {
      const timer = setTimeout(() => setRetained(false), retention);
      return () => clearTimeout(timer);
    }
  }, [open, retained]);

  return (
    <Directory.Provider
      value={{ ...state, refresh: () => setRevision((v) => v + 1) }}
    >
      {children}
    </Directory.Provider>
  );
}

export function useMemberDirectory() {
  const directory = useContext(Directory);
  if (!directory) throw new Error("MemberDirectoryProvider manquant");
  return directory;
}
