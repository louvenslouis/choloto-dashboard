import { test, expect } from "@playwright/test";
for (const width of [390, 1440])
  test(`écrans restaurés ${width}`, async ({ page }) => {
    await page.setViewportSize({ width, height: 960 });
    await page.route(/https:\/\/(?!fonts\.).*/, (route) => route.abort());
    const errors: string[] = [];
    page.on("pageerror", (e) => errors.push(e.message));
    for (const path of [
      "predictions",
      "croix",
      "publications",
      "publications/history",
      "payments",
      "payment-reviews",
      "settings",
    ]) {
      await page.goto(`/${path}`);
      await expect(page.locator("#main-content")).toBeVisible();
      await expect(page.locator("#main-content .spin")).toHaveCount(0);
      expect(
        await page.evaluate(
          () => document.documentElement.scrollWidth <= innerWidth,
        ),
      ).toBe(true);
      await page.screenshot({
        path: `test-results/parity-${path.replaceAll("/", "-")}-${width}.png`,
        fullPage: true,
      });
    }
    await page.goto("/croix");
    for (let i = 1; i <= 8; i++)
      await page
        .getByRole("textbox", { name: `Numéro ${i}`, exact: true })
        .fill(String(i + 10));
    await page.getByRole("button", { name: "Publier la mise à jour" }).click();
    await expect(
      page.getByRole("heading", { name: "Vérifier la publication" }),
    ).toBeVisible();
    await page.getByRole("button", { name: "Annuler", exact: true }).click();
    await expect(
      page.getByRole("textbox", { name: "Numéro 1", exact: true }),
    ).toHaveValue("11");
    await page.goto("/publications/history");
    await page.getByRole("button", { name: /réactions/ }).click();
    await expect(
      page.getByRole("heading", { name: "Réactions au BINGO" }),
    ).toBeVisible();
    await expect(page.getByText("Membre Test", { exact: true })).toBeVisible();
    await page.getByRole("button", { name: "Fermer", exact: true }).click();
    await page.goto("/support-inbox");
    await page
      .getByRole("button", { name: "Bot du service client", exact: true })
      .click();
    await expect(
      page.getByRole("heading", { name: "Le parcours" }),
    ).toBeVisible();
    await page
      .getByRole("button", {
        name: "Modifier Contacter le support",
      })
      .click();
    await page.getByLabel("Titre", { exact: true }).fill("Assistance");
    await page
      .getByRole("button", { name: "Enregistrer", exact: true })
      .click();
    await expect(page.getByText("Modifications non publiées")).toBeVisible();
    await page.screenshot({
      path: `test-results/bot-parity-${width}.png`,
      fullPage: true,
    });
    expect(errors).toEqual([]);
  });
test("téléchargement réel du reçu PDF", async ({ page }) => {
  await page.goto("/payments");
  await page.getByRole("button", { name: "Reçu", exact: true }).click();
  const pending = page.waitForEvent("download");
  await page.getByRole("button", { name: "Télécharger le reçu PDF" }).click();
  const file = await pending;
  await file.saveAs("test-results/receipt.pdf");
  const { createRequire } = await import("node:module");
  const { PDFDocument } = createRequire(import.meta.url)("pdf-lib");
  const fs = await import("node:fs/promises");
  const pdf = await PDFDocument.load(
    await fs.readFile("test-results/receipt.pdf"),
  );
  expect(pdf.getPageCount()).toBe(1);
  expect(pdf.getTitle()).toContain("CH-payment-1");
});
