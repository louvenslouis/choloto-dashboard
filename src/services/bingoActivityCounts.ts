import {
  collection,
  getCountFromServer,
  query,
  where,
} from "firebase/firestore";
import { auth, db } from "./firebase";

export type ActivityCounts = Record<
  string,
  { comments: number; reactions: number }
>;
type ReactionCounts = { won: number; lost: number };

const lifetime = 30 * 60_000;

function bingoCountCache<T>(read: (id: string) => Promise<T>) {
  type Entry = { result: Promise<T>; expires: number };
  const sessions = new WeakMap<
    NonNullable<typeof auth.currentUser>,
    Map<string, Entry>
  >();

  return {
    clear() {
      if (auth.currentUser) sessions.delete(auth.currentUser);
    },
    async load(ids: string[]): Promise<Record<string, T>> {
      const user = auth.currentUser;
      if (!user) throw new Error("Reconnectez-vous.");
      const cache = sessions.get(user) ?? new Map<string, Entry>();
      sessions.set(user, cache);
      for (const [id, entry] of cache) {
        if (entry.expires <= Date.now()) cache.delete(id);
      }
      const pairs = await Promise.all(
        ids.map(async (id) => {
          let entry = cache.get(id);
          if (!entry) {
            const fresh = { result: read(id), expires: Infinity };
            cache.set(id, fresh);
            try {
              await fresh.result;
              fresh.expires = Date.now() + lifetime;
            } catch (error) {
              if (cache.get(id) === fresh) cache.delete(id);
              throw error;
            }
            entry = fresh;
          }
          return [id, await entry.result] as const;
        }),
      );
      return Object.fromEntries(pairs);
    },
  };
}

const comments = bingoCountCache(async (id) => {
  const [visible, hidden] = await Promise.all(
    ["comments", "hiddenComments"].map((name) =>
      getCountFromServer(collection(db, "bingo", id, name)),
    ),
  );
  return visible.data().count + hidden.data().count;
});

const reactions = bingoCountCache<ReactionCounts>(async (id) => {
  const ref = collection(db, "bingo", id, "bingostats");
  const [all, gains] = await Promise.all([
    getCountFromServer(ref),
    getCountFromServer(query(ref, where("gain", "==", true))),
  ]);
  const total = all.data().count;
  const won = Math.min(total, gains.data().count);
  return { won, lost: total - won };
});

export const loadReactionCounts = reactions.load;

export function clearActivityCounts() {
  comments.clear();
  reactions.clear();
}

export async function loadActivityCounts(
  ids: string[],
): Promise<ActivityCounts> {
  const [commentCounts, reactionCounts] = await Promise.all([
    comments.load(ids),
    loadReactionCounts(ids),
  ]);
  return Object.fromEntries(
    ids.map((id) => [
      id,
      {
        comments: commentCounts[id],
        reactions: reactionCounts[id].won + reactionCounts[id].lost,
      },
    ]),
  );
}
