import { useState } from "react";
import { createPortal } from "react-dom";
import type { VipBadgeTier } from "../services/vipBadges";
import { Modal } from "./ui";
import "./vipMedal.css";

type Props = {
  rank: number;
  tier: VipBadgeTier;
  duration?: string;
  retained?: boolean;
  disabled?: boolean;
};

export default function VipMedal({
  rank,
  tier,
  duration,
  retained,
  disabled,
}: Props) {
  const [open, setOpen] = useState(false);
  const src = `${import.meta.env.BASE_URL}vip-badges/rank-${rank + 1}.webp`;
  const threshold =
    tier.days === 0
      ? "Dès l’activation VIP"
      : `${tier.days.toLocaleString("fr-FR")} jour${tier.days > 1 ? "s" : ""} VIP`;

  return (
    <>
      <button
        type="button"
        disabled={disabled}
        className="vip-medal-button"
        aria-label={`Ouvrir le badge ${tier.name}`}
        aria-haspopup="dialog"
        title={tier.name}
        onClick={() => setOpen(true)}
      >
        <img
          className={retained ? "vip-medal-retained" : undefined}
          src={src}
          alt=""
          width={44}
          height={44}
          loading="lazy"
        />
      </button>
      {open &&
        createPortal(
          <Modal title={tier.name} onClose={() => setOpen(false)}>
            <div className="vip-medal-details" data-rank={rank + 1}>
              <div
                className={
                  retained
                    ? "vip-medal-display vip-medal-retained"
                    : "vip-medal-display"
                }
              >
                <img src={src} alt="" width={164} height={164} />
              </div>
              <dl>
                <div>
                  <dt>Attribution</dt>
                  <dd>{threshold}</dd>
                </div>
                {duration && (
                  <div>
                    <dt>Durée VIP du membre</dt>
                    <dd>{duration}</dd>
                  </div>
                )}
              </dl>
            </div>
          </Modal>,
          document.body,
        )}
    </>
  );
}
