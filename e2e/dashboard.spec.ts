import { test, expect } from "@playwright/test";
test("prédictions uniquement à midi et le soir", async ({ page }) => {
  await page.goto("/dashboard");
  const status = page.locator('.operation-row[href="/predictions"]');
  // The historical morning record in the fixture covers neither period.
  await expect(status).toContainText("0/2");
  await expect(status).toContainText("Midi · Soir");
  await status.click();
  const choices = page.locator(".period-selector button");
  await expect(choices).toHaveText(["Midi", "Soir"]);
  await expect(choices.first()).toHaveAttribute("aria-pressed", "true");
  await choices.last().click();
  await expect(choices.last()).toHaveAttribute("aria-pressed", "true");
});

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
      ["/support-inbox", "Service client"],
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
    if (width >= 992) {
      await page
        .getByRole("button", { name: "Vue liste", exact: true })
        .click();
      await expect(page.locator(".members-list-heading")).toBeVisible();
      await page
        .getByRole("button", { name: "Vue cartes", exact: true })
        .click();
    } else {
      await page.getByRole("button", { name: "Filtres et tri" }).click();
    }
    await page.getByRole("button", { name: /^Gratuit/ }).click();
    if (width < 992)
      await page.getByRole("button", { name: "Appliquer" }).click();
    await expect(
      page.getByRole("heading", { name: "Aucun membre trouvé" }),
    ).toBeVisible();
    await page.getByRole("button", { name: "Réinitialiser" }).click();
    await expect(page.locator(".member-card")).toHaveCount(1);
    await expect(page.locator(".new-member")).toBeVisible();
    await page.getByRole("button", { name: /^Membre Test/ }).click();
    await expect(
      page.getByRole("heading", { name: "Profil du membre" }),
    ).toBeVisible();
    await expect(page.getByText("CH-0001", { exact: true })).toBeVisible();
    await expect(
      page.getByText("ABONNEMENT ACTIF", { exact: true }),
    ).toBeVisible();
    await page.screenshot({
      path: `test-results/member-profile-${width}.png`,
      fullPage: true,
    });
    await page.getByRole("button", { name: "Fermer", exact: true }).click();
    await page.screenshot({
      path: `test-results/members-${width}.png`,
      fullPage: true,
    });
    await page.getByRole("button", { name: "Paiement", exact: true }).click();
    await expect(page.getByRole("dialog")).toBeVisible();
    await page
      .getByRole("button", { name: "Prolonger l’abonnement", exact: true })
      .click();
    await expect(page.getByLabel("Montant", { exact: true })).toBeVisible();
    await page.screenshot({
      path: `test-results/payment-editor-${width}.png`,
      fullPage: true,
    });
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
    await page
      .getByRole("textbox", { name: "Rechercher une conversation" })
      .fill("introuvable");
    await expect(
      page.getByText("Aucune conversation ne correspond à vos filtres."),
    ).toBeVisible();
    await page
      .getByRole("button", { name: "Réinitialiser les filtres" })
      .click();
    await page.getByRole("button", { name: /^À répondre/ }).click();
    await page.screenshot({
      path: `test-results/support-inbox-${width}.png`,
      fullPage: true,
    });
    await page.getByRole("button", { name: /Membre Test/ }).click();
    await expect(
      page.getByRole("textbox", { name: "Message", exact: true }),
    ).toBeVisible();
    await page.getByLabel("Actions du message").click();
    await page
      .locator(".support-message-menu")
      .getByRole("button", { name: "Modifier", exact: true })
      .click();
    await expect(
      page.getByRole("textbox", { name: "Message à modifier" }),
    ).toHaveValue("Bonjour, nous allons vous aider.");
    await page.getByRole("button", { name: "Fermer", exact: true }).click();
    await page.getByLabel("Actions du message").click();
    await page.getByRole("button", { name: /^Bonjou fanmi/ }).click();
    await expect(
      page.getByRole("textbox", { name: "Message", exact: true }),
    ).toHaveValue(/Bonjou fanmi/);
    await page.screenshot({
      path: `test-results/support-${width}.png`,
      fullPage: true,
    });
    if (width < 850) {
      await page
        .getByRole("button", { name: "Retour aux conversations" })
        .click();
      await page.getByRole("link", { name: "Accueil", exact: true }).click();
      await page.getByRole("link", { name: "Paramètres du compte" }).click();
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

for (const [width, month, weeks] of [
  [320, 5, 6],
  [360, 2, 4],
  [360, 5, 6],
  [820, 5, 6],
  [1024, 5, 6],
  [1440, 4, 5],
]) {
  test(`le calendrier Bingo de ${weeks} semaines remplit la carte à ${width}px`, async ({
    page,
  }) => {
    await page.setViewportSize({ width, height: 900 });
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.clock.setFixedTime(new Date(2021, month - 1, 15, 12));
    await page.addInitScript(
      (theme) => localStorage.setItem("choloto-theme", theme),
      width === 820 ? "dark" : "light",
    );
    await page.goto("/dashboard");
    if (width < 992)
      await page
        .getByRole("button", { name: "Statistiques", exact: true })
        .click();
    const strip = page.getByRole("region", { name: "Statistiques" });
    const titles = strip.locator(".legacy-stat-title strong");
    await expect(titles).toHaveText([
      "VIP actifs",
      "Bingo mensuel",
      "Réactions Bingo",
      "Nouveaux membres",
    ]);
    const lastCard = strip.locator(".legacy-stat").last();
    if (width < 1440) {
      await expect(lastCard).not.toBeInViewport();
      await strip.hover();
      await page.mouse.wheel(2000, 0);
    }
    await expect(lastCard).toBeInViewport({ ratio: 0.99 });
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
    ).toBe(true);
    const calendar = page.getByLabel("BINGO du mois", { exact: true });
    await expect(
      calendar.getByText(`S${weeks}`, { exact: true }),
    ).toBeVisible();
    const card = page.locator(".legacy-stat").filter({ has: calendar });
    const sizes = await page.locator(".legacy-stat").evaluateAll((cards) =>
      cards.map((card) => {
        const { width, height, bottom, top } = card.getBoundingClientRect();
        const footer = card.querySelector(
          ".legacy-stat-footer > :first-child",
        )!;
        return {
          width,
          height,
          top,
          chartHeight: card
            .querySelector(".legacy-chart")!
            .getBoundingClientRect().height,
          bottomGap: bottom - footer.getBoundingClientRect().bottom,
        };
      }),
    );
    expect(sizes).toHaveLength(4);
    for (const size of sizes) {
      expect(size.top).toBe(sizes[0].top);
      expect(size.width / size.height).toBeGreaterThanOrEqual(0.9);
      expect(size.width / size.height).toBeLessThanOrEqual(1.2);
      expect(Math.abs(size.width - sizes[0].width)).toBeLessThanOrEqual(1);
      expect(Math.abs(size.height - sizes[0].height)).toBeLessThanOrEqual(1);
      expect(
        Math.abs(size.chartHeight - sizes[0].chartHeight),
      ).toBeLessThanOrEqual(1);
      expect(size.bottomGap).toBeGreaterThanOrEqual(0);
      expect(Math.round(size.bottomGap)).toBeLessThanOrEqual(17);
    }
    const periods = page
      .getByRole("group", { name: "Période VIP" })
      .getByRole("button");
    await expect(periods).toHaveText(["30 jours", "3 mois", "6 mois"]);
    const tops = await periods.evaluateAll((buttons) =>
      buttons.map((button) => button.offsetTop),
    );
    expect(new Set(tops).size).toBe(1);
    const area = await card.locator(".legacy-chart").boundingBox();
    const cells = await calendar
      .locator(".bingo-day")
      .evaluateAll((days) =>
        days.map((day) => day.getBoundingClientRect().toJSON()),
      );
    const left = Math.min(...cells.map((cell) => cell.left));
    const right = Math.max(...cells.map((cell) => cell.right));
    expect(right - left).toBeGreaterThan(area!.width * 0.85);
    expect(right).toBeLessThanOrEqual(area!.x + area!.width + 1);
    const adjacentChart = page
      .locator(".legacy-stat")
      .filter({ hasText: "Nouveaux membres" })
      .locator(".legacy-chart");
    expect(area!.height).toBeCloseTo(
      (await adjacentChart.boundingBox())!.height,
      1,
    );
    expect(cells[0].height).toBeGreaterThanOrEqual(15);
    expect(Math.max(...cells.map((cell) => cell.bottom))).toBeLessThanOrEqual(
      area!.y + area!.height + 1,
    );
    await card.screenshot({ path: test.info().outputPath("bingo.png") });
    if (width === 1440)
      await page
        .locator(".legacy-stats")
        .screenshot({ path: test.info().outputPath("statistiques.png") });
  });
}

