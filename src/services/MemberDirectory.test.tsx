import { act, fireEvent, render, screen } from "@testing-library/react";
import { MemoryRouter, Link, Route, Routes } from "react-router-dom";
import { afterEach, expect, it, vi } from "vitest";
import { MemberDirectoryProvider, useMemberDirectory } from "./MemberDirectory";

const { listen, stop } = vi.hoisted(() => ({ listen: vi.fn(), stop: vi.fn() }));
vi.mock("./firebase", () => ({ db: {} }));
vi.mock("firebase/firestore", () => ({
  collection: () => "user",
  query: (ref: string) => ref,
  onSnapshot: listen,
}));

function List() {
  const { rows, refresh } = useMemberDirectory();
  return (
    <>
      <button onClick={refresh}>Actualiser</button>
      {rows.map((row) => (
        <span key={row.id}>{row.display_name}</span>
      ))}
    </>
  );
}

afterEach(() => vi.useRealTimers());

it("réutilise la liste synchronisée, libère l’écoute après 30 minutes et à la fin de session", () => {
  vi.useFakeTimers();
  listen.mockReturnValue(stop);
  const app = render(
    <MemoryRouter initialEntries={["/"]}>
      <MemberDirectoryProvider>
        <Link to="/users">Membres</Link>
        <Link to="/">Accueil</Link>
        <Routes>
          <Route path="/users" element={<List />} />
          <Route path="/" element={null} />
        </Routes>
      </MemberDirectoryProvider>
    </MemoryRouter>,
  );
  const visit = (name: string) =>
    fireEvent.click(screen.getByRole("link", { name }));
  expect(listen).not.toHaveBeenCalled();
  visit("Membres");
  visit("Accueil");
  act(() => {
    vi.advanceTimersByTime(29 * 60_000);
    listen.mock.calls[0][1]({
      docs: [{ id: "1", data: () => ({ display_name: "Marie" }) }],
    });
  });
  visit("Membres");
  expect(screen.getByText("Marie")).toBeVisible();
  expect(listen).toHaveBeenCalledTimes(1);
  act(() => vi.advanceTimersByTime(2 * 60_000));
  expect(stop).not.toHaveBeenCalled();
  fireEvent.click(screen.getByRole("button", { name: "Actualiser" }));
  expect(listen).toHaveBeenCalledTimes(2);
  visit("Accueil");
  act(() => vi.advanceTimersByTime(30 * 60_000));
  expect(stop).toHaveBeenCalledTimes(2);
  visit("Membres");
  expect(listen).toHaveBeenCalledTimes(3);
  expect(screen.queryByText("Marie")).toBeNull();
  app.unmount();
  expect(stop).toHaveBeenCalledTimes(3);
});
