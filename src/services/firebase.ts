import { initializeApp } from "firebase/app";
import {
  getAuth,
  GoogleAuthProvider,
  signInWithPopup,
  reauthenticateWithPopup,
  signOut,
  type User,
} from "firebase/auth";
import {
  initializeFirestore,
  persistentLocalCache,
  persistentMultipleTabManager,
} from "firebase/firestore";
const app = initializeApp({
  apiKey: "AIzaSyBljhPBH4sMSQXVJMSP-qRadQTiwrC4BRg",
  authDomain: "choloto-6aa5b.firebaseapp.com",
  projectId: "choloto-6aa5b",
  storageBucket: "choloto-6aa5b.firebasestorage.app",
  messagingSenderId: "934080509989",
  appId: "1:934080509989:web:3c903c43f4894c904f27cc",
  measurementId: "G-NGFR8XSQJ5",
});
export const auth = getAuth(app);
export const db = initializeFirestore(app, {
  localCache: persistentLocalCache({
    tabManager: persistentMultipleTabManager(),
    cacheSizeBytes: 50 * 1024 * 1024,
  }),
});
let analyticsToken: string | null = null;
export const getAnalyticsToken = () => analyticsToken;
const provider = () => {
  const p = new GoogleAuthProvider();
  p.addScope("https://www.googleapis.com/auth/analytics.readonly");
  return p;
};
export async function isAdministrator(user: User) {
  const token = await user.getIdTokenResult();
  return (
    token.claims.admin === true ||
    user.email?.toLowerCase() === "sanonmaeva064@gmail.com"
  );
}
export async function login() {
  const result = await signInWithPopup(auth, provider());
  if (!(await isAdministrator(result.user))) {
    await logout();
    throw new Error("Accès administrateur requis.");
  }
  analyticsToken =
    GoogleAuthProvider.credentialFromResult(result)?.accessToken ?? null;
}
export async function authorizeAnalytics() {
  if (!auth.currentUser) throw new Error("Reconnectez-vous.");
  const result = await reauthenticateWithPopup(auth.currentUser, provider());
  analyticsToken =
    GoogleAuthProvider.credentialFromResult(result)?.accessToken ?? null;
}
export async function logout() {
  analyticsToken = null;
  await signOut(auth);
}
