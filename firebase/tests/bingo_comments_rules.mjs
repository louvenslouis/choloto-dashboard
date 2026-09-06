import assert from 'node:assert/strict';

const projectId = process.env.GCLOUD_PROJECT || 'demo-choloto';
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const documentsUrl =
  `http://${firestoreHost}/v1/projects/${projectId}/databases/(default)/documents`;

async function createUser(label, email = `${label}@dashboard.test`) {
  const response = await fetch(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({
        email,
        password: 'dashboard-comment-test-password',
        returnSecureToken: true,
      }),
    },
  );
  const body = await response.json();
  assert.equal(response.status, 200, JSON.stringify(body));
  return {uid: body.localId, token: body.idToken};
}

async function documentRequest(
  path,
  {method = 'GET', token, fields, updateMask = []} = {},
) {
  const maskQuery = updateMask
    .map((field) => `updateMask.fieldPaths=${encodeURIComponent(field)}`)
    .join('&');
  const url = `${documentsUrl}/${path}${maskQuery ? `?${maskQuery}` : ''}`;
  const response = await fetch(url, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(token ? {authorization: `Bearer ${token}`} : {}),
    },
    body: fields ? JSON.stringify({fields}) : undefined,
  });
  return {status: response.status, body: await response.text()};
}

async function commentsQuery(bingoId, {token, aggregate = false} = {}) {
  const endpoint = aggregate ? 'runAggregationQuery' : 'runQuery';
  const structuredQuery = {
    from: [{collectionId: 'comments'}],
    orderBy: aggregate
      ? undefined
      : [
          {
            field: {fieldPath: 'updatedAt'},
            direction: 'DESCENDING',
          },
        ],
  };
  const body = aggregate
    ? {
        structuredAggregationQuery: {
          structuredQuery,
          aggregations: [{alias: 'count', count: {}}],
        },
      }
    : {structuredQuery};
  const response = await fetch(
    `${documentsUrl}/bingo/${bingoId}:${endpoint}`,
    {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        ...(token ? {authorization: `Bearer ${token}`} : {}),
      },
      body: JSON.stringify(body),
    },
  );
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
const booleanValue = (value) => ({booleanValue: value});
const timestampValue = (value) => ({timestampValue: value});

const admin = await createUser('admin', 'sanonmaeva064@gmail.com');
const owner = await createUser('owner');
const other = await createUser('other');
const bingoId = 'dashboard-comments-bingo';

expectStatus(
  await documentRequest(`bingo/${bingoId}`, {
    method: 'PATCH',
    token: admin.token,
    fields: {
      date: timestampValue('2026-08-23T12:00:00Z'),
      expiration: timestampValue('2026-08-24T12:00:00Z'),
    },
  }),
  200,
  'admin Bingo creation',
);

const commentPath = `bingo/${bingoId}/comments/${owner.uid}`;
const firstModernCommentPath =
  `bingo/${bingoId}/comments/comment_a11ce000-0000-4000-8000-000000000001`;
const secondModernCommentPath =
  `bingo/${bingoId}/comments/comment_a11ce000-0000-4000-8000-000000000002`;
const hiddenModernCommentPath =
  `bingo/${bingoId}/hiddenComments/comment_a11ce000-0000-4000-8000-000000000001`;
const commentFields = {
  user: stringValue(owner.uid),
  text: stringValue('Mwen te genyen avèk CHOLOTO.'),
  createdAt: timestampValue('2026-08-23T12:05:00Z'),
  updatedAt: timestampValue('2026-08-23T12:05:00Z'),
};

