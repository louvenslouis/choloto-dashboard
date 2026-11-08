import { useState } from "react";
import { Award } from "lucide-react";
import { Form, Modal, Panel, Status, Submit, useAction } from "./ui";
import {
  sameVipBadgeTiers,
  saveVipBadgeTiers,
  useVipBadgeTiers,
  type VipBadgeTier,
} from "../services/vipBadges";
import "./vipBadgeSettings.css";

function BadgeEditor({ onClose }: { onClose: () => void }) {
  const { tiers, loading, error } = useVipBadgeTiers();
  const [draft, setDraft] = useState<{
    previous: VipBadgeTier[];
    tiers: VipBadgeTier[];
  } | null>(null);
  const [feedback, setFeedback] = useState("");
  const action = useAction();
  const shown = draft?.tiers ?? tiers;
  const stale = !!draft && !sameVipBadgeTiers(draft.previous, tiers);

  function edit(index: number, update: Partial<VipBadgeTier>) {
    setFeedback("");
    setDraft({
      previous: draft?.previous ?? tiers,
      tiers: shown.map((tier, i) =>
        i === index ? { ...tier, ...update } : tier,
      ),
    });
  }

  return (
    <Modal title="Badges VIP" onClose={onClose} dismissible={!action.busy}>
      <Status loading={loading} error={error} />
      {!loading && !error && (
        <Form
          onSubmit={() => {
            if (!draft || stale) return;
            void action.run(async () => {
              try {
                await saveVipBadgeTiers(draft.previous, draft.tiers);
                onClose();
              } catch (cause) {
                setFeedback(
                  cause instanceof Error
                    ? cause.message
                    : "Enregistrement impossible.",
                );
              }
            }, "");
          }}
        >
          <fieldset className="vip-badge-fields" disabled={action.busy}>
            <div className="vip-badge-fields-heading" aria-hidden="true">
              <strong>Nom du badge</strong>
              <strong>Jours VIP</strong>
            </div>
            {shown.map((tier, i) => (
              <div className="vip-badge-fields-row" key={i}>
                <input
                  type="text"
                  aria-label={`Nom du badge ${i + 1}`}
                  value={tier.name}
                  required
                  maxLength={80}
                  onChange={(e) => edit(i, { name: e.target.value })}
                />
                <input
                  type="number"
                  aria-label={`Jours VIP du badge ${i + 1}`}
                  value={Number.isNaN(tier.days) ? "" : tier.days}
                  min={i === 0 ? 0 : 1}
                  max={36500}
                  step={1}
                  required
                  readOnly={i === 0}
                  onChange={(e) => edit(i, { days: e.target.valueAsNumber })}
                />
              </div>
            ))}
          </fieldset>
          <Status
            error={
              stale
                ? "Les badges ont été modifiés ailleurs. Rechargez les règles avant d’enregistrer."
                : feedback
            }
          />
          <div className="form-actions">
            {(stale || feedback) && (
              <button
                type="button"
                disabled={action.busy}
                onClick={() => {
                  setDraft(null);
                  setFeedback("");
                }}
              >
                Recharger les règles
              </button>
            )}
            <Submit
              busy={action.busy}
              disabled={!draft || stale || sameVipBadgeTiers(shown, tiers)}
            />
          </div>
        </Form>
      )}
    </Modal>
  );
}

export default function VipBadgeSettings() {
  const [open, setOpen] = useState(false);
  return (
    <Panel title="Badges VIP">
      <button type="button" onClick={() => setOpen(true)}>
        <Award size={18} />
        Modifier les badges
      </button>
      {open && <BadgeEditor onClose={() => setOpen(false)} />}
    </Panel>
  );
}
