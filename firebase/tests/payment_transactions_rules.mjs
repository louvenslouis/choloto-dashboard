import assert from 'node:assert/strict';

const projectId = process.env.GCLOUD_PROJECT || 'demo-choloto';
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const documentsUrl =
  `http://${firestoreHost}/v1/projects/${projectId}/databases/(default)/documents`;
const documentName = (path) =>
  `projects/${projectId}/databases/(default)/documents/${path}`;

async function createUser(label, email = `${label}@payments.test`) {
  const response = await fetch(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({
        email,
        password: 'payment-transaction-test-password',
        returnSecureToken: true,
      }),
    },
  );
  const body = await response.json();
  assert.equal(response.status, 200, JSON.stringify(body));
  return {uid: body.localId, token: body.idToken};
}

async function request(url, {method = 'GET', token, body} = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(token ? {authorization: `Bearer ${token}`} : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return {status: response.status, body: await response.text()};
}

function expectStatus(result, expected, label) {
  assert.equal(
    result.status,
    expected,
    `${label}: expected HTTP ${expected}, received ${result.status}\n${result.body}`,
  );
}

const stringValue = (value) => ({stringValue: value});
const integerValue = (value) => ({integerValue: String(value)});
const timestampValue = (value) => ({timestampValue: value});

const admin = await createUser('admin', 'sanonmaeva064@gmail.com');
const owner = await createUser('owner');
const other = await createUser('other');

const transactionId = 'owner-payment-transaction';
const transactionPath = `payment_transactions/${transactionId}`;

expectStatus(
  await request(`${documentsUrl}:commit`, {
    method: 'POST',
    token: admin.token,
    body: {
      writes: [
        {
          update: {
            name: documentName(transactionPath),
            fields: {
              user_ref: {referenceValue: documentName(`user/${owner.uid}`)},
              user_uid: stringValue(owner.uid),
              receipt_code: stringValue(`CH-${transactionId}`),
              transaction_type: stringValue('renewal'),
              new_end_sub: timestampValue('2026-09-30T12:00:00Z'),
              payment_method: stringValue('moncash'),
              amount: {doubleValue: 40},
              currency: stringValue('USD'),
              member_time_before: integerValue(1),
              member_time_after: integerValue(2),
              created_by: stringValue(admin.uid),
            },
          },
          updateTransforms: [
            {fieldPath: 'created_at', setToServerValue: 'REQUEST_TIME'},
          ],
        },
      ],
    },
  }),
  200,
  'admin transaction creation',
);

expectStatus(
  await request(`${documentsUrl}/${transactionPath}`, {token: owner.token}),
  200,
  'owner transaction read',
);
expectStatus(
  await request(`${documentsUrl}/${transactionPath}`, {token: other.token}),
  403,
  'foreign transaction read',
);
expectStatus(
  await request(`${documentsUrl}/${transactionPath}`),
  403,
  'unauthenticated transaction read',
);

const ownerQuery = {
  structuredQuery: {
    from: [{collectionId: 'payment_transactions'}],
    where: {
      fieldFilter: {
        field: {fieldPath: 'user_uid'},
        op: 'EQUAL',
        value: stringValue(owner.uid),
      },
    },
  },
};
expectStatus(
  await request(`${documentsUrl}:runQuery`, {
    method: 'POST',
    token: owner.token,
    body: ownerQuery,
  }),
  200,
  'owner scoped transaction query',
);
expectStatus(
  await request(`${documentsUrl}:runQuery`, {
    method: 'POST',
    token: other.token,
    body: ownerQuery,
  }),
  403,
  'foreign scoped transaction query',
);
expectStatus(
  await request(`${documentsUrl}:runQuery`, {
    method: 'POST',
    token: owner.token,
    body: {
      structuredQuery: {
        from: [{collectionId: 'payment_transactions'}],
      },
    },
  }),
  403,
  'owner unscoped transaction query',
);
expectStatus(
  await request(`${documentsUrl}:runQuery`, {
    method: 'POST',
    token: admin.token,
    body: {
      structuredQuery: {
        from: [{collectionId: 'payment_transactions'}],
      },
    },
  }),
  200,
  'admin unscoped transaction query',
);
expectStatus(
  await request(`${documentsUrl}/${transactionPath}`, {
    method: 'DELETE',
    token: owner.token,
  }),
  403,
  'owner cannot delete transaction',
);

console.log('Dashboard payment transaction rules checks passed.');

const {testPaymentRequests} = await import('./payment_requests_rules.mjs');
await testPaymentRequests({admin});
