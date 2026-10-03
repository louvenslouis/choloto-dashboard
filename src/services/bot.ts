export type BotNode = {
  id: string;
  parent: string;
  label: string;
  answer: string;
  requiresAuth: boolean;
  requestImage: boolean;
  requestPaymentProof: boolean;
  paymentMethodId: string;
};
export type Plan = {
  id: string;
  name: string;
  amountHtgMinor: number;
  amountUsdMinor: number;
  months: number;
  enabled: boolean;
};
export type Method = {
  id: string;
  name: string;
  currency: string;
  amountMinor: number;
  months: number;
  account: string;
  recipient: string;
  enabled: boolean;
};
export type BotConfig = {
  enabled: boolean;
  greeting: string;
  revision: number;
  nodes: BotNode[];
  plans: Plan[];
  paymentMethods: Method[];
};
export const initialBot: BotConfig = {
  enabled: true,
  greeting: "Bonjour ! Comment pouvons-nous vous aider ?",
  revision: 0,
  nodes: [
    {
      id: "help",
      parent: "",
      label: "Contacter le support",
      answer: "Écrivez votre message.",
      requiresAuth: false,
      requestImage: false,
      requestPaymentProof: false,
      paymentMethodId: "",
    },
  ],
  plans: [],
  paymentMethods: [],
};
export function validateBot(config: BotConfig): BotConfig {
  if (
    !config.greeting.trim() ||
    config.greeting.length > 1000 ||
    !config.nodes.length ||
    config.nodes.length > 80 ||
    config.plans.length > 30 ||
    config.paymentMethods.length > 20
  )
    throw new Error("Vérifiez les limites du bot.");
  const ids = new Set(config.nodes.map((n) => n.id));
  if (ids.size !== config.nodes.length)
    throw new Error("Identifiants de rubriques en double.");
  for (const n of config.nodes) {
    if (
      !/^[a-zA-Z0-9_-]{1,80}$/.test(n.id) ||
      !n.label.trim() ||
      n.label.length > 100 ||
      !n.answer.trim() ||
      n.answer.length > 1500
    )
      throw new Error("Rubrique invalide.");
    const visited = new Set([n.id]);
    let parent = n.parent;
    while (parent) {
      if (!ids.has(parent) || visited.has(parent) || visited.size >= 6)
        throw new Error("La hiérarchie des rubriques est invalide.");
      visited.add(parent);
      parent = config.nodes.find((node) => node.id === parent)!.parent;
    }
    if (
      n.paymentMethodId &&
      !config.paymentMethods.some((m) => m.id === n.paymentMethodId)
    )
      throw new Error("Moyen de paiement de rubrique introuvable.");
  }
  for (const plan of config.plans)
    if (
      !plan.name.trim() ||
      !Number.isInteger(plan.months) ||
      plan.months < 1 ||
      plan.months > 36 ||
      !Number.isInteger(plan.amountHtgMinor) ||
      !Number.isInteger(plan.amountUsdMinor) ||
      plan.amountHtgMinor < 0 ||
      plan.amountUsdMinor < 0 ||
      plan.amountHtgMinor > 100000000 ||
      plan.amountUsdMinor > 100000000 ||
      (plan.enabled && (!plan.amountHtgMinor || !plan.amountUsdMinor))
    )
      throw new Error("Plan invalide.");
  if (
    new Set(config.plans.map((p) => p.id)).size !== config.plans.length ||
    new Set(config.paymentMethods.map((m) => m.id)).size !==
      config.paymentMethods.length
  )
    throw new Error("Identifiants dupliqués.");
  if (new TextEncoder().encode(JSON.stringify(config)).length > 180000)
    throw new Error("Arborescence trop volumineuse.");
  const enabled = config.plans
    .filter((p) => p.enabled)
    .sort((a, b) => a.months - b.months);
  const methods = config.paymentMethods.map((method) => {
    if (!method.enabled) return method;
    let result = { ...method };
    if (config.plans.length) {
      if (!enabled.length) throw new Error("Ajoutez un plan actif.");
      const shortest = enabled.filter((p) => p.months === enabled[0].months),
        amounts = shortest.map((p) =>
          method.currency === "USD" ? p.amountUsdMinor : p.amountHtgMinor,
        );
      if (new Set(amounts).size > 1)
        throw new Error("Harmonisez les prix des plans de même durée.");
      result = {
        ...method,
        months: shortest[0].months,
        amountMinor: amounts[0],
      };
    }
    if (
      !["HTG", "USD"].includes(result.currency) ||
      !result.account.trim() ||
      !result.recipient.trim() ||
      result.amountMinor <= 0 ||
      !Number.isInteger(result.amountMinor) ||
      result.months < 1
    )
      throw new Error("Complétez les moyens de paiement actifs.");
    return result;
  });
  return {
    ...config,
    greeting: config.greeting.trim(),
    paymentMethods: methods,
  };
}
