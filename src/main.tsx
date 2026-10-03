import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import "./styles.css";
// Remove only the previous Flutter app's caches and service worker.
if ("serviceWorker" in navigator)
  navigator.serviceWorker
    .getRegistrations()
    .then((registrations) => {
      for (const registration of registrations)
        if (
          registration.active?.scriptURL.includes("/flutter_service_worker.js")
        )
          void registration.unregister();
    })
    .catch(() => {});
if ("caches" in window)
  caches
    .keys()
    .then((keys) =>
      Promise.all(
        keys
          .filter((key) => key.startsWith("flutter-"))
          .map((key) => caches.delete(key)),
      ),
    )
    .catch(() => {});
ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <BrowserRouter basename={import.meta.env.BASE_URL}>
      <App />
    </BrowserRouter>
  </React.StrictMode>,
);
