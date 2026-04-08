const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

let initialized = false;

function resolveServiceAccountPath() {
  const configured = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!configured) return null;
  if (path.isAbsolute(configured)) return configured;
  return path.resolve(process.cwd(), configured);
}

function readServiceAccountFromEnv() {
  const rawJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (rawJson && rawJson.trim()) {
    return JSON.parse(rawJson);
  }

  const base64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  if (base64 && base64.trim()) {
    const decoded = Buffer.from(base64, 'base64').toString('utf8');
    return JSON.parse(decoded);
  }

  return null;
}

function ensureInitialized() {
  if (initialized || admin.apps.length) {
    initialized = true;
    return;
  }

  let serviceAccount = readServiceAccountFromEnv();
  if (!serviceAccount) {
    const serviceAccountPath = resolveServiceAccountPath();
    if (!serviceAccountPath) {
      throw new Error(
        'Firebase service account missing. Set FIREBASE_SERVICE_ACCOUNT_JSON (recommended) or FIREBASE_SERVICE_ACCOUNT_PATH.'
      );
    }
    if (!fs.existsSync(serviceAccountPath)) {
      throw new Error(`Firebase service account not found at ${serviceAccountPath}`);
    }
    serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
  }

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  initialized = true;
}

function toStringMap(input) {
  const out = {};
  if (!input || typeof input !== 'object') return out;
  for (const [k, v] of Object.entries(input)) {
    if (v === undefined || v === null) continue;
    out[k] = String(v);
  }
  return out;
}

async function sendToTokens(tokens, payload) {
  ensureInitialized();

  const uniqueTokens = [...new Set((tokens || []).filter(Boolean))];
  if (!uniqueTokens.length) {
    return { sentCount: 0, failureCount: 0, invalidTokens: [] };
  }

  const messagePayload = {
    notification: {
      title: payload.title,
      body: payload.body
    },
    data: toStringMap(payload.data),
    android: { priority: 'high' },
    apns: {
      payload: {
        aps: {
          sound: 'default'
        }
      }
    }
  };

  if (payload.imageUrl) {
    messagePayload.notification.imageUrl = payload.imageUrl;
  }

  let sentCount = 0;
  let failureCount = 0;
  const invalidTokens = [];

  for (let i = 0; i < uniqueTokens.length; i += 500) {
    const chunk = uniqueTokens.slice(i, i + 500);
    const response = await admin.messaging().sendEachForMulticast({
      tokens: chunk,
      ...messagePayload
    });

    sentCount += response.successCount;
    failureCount += response.failureCount;

    response.responses.forEach((r, index) => {
      if (!r.error) return;
      const code = r.error.code || '';
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        invalidTokens.push(chunk[index]);
      }
    });
  }

  return {
    sentCount,
    failureCount,
    invalidTokens: [...new Set(invalidTokens)]
  };
}

module.exports = {
  sendToTokens
};
