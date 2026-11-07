import { test, expect } from "@playwright/test";

for (const width of [390, 1440]) {
  test(`édition du BINGO et conservation du brouillon à ${width}px`, async ({
    page,
  }) => {
    await page.setViewportSize({ width, height: 960 });
    await page.route(/https:\/\/(?!fonts\.).*/, (route) => route.abort());
    const errors: string[] = [];
    page.on("pageerror", (error) => errors.push(error.message));
    await page.goto("/publications");
    const editor = page.locator(".bingo-composer");
    const results = editor.locator(".bingo-result");
    await expect(results).toHaveCount(1);
    await expect(
      editor.getByRole("button", { name: "Retirer le résultat 1" }),
    ).toBeDisabled();
    await editor.getByRole("button", { name: "Publier le BINGO" }).click();
    await expect(
      results.first().getByLabel("Numéro", { exact: true }),
    ).toBeFocused();
    await expect(page.getByRole("alert")).toHaveCount(0);

    await results.first().getByLabel("Numéro", { exact: true }).fill("07");
    await results
      .first()
      .getByLabel("Tirage", { exact: true })
      .selectOption("GEORGIA");
    await results
      .first()
      .getByRole("button", { name: "Soir", exact: true })
      .click();
    await page.screenshot({
      path: `test-results/bingo-editor-${width}.png`,
      fullPage: true,
    });

    await editor.getByRole("button", { name: "Ajouter un résultat" }).click();
    await expect(results).toHaveCount(2);
    await expect(
      results.nth(1).getByLabel("Numéro", { exact: true }),
    ).toBeFocused();
    await expect(
      results.nth(1).getByLabel("Tirage", { exact: true }),
    ).toHaveValue("GEORGIA");
    await expect(
      results.nth(1).getByRole("button", { name: "Soir", exact: true }),
    ).toHaveAttribute("aria-pressed", "true");
    await results.nth(1).getByLabel("Numéro", { exact: true }).fill("123");
    await results
      .nth(1)
      .getByLabel("Lot", { exact: true })
      .selectOption("LOTO 3");
    await editor.getByRole("button", { name: "Retirer le résultat 1" }).click();
    await expect(results).toHaveCount(1);
    await expect(
      results.first().getByLabel("Numéro", { exact: true }),
    ).toHaveValue("123");
    await expect(
      results.first().getByLabel("Numéro", { exact: true }),
    ).toBeFocused();

    const navigation = page.getByRole("navigation", {
      name: "Publications BINGO",
      exact: true,
    });
    await navigation
      .getByRole("button", { name: "Historique", exact: true })
      .click();
    await expect(
      page.getByRole("heading", { name: "Historique des publications" }),
    ).toBeVisible();
    await navigation
      .getByRole("button", { name: "Nouvelle publication", exact: true })
      .click();
    await expect(
      results.first().getByLabel("Numéro", { exact: true }),
    ).toHaveValue("123");
    await editor.getByRole("button", { name: "Publier le BINGO" }).click();
    await expect(page.getByRole("alert")).toContainText("Écriture désactivée");
    await expect(
      results.first().getByLabel("Numéro", { exact: true }),
    ).toHaveValue("123");

    await page
      .getByRole("switch", { name: "Activer les BINGO proposés" })
      .click();
    await expect(
      page.getByText("Aucun BINGO proposé", { exact: true }),
    ).toBeVisible();
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
    ).toBe(true);
    await page.evaluate(() => {
      localStorage.setItem("choloto-theme", "dark");
    });
    await page.reload();
    await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
    await expect(
      editor.getByRole("heading", { name: "Publication BINGO" }),
    ).toBeVisible();
    await results.first().getByLabel("Numéro", { exact: true }).fill("07");
    await page.screenshot({
      path: `test-results/bingo-dark-${width}.png`,
      fullPage: true,
    });

    await page.goto("/publications/history");
    await page.getByRole("button", { name: "Modifier", exact: true }).click();
    const dialog = page.getByRole("dialog");
    await expect(dialog.getByLabel("Numéro", { exact: true })).toHaveValue(
      "31",
    );
    await dialog.getByLabel("Numéro", { exact: true }).fill("04");
    await dialog
      .getByRole("button", { name: "Enregistrer", exact: true })
      .click();
    await expect(dialog.getByRole("alert")).toContainText(
      "Écriture désactivée",
    );
    await expect(dialog.getByLabel("Numéro", { exact: true })).toHaveValue(
      "04",
    );
    await page.screenshot({
      path: `test-results/bingo-edit-modal-${width}.png`,
      fullPage: true,
    });
    expect(errors).toEqual([]);
  });
}

test("le BINGO reste lisible sur les petits écrans et aux largeurs intermédiaires", async ({
  page,
}) => {
  await page.route(/https:\/\/(?!fonts\.).*/, (route) => route.abort());
  await page.goto("/publications");
  const editor = page.locator(".bingo-composer");
  await editor
    .getByLabel("Numéro", { exact: true })
    .fill("12-34-56-78-90-12-34-56-78-90");
  for (const width of [320, 768, 1024]) {
    await page.setViewportSize({ width, height: 960 });
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
    ).toBe(true);
    await page.screenshot({
      path: `test-results/bingo-responsive-${width}.png`,
      fullPage: true,
    });
  }
});
