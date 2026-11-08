import { expect, test } from "@playwright/test";

test("édition et validation des seuils des huit badges sur mobile", async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.route(/^https:/, (route) => route.abort());
  await page.goto("/settings");
  const collection = page.locator(".vip-badge-collection");
  const medals = collection.getByRole("button");
  await expect(medals).toHaveCount(8);
  for (let i = 0; i < 8; i++) {
    const image = medals.nth(i).locator("img");
    await expect(image).toHaveAttribute(
      "src",
      new RegExp(`/vip-badges/rank-${i + 1}\\.webp$`),
    );
    await image.scrollIntoViewIfNeeded();
    await expect
      .poll(() => image.evaluate((el) => (el as HTMLImageElement).naturalWidth))
      .toBeGreaterThan(0);
  }
  await page.locator(".panel").filter({ has: collection }).screenshot({
    path: "test-results/vip-badges-mobile.png",
    animations: "disabled",
  });
  await medals.first().click();
  const welcome = page.getByRole("dialog", { name: "Nouveau Membre CHOLOTO" });
  await expect(welcome.getByText("Dès l’activation VIP")).toBeVisible();
  await welcome.getByRole("button", { name: "Fermer" }).click();
  await expect(medals.first()).toBeFocused();
  await page.getByRole("button", { name: "Modifier les badges" }).click();
  const dialog = page.getByRole("dialog", { name: "Badges VIP" });
  await expect(dialog.getByRole("spinbutton")).toHaveCount(8);
  await expect(dialog.getByLabel("Jours VIP du badge 1")).toHaveAttribute(
    "readonly",
    "",
  );
  await expect(dialog.getByLabel("Nom du badge 8")).toHaveValue(
    "Membre Ténor CHOLOTO",
  );
  const submit = dialog.getByRole("button", { name: "Enregistrer" });
  const tenor = dialog.getByRole("button", {
    name: "Ouvrir le badge Membre Ténor CHOLOTO",
  });
  await tenor.click();
  const detail = page.getByRole("dialog", { name: "Membre Ténor CHOLOTO" });
  await expect(detail.getByText(/1\s460 jours VIP/)).toBeVisible();
  await detail.screenshot({
    path: "test-results/vip-tenor-mobile.png",
    animations: "disabled",
  });
  await page.keyboard.press("Escape");
  await expect(tenor).toBeFocused();
  await expect(submit).toBeDisabled();
  await dialog.getByLabel("Jours VIP du badge 5").fill("180");
  await submit.click();
  await expect(dialog.getByRole("alert")).toContainText("181");
  await dialog.getByLabel("Jours VIP du badge 5").fill("360");
  await expect(dialog.getByRole("alert")).toHaveCount(0);
  await expect(submit).toBeEnabled();
  expect(await dialog.evaluate((el) => el.scrollWidth <= el.clientWidth)).toBe(
    true,
  );
});
