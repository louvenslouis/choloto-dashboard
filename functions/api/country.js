export function onRequestGet({ request }) {
  const value = request.cf?.country;
  const country = typeof value === 'string' && /^[A-Z]{2}$/.test(value) && value !== 'XX'
    ? value
    : null;
  return new Response(JSON.stringify({ country }), {
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'access-control-allow-origin': '*',
      'cache-control': 'no-store',
    },
  });
}
