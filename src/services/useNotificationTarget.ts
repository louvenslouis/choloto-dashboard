import { useSearchParams } from "react-router-dom";
import { useDocument, type Row } from "./data";

export function useNotificationTarget(
  parameter: string,
  collection: string,
  rows: Row[],
) {
  const [params, setParams] = useSearchParams();
  const raw = params.get(parameter);
  const id =
    raw &&
    !raw.includes("/") &&
    raw !== "." &&
    raw !== ".." &&
    new TextEncoder().encode(raw).length <= 1500
      ? raw
      : null;
  const listed = rows.find((row) => row.id === id);
  const lookup = useDocument(id && !listed ? collection + "/" + id : null);
  const row = listed ?? (id && lookup.data?.id === id ? lookup.data : null);
  function select(value: string | null) {
    setParams(
      (previous) => {
        const next = new URLSearchParams(previous);
        if (value) next.set(parameter, value);
        else next.delete(parameter);
        return next;
      },
      { replace: true },
    );
  }
  return {
    id,
    row,
    select,
    error:
      id && !row && !lookup.loading
        ? lookup.error || "Ce dossier n’est plus disponible."
        : "",
  };
}
