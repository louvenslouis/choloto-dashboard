import { useEffect, useState } from "react";
import { Bell, BellOff } from "lucide-react";
import {
  disablePush,
  enablePush,
  pushAvailable,
  pushEnabled,
} from "../services/adminPush";
import { Panel, Status, useAction } from "./ui";

export default function PushSettings({ uid }: { uid: string }) {
  const [enabled, setEnabled] = useState(false);
  const [loading, setLoading] = useState(true);
  const action = useAction();
  useEffect(() => {
    let mounted = true;
    const update = () => {
      void pushEnabled(uid)
        .then((value) => {
          if (mounted) setEnabled(value);
        })
        .catch(() => {
          if (mounted) setEnabled(false);
        })
        .finally(() => {
          if (mounted) setLoading(false);
        });
    };
    update();
    window.addEventListener("focus", update);
    return () => {
      mounted = false;
      window.removeEventListener("focus", update);
    };
  }, [uid]);
  const ios =
    /iPhone|iPad|iPod/.test(navigator.userAgent) ||
    (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  const needsHomeScreen =
    ios &&
    !window.matchMedia("(display-mode: standalone)").matches &&
    !(navigator as Navigator & { standalone?: boolean }).standalone;
  return (
    <Panel title="Notifications">
      {pushAvailable() && !needsHomeScreen ? (
        <button
          type="button"
          disabled={loading || action.busy}
          onClick={() =>
            void action.run(async () => {
              if (enabled) await disablePush(uid);
              else await enablePush(uid);
              setEnabled(!enabled);
            }, "")
          }
        >
          {enabled ? <BellOff size={18} /> : <Bell size={18} />}
          {enabled ? "Désactiver sur cet appareil" : "Activer sur cet appareil"}
        </button>
      ) : (
        <p>
          {needsHomeScreen
            ? "Ajoutez le dashboard à l’écran d’accueil, puis ouvrez-le depuis son icône."
            : "Notifications indisponibles dans ce navigateur."}
        </p>
      )}
      <Status error={action.error} />
    </Panel>
  );
}
