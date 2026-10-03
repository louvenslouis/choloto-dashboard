import { useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { localDateInput } from "../services/data";
export default function Calendar({
  value,
  onChange,
  min,
}: {
  value: string;
  onChange: (value: string) => void;
  min?: string;
}) {
  const initial = new Date(`${value}T12:00:00`);
  const [month, setMonth] = useState(
    new Date(initial.getFullYear(), initial.getMonth(), 1),
  );
  const offset = (month.getDay() + 6) % 7,
    days = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate();
  return (
    <div className="membership-calendar">
      <div className="calendar-heading">
        <button
          type="button"
          aria-label="Mois précédent"
          onClick={() =>
            setMonth(new Date(month.getFullYear(), month.getMonth() - 1, 1))
          }
        >
          <ChevronLeft size={18} />
        </button>
        <strong>
          {month.toLocaleDateString("fr-FR", {
            month: "long",
            year: "numeric",
          })}
        </strong>
        <button
          type="button"
          aria-label="Mois suivant"
          onClick={() =>
            setMonth(new Date(month.getFullYear(), month.getMonth() + 1, 1))
          }
        >
          <ChevronRight size={18} />
        </button>
      </div>
      <div className="calendar-days">
        {["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"].map((d) => (
          <small key={d}>{d}</small>
        ))}
        {Array.from({ length: offset }, (_, i) => (
          <span key={`blank${i}`} />
        ))}
        {Array.from({ length: days }, (_, i) => {
          const date = localDateInput(
            new Date(month.getFullYear(), month.getMonth(), i + 1),
          );
          return (
            <button
              type="button"
              key={date}
              aria-label={new Date(`${date}T12:00:00`).toLocaleDateString(
                "fr-FR",
                { dateStyle: "full" },
              )}
              aria-pressed={date === value}
              disabled={!!min && date < min}
              className={date === localDateInput() ? "today" : ""}
              onClick={() => onChange(date)}
            >
              {i + 1}
            </button>
          );
        })}
      </div>
      <div className="calendar-selection">
        <small>Nouvelle échéance</small>
        <strong>
          {new Date(`${value}T12:00:00`).toLocaleDateString("fr-FR", {
            dateStyle: "long",
          })}
        </strong>
      </div>
    </div>
  );
}
