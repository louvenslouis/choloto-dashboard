// Only the E2E Vite server resolves this module. Push delivery is simulated by Chrome.
export const isSupported = async () => true;
export const getMessaging = () => ({});
export const getToken = async () => "fixture-admin-device-token";
