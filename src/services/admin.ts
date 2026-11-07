import { auth } from "./firebase";

export async function callAdmin(name: string, data: Record<string, unknown>) {
  const token = await auth.currentUser?.getIdToken();
  if (!token) throw new Error("Reconnectez-vous.");
  const response = await fetch(
    `https://us-central1-choloto-6aa5b.cloudfunctions.net/${name}`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ data }),
    },
  );
  const payload = await response.json();
  if (!response.ok || payload.error)
    throw new Error(payload.error?.message || "Le serveur ne répond pas.");
  return payload.data ?? payload.result;
}
