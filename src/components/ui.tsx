import {
  useLayoutEffect,
  useRef,
  useState,
  type ReactNode,
  type FormEvent,
} from "react";
import { X, LoaderCircle } from "lucide-react";
import { errorMessage } from "../services/data";
export function Status({
  loading,
  error,
  empty,
}: {
  loading?: boolean;
  error?: string;
  empty?: boolean;
}) {
  if (error)
    return (
      <p className="error" role="alert">
        {error}
      </p>
    );
  if (loading)
    return (
      <div className="empty" role="status">
        <LoaderCircle className="spin" size={22} /> Chargement…
      </div>
    );
  if (empty) return <p className="empty">Aucun élément</p>;
  return null;
}
export function Panel({
  title,
  action,
  children,
}: {
  title?: string;
  action?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="panel">
      {(title || action) && (
        <div className="panel-heading">
          <h2>{title}</h2>
          {action}
        </div>
      )}
      {children}
    </section>
  );
}
export function Field({
  label,
  children,
}: {
  label: string;
  children: ReactNode;
}) {
  return (
    <label className="field">
      <span>{label}</span>
      {children}
    </label>
  );
}
export function Submit({
  busy,
  disabled = false,
  children = "Enregistrer",
}: {
  busy: boolean;
  disabled?: boolean;
  children?: ReactNode;
}) {
  return (
    <button className="primary" disabled={busy || disabled} type="submit">
      {busy && <LoaderCircle className="spin" size={16} />} {children}
    </button>
  );
}
export function useAction() {
  const [busy, setBusy] = useState(false),
    [error, setError] = useState(""),
    [success, setSuccess] = useState("");
  const pending = useRef(false);
  async function run(action: () => Promise<unknown>, message = "Enregistré") {
    if (pending.current) return false;
    pending.current = true;
    setBusy(true);
    setError("");
    setSuccess("");
    try {
      await action();
      setSuccess(message);
      return true;
    } catch (e) {
      setError(errorMessage(e));
      return false;
    } finally {
      pending.current = false;
      setBusy(false);
    }
  }
  return {
    busy,
    error,
    success,
    run,
    feedback: (
      <>
        {error && (
          <p className="error" role="alert">
            {error}
          </p>
        )}
        {success && (
          <p className="success" role="status">
            {success}
          </p>
        )}
      </>
    ),
  };
}
export function Modal({
  title,
  onClose,
  children,
  dismissible = true,
}: {
  title: string;
  onClose: () => void;
  children: ReactNode;
  dismissible?: boolean;
}) {
  const dialog = useRef<HTMLDialogElement>(null);
  useLayoutEffect(() => {
    const el = dialog.current;
    el?.showModal();
    return () => el?.close();
  }, []);
  return (
    <dialog
      ref={dialog}
      aria-label={title}
      onCancel={(e) => {
        e.preventDefault();
        if (dismissible) onClose();
      }}
      onClick={(e) => {
        if (dismissible && e.target === dialog.current) onClose();
      }}
    >
      <div className="modal-head">
        <h2>{title}</h2>
        <button aria-label="Fermer" disabled={!dismissible} onClick={onClose}>
          <X size={20} />
        </button>
      </div>
      {children}
    </dialog>
  );
}
export function Form({
  onSubmit,
  children,
}: {
  onSubmit: () => void;
  children: ReactNode;
}) {
  return (
    <form
      onSubmit={(e: FormEvent) => {
        e.preventDefault();
        onSubmit();
      }}
    >
      {children}
    </form>
  );
}
export function Badge({
  children,
  tone = "",
}: {
  children: ReactNode;
  tone?: string;
}) {
  return <span className={`badge ${tone}`}>{children}</span>;
}
