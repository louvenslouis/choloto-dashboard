import { expect, test } from "@playwright/test";

for (const width of [390, 1280]) {
  test(`badges VIP des conversations et du chat à ${width}px`, async ({
    page,
  }) => {
    await page.setViewportSize({ width, height: 844 });
    await page.route(/^https:/, (route) => route.abort());
    await page.goto(
      "/support-inbox?vip-duration-fixture&free-badge-fixture&support-badge-fixture",
    );
    const card = (label: string) =>
      page
        .locator(".support-conversation")
        .filter({ has: page.getByText(label, { exact: true }) });
    const active = card("Membre Test");
    const former = card("Profil ancien 14 jours et une heure");
    const medal = (label: string) => ({ name: `Ouvrir le badge ${label}` });
    const activeRank = "Membre initié CHOLOTO";
    const formerRank = "Nouveau Membre CHOLOTO";
    await expect(
      active.getByRole("button", medal(activeRank)).locator("img"),
    ).toHaveCSS("filter", "none");
    await expect(
      former.getByRole("button", medal(formerRank)).locator("img"),
    ).toHaveCSS("filter", "grayscale(1)");
    for (const label of [
      "Profil gratuit",
      "Profil ancien 14 jours",
      "Visiteur anonyme",
    ]) {
      await expect(card(label)).toBeVisible();
      await expect(
        card(label).getByRole("button", { name: /Ouvrir le badge/ }),
      ).toHaveCount(0);
    }
    await active.getByRole("button", medal(activeRank)).click();
    const detail = page.getByRole("dialog", { name: activeRank });
    await expect(detail.getByText("1 mois 5 j")).toBeVisible();
    await expect(page.locator(".support-chat")).toHaveCount(0);
    await page.keyboard.press("Escape");
    await expect(active.getByRole("button", medal(activeRank))).toBeFocused();
    await former.getByRole("button", { name: /Profil ancien/ }).click();
    const chat = page.locator(".support-chat");
    await chat
      .getByRole("textbox", { name: "Message", exact: true })
      .fill("Réponse en cours");
    await chat.getByRole("button", medal(formerRank)).click();
    await expect(
      page
        .getByRole("dialog", { name: formerRank })
        .locator(".vip-medal-display"),
    ).toHaveCSS("filter", "grayscale(1)");
    await page.keyboard.press("Escape");
    await expect(
      chat.getByRole("textbox", { name: "Message", exact: true }),
    ).toHaveValue("Réponse en cours");
  });
}
