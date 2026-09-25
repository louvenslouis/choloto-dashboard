import test from 'node:test';
import assert from 'node:assert/strict';
import { onRequestGet } from '../functions/api/country.js';

test('country endpoint returns only a validated country code without caching', async () => {
  for (const [input, expected] of [['HT', 'HT'], ['US', 'US'], ['XX', null], ['T1', null], [null, null]]) {
    const response = onRequestGet({ request: { cf: { country: input } } });
    assert.deepEqual(await response.json(), { country: expected });
    assert.equal(response.headers.get('cache-control'), 'no-store');
    assert.equal(response.headers.get('access-control-allow-origin'), '*');
  }
});
