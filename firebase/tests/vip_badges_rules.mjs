import assert from 'node:assert/strict';

export async function testVipBadges({admin, owner}) {
  const project = process.env.GCLOUD_PROJECT || 'demo-choloto';
  assert.ok(project.startsWith('demo-'), 'Use a demo project for emulator tests');
  const host = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
  const base = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
  const stringValue = value => ({stringValue: value});
  const integerValue = value => ({integerValue: String(value)});
  const defaults = [
    ['Nouveau Membre CHOLOTO', 0], ['Membre initié CHOLOTO', 30],
    ['Membre Discipliné CHOLOTO', 60], ['Membre Visionnaire CHOLOTO', 180],
    ['Membre Loyal CHOLOTO', 365], ['Membre Empereur CHOLOTO', 730],
    ['Membre Légende CHOLOTO', 1095], ['Membre Ténor CHOLOTO', 1460],
  ].map(([name, days]) => ({name: stringValue(name), days: integerValue(days)}));
  const fields = tiers => ({tiers: {arrayValue: {values: tiers.map(tier => ({mapValue: {fields: tier}}))}}});
  const replace = (index, changes) => defaults.map((tier, i) => i === index ? {...tier, ...changes} : tier);

  async function check(method, token, expected, label, data, path = 'vip_badges/config') {
    const response = await fetch(`${base}/${path}`, {
      method,
      headers: {'content-type': 'application/json', ...(token ? {authorization: `Bearer ${token}`} : {})},
      body: data ? JSON.stringify({fields: data}) : undefined,
    });
    const body = await response.json();
    assert.equal(response.status, expected, `${label}: ${JSON.stringify(body)}`);
    return body;
  }

  await check('GET', owner.token, 404, 'member can read missing badge configuration');
  await check('GET', admin.token, 404, 'admin can read missing badge configuration');
  await check('GET', undefined, 403, 'signed-out reader cannot inspect missing configuration');
  await check('PATCH', undefined, 403, 'signed-out creation denied', fields(defaults));
  await check('PATCH', owner.token, 403, 'member creation denied', fields(defaults));
  await check('PATCH', admin.token, 200, 'initial badge configuration', fields(defaults));

  const edited = fields(replace(1, {name: stringValue('Initié VIP'), days: integerValue(15)}));
  await check('PATCH', owner.token, 403, 'member update denied', edited);
  await check('PATCH', admin.token, 200, 'admin edits titles and thresholds', edited);
  await check('GET', undefined, 403, 'signed-out reader cannot read saved thresholds');
  const editsRead = await check('GET', owner.token, 200, 'member reads saved thresholds');
  assert.deepEqual(editsRead.fields, edited);
  await check('DELETE', owner.token, 403, 'member cannot erase badge configuration');
  await check('DELETE', admin.token, 403, 'admin cannot erase badge configuration');
  await check('GET', owner.token, 403, 'member cannot enumerate badge documents', undefined, 'vip_badges');
  await check('PATCH', admin.token, 403, 'config document only', fields(defaults), 'vip_badges/other');

  for (const [label, invalid] of [
    ['unknown configuration field', {...fields(defaults), enabled: {booleanValue: true}}],
    ['tiers are required', {other: {booleanValue: true}}],
    ['insufficient tiers', fields(defaults.slice(0, -1))],
    ['extra tier', fields([...defaults, defaults.at(-1)])],
    ['unknown tier field', fields(replace(1, {enabled: {booleanValue: true}}))],
    ['name is required', fields(defaults.map((t,i) => i === 2 ? {days:t.days} : t))],
    ['empty name', fields(replace(0, {name: stringValue('')}))],
    ['untrimmed name', fields(replace(6, {name: stringValue(' Membre Légende CHOLOTO ')}))],
    ['long name', fields(replace(7, {name: stringValue('A'.repeat(81))}))],
    ['first tier at registration', fields(replace(0, {days: integerValue(1)}))],
    ['duplicate threshold', fields(replace(3, {days: integerValue(60)}))],
    ['decreasing threshold', fields(replace(7, {days: integerValue(1000)}))],
    ['invalid threshold type', fields(replace(4, {days: {doubleValue: 365.5}}))],
    ['threshold limit', fields(replace(7, {days: integerValue(36501)}))],
  ]) {
    await check('PATCH', admin.token, 403, label, invalid);
  }
  const unchanged = await check('GET', owner.token, 200, 'failed writes preserve complete configuration');
  assert.deepEqual(unchanged.fields, edited);
  console.log('VIP badge configuration rules passed.');
}
