import { beforeEach, it, expect, vi } from "vitest";
import { render, screen, waitFor, act } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
const mocks = vi.hoisted(() => ({
  user: null as unknown,
  allowed: true,
  logout: vi.fn(),
  callback: null as null | ((user: unknown) => void),
}));
vi.mock("firebase/auth", () => ({
  onIdTokenChanged: (_auth: unknown, callback: (user: unknown) => void) => {
    mocks.callback = callback;
    void callback(mocks.user);
    return () => {};
  },
}));
vi.mock("../services/firebase", () => ({
  auth: {},
  isAdministrator: async () => mocks.allowed,
  login: vi.fn(),
  logout: mocks.logout,
}));
vi.mock("../services/OfficialProvider", () => ({
  OfficialProvider: ({ children }: { children: unknown }) => children,
}));
vi.mock("../services/support", () => ({ cleanExpiredSupport: async () => {} }));
import App from "../App";
beforeEach(() => {
  mocks.user = null;
  mocks.allowed = true;
  mocks.logout.mockReset();
});
it("protège une route privée sans session", async () => {
  render(
    <MemoryRouter initialEntries={["/payments"]}>
      <App />
    </MemoryRouter>,
  );
  expect(
    await screen.findByRole("button", { name: "Continuer avec Google" }),
  ).toBeVisible();
  expect(screen.queryByText("Transactions")).not.toBeInTheDocument();
});
it("vérifie les autorisations lors de la restauration d’une session", async () => {
  mocks.user = { uid: "not-admin", email: "reader@example.test" };
  mocks.allowed = false;
  render(
    <MemoryRouter initialEntries={["/settings"]}>
      <App />
    </MemoryRouter>,
  );
  await waitFor(() => expect(mocks.logout).toHaveBeenCalled());
  expect(await screen.findByText("Accès administrateur requis.")).toBeVisible();
});
it("affiche les paramètres pour un administrateur autorisé", async () => {
  mocks.user = {
    uid: "admin",
    email: "admin@example.test",
    displayName: "Admin",
  };
  render(
    <MemoryRouter initialEntries={["/settings"]}>
      <App />
    </MemoryRouter>,
  );
  expect(
    await screen.findByRole("heading", { name: "Apparence" }),
  ).toBeVisible();
  expect(screen.getByRole("button", { name: "Sombre" })).toBeVisible();
});

it("conserve l’écran monté lors du renouvellement du jeton", async () => {
  mocks.user = {
    uid: "admin",
    email: "admin@example.test",
    displayName: "Admin",
  };
  render(
    <MemoryRouter initialEntries={["/settings"]}>
      <App />
    </MemoryRouter>,
  );
  const heading = await screen.findByRole("heading", { name: "Apparence" });
  await act(async () => {
    mocks.callback?.(mocks.user);
  });
  expect(screen.getByRole("heading", { name: "Apparence" })).toBe(heading);
});