test("infobulles des graphiques de l’accueil", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 960 });
  await page.route(/https:\/\/(?!fonts\.).*/, (route) => route.abort());
  await page.goto("/dashboard");
  const vip = page.locator(".legacy-stat").nth(0);
  const chart = vip.locator("svg[aria-label='Évolution sur la période']");
  const box = await chart.boundingBox();
  expect(box).not.toBeNull();
  await chart.hover({ position: { x: 4, y: 60 } });
  await expect(vip.getByRole("tooltip")).toContainText("VIP actifs");
  const firstDate = await vip.getByRole("tooltip").locator("span").innerText();
  await chart.hover({ position: { x: box!.width - 9, y: 60 } });
  await expect(vip.getByRole("tooltip").locator("span")).not.toHaveText(
    firstDate,
  );
  await expect(vip.locator(".chart-highlight")).toBeVisible();
  await page.screenshot({ path: "test-results/chart-hover.png" });
  await page.mouse.move(0, 0);
  await expect(vip.getByRole("tooltip")).toHaveCount(0);
  await chart.focus();
  await expect(vip.getByRole("tooltip").locator("span")).toHaveText(firstDate);
  await chart.press("ArrowRight");
  await expect(vip.getByRole("tooltip").locator("span")).not.toHaveText(
    firstDate,
  );
  await chart.press("Escape");
  await expect(vip.getByRole("tooltip")).toHaveCount(0);
  const bingo = page
    .locator(".legacy-stat")
    .filter({ hasText: "Bingo mensuel" });
  const firstDay = bingo.locator(".bingo-day").first();
  await firstDay.hover();
  await expect(firstDay).toHaveClass(/is-active/);
  await expect(bingo.getByRole("tooltip")).toContainText("Bingo validé");
  await page.mouse.move(0, 0);
  await expect(bingo.getByRole("tooltip")).toHaveCount(0);
});

