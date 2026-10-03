// Retire the old Flutter worker on existing installations of this origin.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil((async () => {
  for (const name of await caches.keys()) if (name.startsWith('flutter-')) await caches.delete(name);
  await self.registration.unregister();
  await self.clients.claim();
})()));
