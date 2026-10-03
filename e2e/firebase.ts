// Isolated browser-test fixture. Only the dedicated e2e Vite config resolves this module.
export const auth = {
  currentUser: {
    uid: "fixture-admin",
    email: "admin@example.test",
    displayName: "Administration",
    getIdToken: async () => "",
  },
};
export const db = {};
export const isAdministrator = async () => true;
export const login = async () => {};
export const logout = async () => {};
export const authorizeAnalytics = async () => {};
export const getAnalyticsToken = () => null;
