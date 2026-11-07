import { beforeEach, expect, it, vi } from "vitest";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
const mocks = vi.hoisted(() => ({ prepare: vi.fn(), apply: vi.fn() }));
vi.mock("../services/firebase", () => ({
  auth: { currentUser: { uid: "admin" } },
  db: {},
}));
vi.mock("../services/compensation", () => ({
  prepareCompensation: mocks.prepare,
  applyCompensation: mocks.apply,
}));
import CompensationDialog from "./CompensationDialog";
const operation = {
  id: "operation",
  adminUid: "admin",
  days: 3,
  scope: "vip",
  uids: ["alice", "bob"],
  startedAt: Date.now(),
};
const rows = [
  {
    id: "alice",
    display_name: "Alice",
    email: "alice@example.test",
    end_sub: new Date(2099, 1, 1),
  },
  { id: "bob", display_name: "Bob", email: "bob@example.test" },
];
beforeEach(() => {
  vi.clearAllMocks();
  sessionStorage.clear();
  HTMLDialogElement.prototype.showModal = function () {
    this.setAttribute("open", "");
  };
  HTMLDialogElement.prototype.close = function () {
    this.removeAttribute("open");
  };
  mocks.prepare.mockResolvedValue(operation);
  mocks.apply.mockResolvedValue({
    applied: 2,
    failed: 0,
    skipped: 0,
    error: "",
  });
});

it("conserve les membres cochés quand la recherche change et envoie uniquement la sélection", async () => {
  render(<CompensationDialog rows={rows} onClose={vi.fn()} />);
  fireEvent.change(screen.getByLabelText("Bénéficiaires"), {
    target: { value: "selected" },
  });
  expect(
    screen.getByRole("button", { name: "Appliquer la compensation" }),
  ).toBeDisabled();
  fireEvent.change(screen.getByLabelText("Rechercher des bénéficiaires"), {
    target: { value: "Alice" },
  });
  fireEvent.click(
    screen.getByLabelText("Tout sélectionner dans les résultats"),
  );
  fireEvent.change(screen.getByLabelText("Rechercher des bénéficiaires"), {
    target: { value: "Bob" },
  });
  expect(screen.getByText("1 membre")).toBeVisible();
  expect(screen.getByLabelText(/Bob/)).not.toBeChecked();
  fireEvent.change(screen.getByLabelText("Nombre de jours"), {
    target: { value: "3" },
  });
  fireEvent.click(
    screen.getByRole("button", { name: "Appliquer la compensation" }),
  );
  await waitFor(() =>
    expect(mocks.prepare).toHaveBeenCalledWith(3, "selected", ["alice"]),
  );
  await screen.findByRole("button", { name: "Terminer" });
});

it("fige le formulaire et empêche la fermeture et les doubles envois pendant l’application", async () => {
  let finish: (value: unknown) => void = () => {};
  mocks.apply.mockReturnValue(
    new Promise((resolve) => {
      finish = resolve;
    }),
  );
  const close = vi.fn();
  render(<CompensationDialog rows={rows} onClose={close} />);
  fireEvent.change(screen.getByLabelText("Nombre de jours"), {
    target: { value: "3" },
  });
  fireEvent.click(
    screen.getByRole("button", { name: "Appliquer la compensation" }),
  );
  await waitFor(() => expect(mocks.apply).toHaveBeenCalledTimes(1));
  expect(
    JSON.parse(sessionStorage.getItem("choloto.compensation.admin")!),
  ).toEqual(operation);
  expect(screen.getByLabelText("Nombre de jours")).toBeDisabled();
  expect(screen.getByRole("button", { name: "Fermer" })).toBeDisabled();
  const dialog = screen.getByRole("dialog");
  expect(fireEvent(dialog, new Event("cancel", { cancelable: true }))).toBe(
    false,
  );
  fireEvent.click(dialog);
  fireEvent.submit(
    screen.getByRole("button", { name: "Application…" }).closest("form")!,
  );
  expect(close).not.toHaveBeenCalled();
  expect(mocks.apply).toHaveBeenCalledTimes(1);
  finish({ applied: 2, failed: 0, skipped: 0, error: "" });
  await screen.findByRole("button", { name: "Terminer" });
  expect(sessionStorage.getItem("choloto.compensation.admin")).toBeNull();
});

it("reprend la même opération après échec et réouverture du formulaire", async () => {
  mocks.apply.mockResolvedValueOnce({
    applied: 1,
    failed: 1,
    skipped: 0,
    error: "Connexion interrompue",
  });
  const first = render(<CompensationDialog rows={rows} onClose={vi.fn()} />);
  fireEvent.change(screen.getByLabelText("Nombre de jours"), {
    target: { value: "3" },
  });
  fireEvent.click(
    screen.getByRole("button", { name: "Appliquer la compensation" }),
  );
  await screen.findByRole("alert");
  expect(screen.getByText("1 membre compensé")).toBeVisible();
  first.unmount();
  render(<CompensationDialog rows={rows} onClose={vi.fn()} />);
  expect(screen.getByLabelText("Nombre de jours")).toHaveValue(3);
  fireEvent.click(screen.getByRole("button", { name: "Réessayer" }));
  await screen.findByText("2 membres compensés");
  expect(mocks.prepare).toHaveBeenCalledTimes(1);
  expect(mocks.apply.mock.calls[1][0]).toEqual(mocks.apply.mock.calls[0][0]);
  expect(sessionStorage.getItem("choloto.compensation.admin")).toBeNull();
});
