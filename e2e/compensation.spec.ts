import { expect, test } from "@playwright/test";

for (const width of [390, 1440]) {
  test(`compensation des membres à ${width}px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 900 });
    await page.route(/https:\/\/(?!fonts\.).*/, (route) => route.abort());
    const errors: string[] = [];
    page.on("pageerror", (error) => errors.push(error.message));
    await page.goto("/users");
    await expect(page.locator(".member-card")).toHaveCount(1);
    await expect(
      page.getByRole("button", { name: "Ajouter un utilisateur" }),
    ).toHaveCount(0);
    if (width < 992)
      await page.getByRole("button", { name: "Actions des membres" }).click();
    await page
      .getByRole("button", { name: "Compensation", exact: true })
      .click();
    await expect(
      page.getByRole("heading", { name: "Compensation", exact: true }),
    ).toBeVisible();
    await expect(page.getByLabel("Bénéficiaires")).toHaveValue("vip");
    await expect(page.getByText("1 membre", { exact: true })).toBeVisible();
    await page.getByLabel("Nombre de jours").fill("3");
    await page.screenshot({
      path: `test-results/compensation-vip-${width}.png`,
    });
    await page.getByLabel("Bénéficiaires").selectOption("selected");
    await expect(
      page.getByRole("button", { name: "Appliquer la compensation" }),
    ).toBeDisabled();
    await page.getByLabel("Rechercher des bénéficiaires").fill("CH-0001");
    await page.getByRole("checkbox", { name: /Membre Test/ }).check();
    await page.getByLabel("Rechercher des bénéficiaires").fill("absent");
    await expect(
      page.getByText("Aucun membre trouvé", { exact: true }),
    ).toBeVisible();
    await expect(page.getByText("1 membre", { exact: true })).toBeVisible();
    await page.getByLabel("Rechercher des bénéficiaires").fill("");
    await page.screenshot({
      path: `test-results/compensation-selection-${width}.png`,
    });
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
    ).toBe(true);
    await page
      .getByRole("button", { name: "Appliquer la compensation" })
      .click();
    // The browser fixture blocks every write; exercise retry against that failure.
    await expect(page.getByRole("alert")).toContainText("Écriture désactivée");
    await expect(page.getByRole("button", { name: "Réessayer" })).toBeEnabled();
    await expect(page.getByLabel("Nombre de jours")).toBeDisabled();
    await page.reload();
    if (width < 992)
      await page.getByRole("button", { name: "Actions des membres" }).click();
    await page
      .getByRole("button", { name: "Compensation", exact: true })
      .click();
    await expect(page.getByLabel("Nombre de jours")).toHaveValue("3");
    await expect(page.getByRole("button", { name: "Réessayer" })).toBeEnabled();
    expect(errors).toEqual([]);
  });

  test(`historique de compensation à ${width}px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 900 });
    await page.route(/https:\/\/(?!fonts\.).*/, (route) => route.abort());
    await page.goto("/payments?compensation-fixture");
    await expect(page.locator(".payment-record")).toHaveCount(2);
    await expect(page.locator(".payment-trend > div > strong")).toHaveText("1");
    await expect(page.locator(".payment-totals")).toHaveText("500 GDS");
    const compensation = page
      .locator(".payment-record")
      .filter({ hasText: "Compensation" });
    await expect(compensation).toHaveCount(1);
    await page.getByLabel("Statut des paiements").selectOption("active");
    await expect(compensation).toHaveCount(0);
    await expect(page.locator(".payment-record")).toHaveCount(1);
    await page.getByLabel("Statut des paiements").selectOption("all");
    await compensation
      .getByRole("button", { name: "Reçu", exact: true })
      .click();
    await expect(
      page.getByRole("heading", { name: "Compensation", exact: true }),
    ).toBeVisible();
    await expect(
      page.getByRole("heading", { name: "Sans frais", exact: true }),
    ).toBeVisible();
    const dialog = page.getByRole("dialog");
    expect(
      await dialog.evaluate((el) => el.scrollWidth <= el.clientWidth),
    ).toBe(true);
  });
}
