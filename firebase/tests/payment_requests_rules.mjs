import assert from 'node:assert/strict';

export async function testPaymentRequests({admin}) {
  const project = process.env.GCLOUD_PROJECT || 'demo-choloto';
  assert.ok(project.startsWith('demo-'), 'Never test against production');
  const host = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
  const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
  const root = `projects/${project}/databases/(default)/documents`;
  const url = `http://${host}/v1/${root}`;
  const str = stringValue => ({stringValue});
  const int = n => ({integerValue: String(n)});
  const time = timestampValue => ({timestampValue});
  const ref = path => ({referenceValue: `${root}/${path}`});
  async function http(path, token, method = 'GET', body) {
    const r = await fetch(`${url}${path}`, {method,
      headers: {'content-type': 'application/json', ...(token ? {authorization: `Bearer ${token}`} : {})},
      body: body ? JSON.stringify(body) : undefined});
    return {status: r.status, body: await r.text()};
  }
  const check = (r, code, label) => assert.equal(r.status, code, `${label}: ${r.body}`);
  const fields = async (path, token) => JSON.parse((await http(path, token)).body).fields;
  async function user(label) {
    const r = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
      method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify({
        email: `proof-${label}-${Date.now()}@example.test`, password: 'proof-test-password', returnSecureToken: true})});
    const b = await r.json(); assert.equal(r.status, 200, JSON.stringify(b)); return {uid: b.localId, token: b.idToken};
  }
  const owner = await user('owner'), other = await user('other'), legacy = await user('legacy');
  const profile = uid => `/user/${uid}`;
  for (const [u, old] of [[owner, false], [legacy, true]]) {
    check(await http(profile(u.uid), u.token), 404, 'first sign-in reads absent profile');
    check(await http(profile(u.uid), u.token, 'PATCH', {fields: {
      ...(!old ? {uid: str(u.uid)} : {}), email: str('member@example.test')
    }}), 200, 'create current / legacy profile');
    check(await http(profile(u.uid), u.token), 200, 'read profile before submission');
  }
  function write(path, values, {mask = false, stamp} = {}) {
    return {update: {name: `${root}/${path}`, fields: values},
      ...(mask ? {updateMask: {fieldPaths: Object.keys(values)}} : {}),
      ...(stamp ? {updateTransforms: [{fieldPath: stamp, setToServerValue: 'REQUEST_TIME'}]} : {})};
  }
  const commit = (writes, token) => http(':commit', token, 'POST', {writes});
  function submission(id, uid, extra = {}, imageExtra = {}) {
    return [write(`payment_requests/${id}`, {user_uid: str(uid), plan: str('vip'), status: str('pending'),
      note: str(''), ...extra}, {stamp: 'created_at'}),
    write(`payment_requests/${id}/evidence/image`, {base64: str('/9j/2Q=='), mime_type: str('image/jpeg'), byte_length: int(4), ...imageExtra})];
  }
  const request = id => `/payment_requests/${id}`, image = id => `${request(id)}/evidence/image`;
  const id = 'current-request';
  check(await http(request(id), owner.token), 404, 'read missing request before transaction');
  check(await commit(submission(id, owner.uid), owner.token), 200, 'submit metadata + image atomically');
  assert.equal((await fields(profile(owner.uid), owner.token)).end_sub, undefined, 'submission grants no VIP');
  assert.equal((await fields(request(id), owner.token)).amount, undefined, 'photo-only submission requires no amount');
  check(await commit(submission('optional-message', owner.uid, {note: str('Transfert envoyé')}), owner.token), 200, 'optional message');
  check(await commit(submission('no-profile', other.uid), other.token), 403, 'submission requires own profile');
  check(await commit(submission('long-message', owner.uid, {note: str('A'.repeat(501))}), owner.token), 403, 'message size limit');
  for (const token of [owner.token, admin.token]) {
    check(await http(request(id), token), 200, 'owner/admin request');
    check(await http(image(id), token), 200, 'owner/admin image');
  }
  for (const token of [undefined, other.token]) {
    check(await http(request(id), token), 403, 'request private');
    check(await http(image(id), token), 403, 'image private');
    check(await commit(submission('spoof', owner.uid), token), 403, 'anonymous / foreign submission');
  }
  check(await commit(submission('no-image', owner.uid).slice(0, 1), owner.token), 403, 'image required');
  check(await commit(submission('orphan', owner.uid).slice(1), owner.token), 403, 'no orphan image');
  for (const [name, extra, proof] of [
    ['preapproved', {status: str('approved')}, {}], ['amount', {amount: int(-1)}, {}],
    ['currency', {currency: str('EUR')}, {}], ['method', {payment_method: str('anything')}, {}],
    ['oversize', {}, {base64: str('A'.repeat(800004))}], ['mime', {}, {mime_type: str('image/svg+xml')}],
    ['base64', {}, {base64: str('<script>')}], ['byte-size', {}, {byte_length: int(600001)}],
  ]) check(await commit(submission(name, owner.uid, extra, proof), owner.token), 403, name);
  check(await http(image(id), owner.token, 'PATCH', {fields: {base64: str('AAAA')}}), 403, 'immutable image');
  check(await http(request(id), owner.token, 'DELETE'), 403, 'immutable request');
  async function query(token, uid) {
    return http(':runQuery', token, 'POST', {structuredQuery: {from: [{collectionId: 'payment_requests'}],
      ...(uid ? {where: {fieldFilter: {field: {fieldPath: 'user_uid'}, op: 'EQUAL', value: str(uid)}}} : {})}});
  }
  check(await query(owner.token, owner.uid), 200, 'own history query');
  check(await query(owner.token), 403, 'no unscoped member query');
  check(await query(other.token, owner.uid), 403, 'no foreign history query');
  check(await query(admin.token), 200, 'admin queue query');
  function approval(id, uid, count = 0, previous) {
    const txId = `proof_${id}`, end = '2090-10-01T23:59:59Z';
    return [write(`user/${uid}`, {end_sub: time(end), method: str('moncash'), member_time: int(count + 1)}, {mask: true, stamp: 'updated_time'}),
      write(`payment_transactions/${txId}`, {user_ref: ref(`user/${uid}`), user_uid: str(uid), receipt_code: str(`CH-${txId}`),
        transaction_type: str(previous ? 'renewal' : 'subscription'), ...(previous ? {previous_end_sub: time(previous)} : {}),
        new_end_sub: time(end), amount: int(2000), currency: str('GDS'), payment_method: str('moncash'),
        member_time_before: int(count), member_time_after: int(count + 1), created_by: str(admin.uid)}, {stamp: 'created_at'}),
      write(`payment_requests/${id}`, {status: str('approved'), transaction_id: str(txId),
        amount: int(2000), currency: str('GDS'), payment_method: str('moncash'),
        new_end_sub: time(end), reviewed_by: str(admin.uid)}, {mask: true, stamp: 'reviewed_at'})];
  }
  const approve = approval(id, owner.uid);
  check(await commit(approve, owner.token), 403, 'member cannot self-approve');
  check(await commit(approve.slice(2), admin.token), 403, 'approval requires receipt + profile');
  check(await commit(approve.slice(1), admin.token), 403, 'approval requires profile update');
  const mismatch = structuredClone(approve); mismatch[1].update.fields.amount = int(10);
  check(await commit(mismatch, admin.token), 403, 'amount must match proof request');
  check(await commit(approve, admin.token), 200, 'atomic approval, payment, VIP');
  check(await commit(approve, admin.token), 403, 'double approval denied');
  assert.equal((await fields(request(id), owner.token)).status.stringValue, 'approved');
  assert.equal((await fields(profile(owner.uid), owner.token)).member_time.integerValue, '1');
  check(await http(`/payment_transactions/proof_${id}`, owner.token), 200, 'receipt visible in existing history');
  check(await http(`/payment_transactions/proof_${id}`, other.token), 403, 'receipt private');
  const previous = '2090-09-01T23:59:59Z';
  check(await commit([write(`user/${legacy.uid}`, {end_sub: time(previous)}, {mask: true})], legacy.token), 200, 'legacy completion');
  check(await commit(submission('legacy-request', legacy.uid, {
    amount: int(2000), currency: str('GDS'), payment_method: str('moncash'), payment_reference: str('MC-123456')
  }), legacy.token), 200, 'legacy detailed submission remains compatible');
  check(await commit(approval('legacy-request', legacy.uid, 0, previous), admin.token), 200, 'legacy renewal');
  check(await commit(submission('rejected-request', owner.uid), owner.token), 200, 'second request');
  const rejection = reason => [write('payment_requests/rejected-request', {
    status: str('rejected'), rejection_reason: str(reason), reviewed_by: str(admin.uid)}, {mask: true, stamp: 'reviewed_at'})];
  check(await commit(rejection(''), admin.token), 403, 'rejection needs reason');
  check(await commit(rejection('Illisible'), other.token), 403, 'foreign review denied');
  check(await commit(rejection('Illisible'), admin.token), 200, 'reject with reason');
  assert.equal((await fields(request('rejected-request'), owner.token)).rejection_reason.stringValue, 'Illisible');
  check(await commit(approval('rejected-request', owner.uid, 1), admin.token), 403, 'cannot approve rejected request');
  check(await http('/payment_transactions/proof_rejected-request', admin.token), 404, 'rejection records no payment');
  check(await commit(submission('resubmitted', owner.uid), owner.token), 200, 'resubmit after rejection');
  check(await http(profile(owner.uid), owner.token, 'DELETE'), 200, 'profile deleted after request');
  check(await commit(approval('resubmitted', owner.uid, 1), admin.token), 403, 'missing profile prevents approval');
  console.log('Payment proof rules: full client/admin flow passed.');
}
