import { expect, test } from "@playwright/test";

test("édition et validation des seuils des huit badges sur mobile", async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.route(/^https:/, (route) => route.abort());
  await page.goto("/settings");
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