expectStatus(
  await documentRequest(commentPath, {
    method: 'PATCH',
    token: owner.token,
    fields: commentFields,
  }),
  200,
  'owner comment creation',
);
expectStatus(
  await documentRequest(firstModernCommentPath, {
    method: 'PATCH',
    token: owner.token,
    fields: {
      ...commentFields,
      text: stringValue('Premye kòmantè modèn.'),
      updatedAt: timestampValue('2026-08-23T12:05:30Z'),
    },
  }),
  200,
  'first modern comment creation',
);
expectStatus(
  await documentRequest(secondModernCommentPath, {
    method: 'PATCH',
    token: owner.token,
    fields: {
      ...commentFields,
      text: stringValue('Dezyèm kòmantè sou menm BINGO a.'),
      createdAt: timestampValue('2026-08-23T12:05:45Z'),
      updatedAt: timestampValue('2026-08-23T12:05:45Z'),
    },
  }),
  200,
  'second modern comment creation by the same owner',
);
expectStatus(
  await documentRequest(`bingo/${bingoId}/comments/${other.uid}`, {
    method: 'PATCH',
    token: owner.token,
    fields: commentFields,
  }),
  403,
  'modern owner cannot reserve another uid legacy comment path',
);
expectStatus(
  await documentRequest(
    `bingo/${bingoId}/comments/comment_a11ce000-0000-4000-8000-000000000003`,
    {
      method: 'PATCH',
      token: owner.token,
      fields: {...commentFields, user: stringValue(other.uid)},
    },
  ),
  403,
  'modern comment cannot spoof its owner field',
);
expectStatus(
  await documentRequest(commentPath, {token: owner.token}),
  200,
  'owner comment read',
);
expectStatus(
  await documentRequest(commentPath, {
    method: 'PATCH',
    token: owner.token,
    updateMask: ['adminLiked', 'adminLikedAt', 'adminLikedBy'],
    fields: {
      adminLiked: booleanValue(true),
      adminLikedAt: timestampValue('2026-08-23T12:06:00Z'),
      adminLikedBy: stringValue(owner.uid),
    },
  }),
  403,
  'owner cannot forge the CHOLOTO like',
);
expectStatus(
  await documentRequest(commentPath, {
    method: 'PATCH',
    token: admin.token,
    updateMask: ['adminLiked', 'adminLikedAt', 'adminLikedBy'],
    fields: {
      adminLiked: booleanValue(true),
      adminLikedAt: timestampValue('2026-08-23T12:06:00Z'),
      adminLikedBy: stringValue(admin.uid),
    },
  }),
  200,
  'admin comment like',
);
expectStatus(
  await documentRequest(commentPath, {
    method: 'PATCH',
    token: admin.token,
    updateMask: ['adminReply', 'adminReplyAt', 'adminReplyBy'],
    fields: {
      adminReply: stringValue('Merci pour votre message !'),
      adminReplyAt: timestampValue('2026-08-23T12:07:00Z'),
      adminReplyBy: stringValue(admin.uid),
    },
  }),
  200,
  'admin comment reply',
);
expectStatus(
  await documentRequest(commentPath, {
    method: 'PATCH',
    token: other.token,
    updateMask: ['adminLiked', 'adminLikedAt', 'adminLikedBy'],
    fields: {
      adminLiked: booleanValue(true),
      adminLikedAt: timestampValue('2026-08-23T12:08:00Z'),
      adminLikedBy: stringValue(other.uid),
    },
  }),
  403,
  'non-admin cannot like a comment',
);
expectStatus(
  await documentRequest(commentPath, {
    method: 'PATCH',
    token: owner.token,
    updateMask: ['text', 'updatedAt'],
    fields: {
      text: stringValue('Mwen genyen ankò avèk CHOLOTO.'),
      updatedAt: timestampValue('2026-08-23T12:09:00Z'),
    },
  }),
  200,
  'owner can edit text while preserving admin interactions',
);
expectStatus(
  await documentRequest(secondModernCommentPath, {
    method: 'PATCH',
    token: other.token,
    updateMask: ['text', 'updatedAt'],
    fields: {
      text: stringValue('Tentative étrangère.'),
      updatedAt: timestampValue('2026-08-23T12:09:30Z'),
    },
  }),
  403,
  'non-owner cannot edit a modern comment',
);
expectStatus(
  await documentRequest(secondModernCommentPath, {
    method: 'PATCH',
    token: owner.token,
    updateMask: ['text', 'updatedAt'],
    fields: {
      text: stringValue('Dezyèm kòmantè a korije.'),
      updatedAt: timestampValue('2026-08-23T12:09:45Z'),
    },
  }),
  200,
  'owner can edit a modern comment',
);
expectStatus(
  await documentRequest(commentPath, {
    method: 'PATCH',
    token: admin.token,
    updateMask: ['text'],
    fields: {
      text: stringValue('Administrators cannot rewrite member comments.'),
    },
  }),
  403,
  'admin cannot rewrite member comment text',
);
expectStatus(
  await documentRequest(secondModernCommentPath, {
    method: 'DELETE',
    token: other.token,
  }),
  403,
  'non-owner cannot delete a modern comment',
);
expectStatus(
  await documentRequest(secondModernCommentPath, {method: 'DELETE'}),
  403,
  'signed-out user cannot delete a modern comment',
);
expectStatus(
  await documentRequest(secondModernCommentPath, {
    method: 'DELETE',
    token: owner.token,
  }),
  200,
  'owner can delete a modern comment',
);
expectStatus(
  await documentRequest(secondModernCommentPath),
  404,
  'deleted modern comment is absent',
);

