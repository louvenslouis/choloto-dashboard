import { useEffect, useState } from "react";
import { doc, onSnapshot, runTransaction } from "firebase/firestore";
import { db } from "./firebase";

export type VipBadgeTier = { name: string; days: number };

export const defaultVipBadgeTiers: VipBadgeTier[] = [
  { name: "Nouveau Membre CHOLOTO", days: 0 },
  { name: "Membre initié CHOLOTO", days: 30 },
  { name: "Membre Discipliné CHOLOTO", days: 60 },
  { name: "Membre Visionnaire CHOLOTO", days: 180 },
  { name: "Membre Loyal CHOLOTO", days: 365 },
  { name: "Membre Empereur CHOLOTO", days: 730 },
  { name: "Membre Légende CHOLOTO", days: 1095 },
  { name: "Membre Ténor CHOLOTO", days: 1460 },
];

const configRef = () => doc(db, "vip_badges", "config");

export function validateVipBadgeTiers(value: unknown): VipBadgeTier[] {
  if (!Array.isArray(value) || value.length !== defaultVipBadgeTiers.length)
    throw new Error("Les huit badges sont requis.");
  let previous = -1;
  return value.map((tier, index) => {
    const name = typeof tier?.name === "string" ? tier.name.trim() : "";
    const days = tier?.days;
    if (!name || name.length > 80)
      throw new Error(`Vérifiez le nom du badge ${index + 1}.`);
    if (index === 0 && days !== 0)
      throw new Error("Le premier badge est attribué à l’inscription.");
    if (!Number.isInteger(days) || days <= previous || days > 36500)
      throw new Error(
        `Le seuil de « ${name} » doit être un entier entre ${previous + 1} et 36 500 jours.`,
      );
    previous = days;
    return { name, days };
  });
}

export function sameVipBadgeTiers(a: VipBadgeTier[], b: VipBadgeTier[]) {
  return (
    a.length === b.length &&
    a.every((tier, i) => tier.name === b[i].name && tier.days === b[i].days)
  );
}

export function useVipBadgeTiers() {
  const [state, setState] = useState<{
    tiers: VipBadgeTier[];
    loading: boolean;
    error: string;
  }>({
    tiers: [],
    loading: true,
    error: "",
  });
  useEffect(
    () =>
      onSnapshot(
        configRef(),
        { includeMetadataChanges: true },
        (snapshot) => {
          if (
            snapshot.metadata?.fromCache ||
            snapshot.metadata?.hasPendingWrites
          )
            return;
          try {
            const tiers = snapshot.exists()
              ? validateVipBadgeTiers(snapshot.data().tiers)
              : defaultVipBadgeTiers;
            setState({ tiers, loading: false, error: "" });
          } catch (error) {
            setState({
              tiers: [],
              loading: false,
              error:
                error instanceof Error
                  ? error.message
                  : "Badges VIP invalides.",
            });
          }
        },
        (error) =>
          setState({ tiers: [], loading: false, error: error.message }),
      ),
    [],
  );
  return state;
}

export async function saveVipBadgeTiers(
  previous: VipBadgeTier[],
  draft: VipBadgeTier[],
) {
  const tiers = validateVipBadgeTiers(draft);
  const ref = configRef();
  await runTransaction(db, async (tx) => {
    const snapshot = await tx.get(ref);
    const stored = snapshot.exists()
      ? validateVipBadgeTiers(snapshot.data().tiers)
      : defaultVipBadgeTiers;
    if (!sameVipBadgeTiers(previous, stored))
      throw new Error(
        "Les badges ont été modifiés ailleurs. Rechargez les règles avant d’enregistrer.",
      );
    tx.set(ref, { tiers });
  });
}