test("les réactions des Bingo sont regroupées par jour sur les 30 derniers jours", async ({
  page,
}) => {
  await page.setViewportSize({ width: 1440, height: 960 });
  await page.clock.setFixedTime(new Date(2026, 10, 7, 12));
  await page.goto("/dashboard?reaction-fixture");
  const card = page
    .locator(".legacy-stat")
    .filter({ hasText: "Réactions Bingo" });
  await expect(card.locator(".legacy-stat-value")).toHaveText("51");
  await expect(card.locator(".bingo-reaction-legend span")).toHaveText([
    "Gagné 28",
    "Pas gagné 23",
  ]);
  const chart = card.getByRole("img", { name: /Réactions Bingo par jour/ });
  await chart.focus();
  const tooltip = card.getByRole("tooltip");
  await expect(tooltip).toContainText("9 octobre 2026");
  await expect(tooltip.locator("strong")).toHaveText([
    "Gagné · 3",
    "Pas gagné · 4",
  ]);
  await chart.press("ArrowRight");
  await expect(tooltip.locator("strong")).toHaveText([
    "Gagné · 0",
    "Pas gagné · 0",
  ]);
  await chart.press("Escape");
  await expect(tooltip).toHaveCount(0);
  const monthly = page
    .locator(".legacy-stat")
    .filter({ hasText: "Bingo mensuel" });
  await expect(monthly.locator(".legacy-stat-value")).toHaveText("3");
  await page.getByRole("button", { name: "Clean l’activité BINGO" }).click();
  await expect(card.locator(".legacy-stat-value")).toHaveText("51");
  await card.screenshot({
    path: test.info().outputPath("reactions-bingo.png"),
  });
});

test.describe("Réactions Bingo sur mobile", () => {
  test.use({
    viewport: { width: 390, height: 844 },
    hasTouch: true,
    timezoneId: "America/Port-au-Prince",
  });
  test("un toucher affiche les deux valeurs du jour choisi", async ({
    page,
  }) => {
    await page.clock.setFixedTime(new Date("2026-11-07T12:00:00-05:00"));
    await page.goto("/dashboard?reaction-fixture");
    await page.getByRole("button", { name: "Statistiques", exact: true }).tap();
    const chart = page.getByRole("img", { name: /Réactions Bingo par jour/ });
    const box = await chart.boundingBox();
    await chart.tap({ position: { x: box!.width - 9, y: 50 } });
    const tooltip = page.getByRole("tooltip");
    await expect(tooltip).toContainText("7 novembre 2026");
    await expect(tooltip.locator("strong")).toHaveText([
      "Gagné · 2",
      "Pas gagné · 1",
    ]);
    await chart.tap({ position: { x: 8, y: 50 } });
    await expect(tooltip).toContainText("9 octobre 2026");
  });
});