const hiddenCommentFields = {
  ...commentFields,
  text: stringValue('Premye kòmantè modèn.'),
  updatedAt: timestampValue('2026-08-23T12:05:30Z'),
  hiddenAt: timestampValue('2026-08-23T12:10:00Z'),
  hiddenBy: stringValue(admin.uid),
};
expectStatus(
  await documentRequest(hiddenModernCommentPath, {
    method: 'PATCH',
    token: other.token,
    fields: hiddenCommentFields,
  }),
  403,
  'non-admin cannot archive a comment',
);
expectStatus(
  await documentRequest(hiddenModernCommentPath, {
    method: 'PATCH',
    token: admin.token,
    fields: hiddenCommentFields,
  }),
  200,
  'admin archives a comment',
);
expectStatus(
  await documentRequest(firstModernCommentPath, {
    method: 'DELETE',
    token: admin.token,
  }),
  200,
  'admin removes the archived comment from the public collection',
);
expectStatus(
  await documentRequest(hiddenModernCommentPath, {token: admin.token}),
  200,
  'admin reads a hidden comment',
);
expectStatus(
  await documentRequest(hiddenModernCommentPath, {token: owner.token}),
  403,
  'comment owner cannot read the private moderation archive',
);
expectStatus(
  await documentRequest(hiddenModernCommentPath),
  403,
  'signed-out user cannot read the private moderation archive',
);
expectStatus(
  await documentRequest(commentPath, {token: other.token}),
  200,
  'public anonymous comment read',
);
expectStatus(
  await documentRequest(commentPath),
  200,
  'signed-out public comment read',
);
expectStatus(
  await commentsQuery(bingoId, {token: admin.token}),
  200,
  'dashboard ordered comment query',
);
expectStatus(
  await commentsQuery(bingoId, {token: admin.token, aggregate: true}),
  200,
  'dashboard comment count query',
);
expectStatus(
  await commentsQuery(bingoId, {token: other.token}),
  200,
  'public comment list query',
);
expectStatus(
  await commentsQuery(bingoId),
  200,
  'signed-out public comment list query',
);
expectStatus(
  await commentsQuery(bingoId, {token: other.token, aggregate: true}),
  200,
  'public comment count query',
);

const ownerLikePath = `${commentPath}/likes/${owner.uid}`;
expectStatus(
  await documentRequest(ownerLikePath, {
    method: 'PATCH',
    token: owner.token,
    fields: {
      createdAt: timestampValue('2026-08-23T12:10:00Z'),
    },
  }),
  200,
  'owner likes a public comment',
);
expectStatus(
  await documentRequest(ownerLikePath, {token: other.token}),
  200,
  'comment likes are publicly readable',
);
expectStatus(
  await documentRequest(ownerLikePath, {
    method: 'PATCH',
    token: other.token,
    fields: {
      createdAt: timestampValue('2026-08-23T12:11:00Z'),
    },
  }),
  403,
  'another user cannot overwrite an existing like',
);
const otherLikePath = `${commentPath}/likes/${other.uid}`;
expectStatus(
  await documentRequest(otherLikePath, {
    method: 'PATCH',
    token: other.token,
    fields: {
      createdAt: timestampValue('2026-08-23T12:12:00Z'),
    },
  }),
  200,
  'another user likes the public comment',
);
expectStatus(
  await documentRequest(otherLikePath, {
    method: 'DELETE',
    token: other.token,
  }),
  200,
  'user removes their own like',
);

expectStatus(
  await documentRequest(firstModernCommentPath, {
    method: 'PATCH',
    token: admin.token,
    fields: {
      ...commentFields,
      text: stringValue('Premye kòmantè modèn.'),
      updatedAt: timestampValue('2026-08-23T12:05:30Z'),
    },
  }),
  200,
  'admin restores a hidden comment to the public collection',
);
expectStatus(
  await documentRequest(hiddenModernCommentPath, {
    method: 'DELETE',
    token: admin.token,
  }),
  200,
  'admin removes the restored comment from the moderation archive',
);
expectStatus(
  await documentRequest(firstModernCommentPath),
  200,
  'restored comment is publicly readable again',
);
expectStatus(
  await documentRequest(commentPath, {
    method: 'DELETE',
    token: other.token,
  }),
  403,
  'non-owner cannot delete a legacy comment',
);
expectStatus(
  await documentRequest(commentPath, {
    method: 'DELETE',
    token: owner.token,
  }),
  200,
  'owner can delete a legacy comment',
);
expectStatus(
  await documentRequest(commentPath),
  404,
  'deleted legacy comment is absent',
);

console.log('Dashboard Bingo comment rules checks passed.');
