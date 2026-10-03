import { auth } from "./firebase";
export const onIdTokenChanged = (
  _auth: unknown,
  callback: (user: unknown) => void,
) => {
  queueMicrotask(() => callback(auth.currentUser));
  return () => {};
};