test("la période VIP actualise les dates et la courbe", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 960 });
  await page.route(/https:\/\/(?!fonts\.).*/, (route) => route.abort());
  await page.goto("/dashboard");
  const vip = page.locator(".legacy-stat").first();
  const chart = vip.locator("svg[aria-label='Évolution sur la période']");
  const dates = chart.locator('text[dominant-baseline="hanging"]');
  await expect(dates.last()).toBeVisible();
  const initialDates = await dates.allTextContents();
  const initialPath = await chart
    .locator('path[stroke-width="2.5"]')
    .getAttribute("d");
  const periods = vip.getByRole("group", { name: "Période VIP" });
  const selected = periods.getByRole("button", { pressed: true });
  await expect(selected).toHaveText("30 jours");
  await periods.getByRole("button", { name: "3 mois" }).click();
  await expect(selected).toHaveText("3 mois");
  await expect(dates.last()).not.toHaveText(initialDates.at(-1)!);
  await expect(chart.locator('path[stroke-width="2.5"]')).not.toHaveAttribute(
    "d",
    initialPath!,
  );
  const threeMonthDates = await dates.allTextContents();
  expect(threeMonthDates.every((date) => !date.includes("/"))).toBe(true);
  await periods.getByRole("button", { name: "6 mois" }).press("Enter");
  await expect(selected).toHaveText("6 mois");
  await expect(dates.first()).not.toHaveText(threeMonthDates[0]);
  await expect(dates.last()).toHaveText(threeMonthDates.at(-1)!);
  await page.screenshot({ path: "test-results/vip-six-month-axis.png" });
  await periods.getByRole("button", { name: "30 jours" }).click();
  await expect(selected).toHaveText("30 jours");
  await expect(dates).toHaveText(initialDates);
});

test("Clean remet l’activité BINGO à zéro et persiste au rechargement", async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 960 });
  await page.route(/https:\/\/(?!fonts\.).*/, (route) => route.abort());
  await page.goto("/dashboard");
  const card = page
    .locator(".task-tile-container")
    .filter({ hasText: "Activité BINGO" });
  await expect(card).toContainText("6 commentaires • 3 réactions");
  await card.getByRole("button", { name: "Clean l’activité BINGO" }).click();
  await expect(page).toHaveURL(/dashboard/);
  await expect(card).toContainText("0 commentaires • 0 réactions");
  await expect(card.getByRole("button")).toBeDisabled();
  await page.reload();
  await expect(card).toContainText("0 commentaires • 0 réactions");
  await expect(card.getByRole("link")).toHaveAttribute(
    "href",
    "/publications/history",
  );
  await page.screenshot({ path: "test-results/bingo-clean-mobile.png" });
});

test("navigation mobile par rubrique", async ({ page }) => {
  await page.setViewportSize({ width: 320, height: 700 });
  await page.route(/https:\/\/(?!fonts\.).*/, (route) => route.abort());
  await page.goto("/dashboard");
  const bar = page.getByRole("navigation", { name: "Navigation mobile" });
  await expect(bar.getByRole("link")).toHaveText([
    "Accueil",
    "Support",
    "Membres",
  ]);
  await expect(
    page.getByRole("heading", { name: "Actions rapides" }),
  ).toBeHidden();
  await page.getByRole("link", { name: /^Tirages\b/ }).click();
  await expect(page).toHaveURL(/tirages$/);
  const accueil = bar.getByRole("link", { name: "Accueil" });
  await expect(accueil).toHaveAttribute("aria-current", "location");
  await accueil.click();
  await page.getByRole("link", { name: "Paramètres du compte" }).click();
  await expect(page).toHaveURL(/settings$/);
  await expect(bar.getByRole("link", { name: "Accueil" })).toHaveAttribute(
    "aria-current",
    "location",
  );
  const publications = bar.getByRole("button", { name: "Publications" });
  await publications.click();
  const types = page.getByRole("navigation", { name: "Types de publication" });
  await expect(page).toHaveURL(/settings$/);
  await expect(types.getByRole("link")).toHaveText([
    "BINGO",
    "Prédictions",
    "Croix",
  ]);
  await page.keyboard.press("Tab");
  await expect(types.getByRole("link", { name: "BINGO" })).toBeFocused();
  await page.keyboard.press("Escape");
  await expect(publications).toBeFocused();
  await expect(types).toBeHidden();
  await publications.click();
  await page.getByRole("heading", { name: "Apparence" }).click();
  await expect(types).toBeHidden();
  for (const [name, path] of [
    ["BINGO", "/publications"],
    ["Croix", "/croix"],
    ["Prédictions", "/predictions"],
  ]) {
    await publications.click();
    const link = types.getByRole("link", { name, exact: true });
    await link.click();
    await expect(page).toHaveURL(new RegExp(path + "$"));
    await expect(types).toBeHidden();
    await expect(publications).toHaveAttribute("aria-current", /page|location/);
  }
  await page.goto("/croix/history");
  await publications.click();
  await expect(types.getByRole("link", { name: "Croix" })).toHaveAttribute(
    "aria-current",
    "location",
  );
  await bar.getByRole("link", { name: "Support" }).click();
  await expect(page).toHaveURL(/support-inbox$/);
  await bar.getByRole("link", { name: "Membres" }).click();
  await page.locator('main a[href="/payments"]').click();
  await expect(bar.getByRole("link", { name: "Membres" })).toHaveAttribute(
    "aria-current",
    "location",
  );
  await page.setViewportSize({ width: 1024, height: 768 });
  await expect(bar).toBeHidden();
  await expect(page.locator("aside nav a")).toHaveCount(8);
});
