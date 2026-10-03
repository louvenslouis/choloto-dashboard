import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";
const local = (name: string) => fileURLToPath(new URL(name, import.meta.url));
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: [
      {
        find: /^(\.\.\/|\.\/)?services\/firebase$|^\.\/firebase$/,
        replacement: local("./firebase.ts"),
      },
      { find: "firebase/firestore", replacement: local("./firestore.ts") },
      { find: "firebase/auth", replacement: local("./auth.ts") },
    ],
  },
  server: { host: "127.0.0.1", port: 5174, strictPort: true },
});
