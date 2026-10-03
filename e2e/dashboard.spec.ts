import { test, expect } from "@playwright/test";
for (const width of [390, 1440]) {
  test(`navigation et formulaires à ${width}px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 960 });
    const errors: string[] = [];
    page.on("pageerror", (e) => errors.push(e.message));
    await page.route(/https:\/\/(?!fonts\.).*/, (route) => route.abort());
    await page.goto("/dashboard");
    await expect(
      page.getByRole("heading", { name: "Aujourd’hui" }),
    ).toBeVisible();
    await expect(
      page.getByRole("link", { name: /Paiements à traiter/ }),
    ).toBeVisible();
    if (width < 992) {
      await page
        .getByRole("button", { name: "Statistiques", exact: true })
        .click();
      await expect(
        page.getByText("Bingo mensuel", { exact: true }),
      ).toBeVisible();
      await page.screenshot({
        path: `test-results/statistics-${width}.png`,
        fullPage: true,
      });
      await page
        .getByRole("button", { name: "À traiter", exact: true })
        .click();
    }
    await page.screenshot({
      path: `test-results/dashboard-${width}.png`,
      fullPage: true,
    });
    if (width >= 992) {
      await page.getByRole("button", { name: "Réduire le menu" }).click();
      await expect(page.locator(".app")).toHaveClass(/sidebar-collapsed/);
      await page.getByRole("button", { name: "Développer le menu" }).click();
    }
    for (const [path, title] of [
      ["/tirages", "Résultats officiels"],
      ["/predictions", "Prédictions"],
      ["/publications", "Publication BINGO"],
      ["/croix", "Croix de la chance"],
      ["/users", "Membres & Paiements"],
      ["/payment-reviews", "Paiements à vérifier"],
      ["/payments", "Transactions"],
      ["/support-inbox", "Conversations"],
      ["/settings", "Apparence"],
    ]) {
      await page.goto(path);
      await expect(
        page.getByRole("heading", { name: title, exact: true }).last(),
      ).toBeVisible();
      expect(
        await page.evaluate(
          () => document.documentElement.scrollWidth <= window.innerWidth,
        ),
      ).toBe(true);
    }
    await page.goto("/users");
    await expect(page.locator(".member-card")).toHaveCount(1);
    await page.getByRole("button", { name: "Vue liste", exact: true }).click();
    await expect(
      page.getByRole("columnheader", { name: "Membre", exact: true }),
    ).toBeVisible();
    await page.getByRole("button", { name: "Vue cartes", exact: true }).click();
    await page.screenshot({
      path: `test-results/members-${width}.png`,
      fullPage: true,
    });
    await page.getByRole("button", { name: "Paiement", exact: true }).click();
    await expect(page.getByRole("dialog")).toBeVisible();
    await expect(page.getByLabel("Montant", { exact: true })).toBeVisible();
    await page.goto("/predictions");
    await page
      .getByRole("textbox", { name: "BOLOTO 1", exact: true })
      .fill("12");
    await expect(
      page.getByRole("textbox", { name: "BOLOTO 1", exact: true }),
    ).toHaveValue("12");
    await page.screenshot({
      path: `test-results/predictions-${width}.png`,
      fullPage: true,
    });
    await page.getByRole("button", { name: "Publier", exact: true }).click();
    await expect(page.getByRole("alert")).toContainText("Écriture désactivée");
    await expect(
      page.getByRole("textbox", { name: "BOLOTO 1", exact: true }),
    ).toHaveValue("12");
    await page.goto("/support-inbox");
    await page.getByRole("button", { name: /Membre Test/ }).click();
    await expect(
      page.getByRole("textbox", { name: "Message", exact: true }),
    ).toBeVisible();
    await page.screenshot({
      path: `test-results/support-${width}.png`,
      fullPage: true,
    });
    if (width < 850) {
      await page.getByRole("button", { name: "Ouvrir le menu" }).click();
      await page.getByRole("link", { name: "Paramètres", exact: true }).click();
      await expect(
        page.getByRole("heading", { name: "Apparence" }),
      ).toBeVisible();
    }
    await page.goto("/settings");
    await page.getByRole("button", { name: "Sombre", exact: true }).click();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    expect(errors).toEqual([]);
  });
}

test("export Excel des membres", async ({ page }) => {
  await page.route(/https:\/\/(?!fonts\.).*/, (route) => route.abort());
  await page.goto("/users");
  await expect(page.getByText("membre@example.test").first()).toBeVisible();
  const downloadPromise = page.waitForEvent("download");
  await page.getByRole("button", { name: "Exporter Excel" }).click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toMatch(/membres-choloto-.*\.xlsx$/);
  const path = await download.path();
  const { createRequire } = await import("node:module");
  const ExcelJS = createRequire(import.meta.url)("exceljs");
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(path!);
  expect(workbook.getWorksheet("Membres")!.getCell("B2").value).toBe(
    "membre@example.test",
  );
});
