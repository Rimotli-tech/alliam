const toolsRoot =
  "C:/Users/rimot/AppData/Local/npm-cache/_npx/7750544ccf494d8b/node_modules/firebase-tools/lib";
const { configstore } = require(`${toolsRoot}/configstore`);
const auth = require(`${toolsRoot}/auth`);

const projectId = "spelliam-ad3fd";
const email = process.argv[2]?.trim().toLowerCase();
const apply = process.argv.includes("--apply");

if (!email) throw new Error("An email address is required.");

function valueOf(field) {
  if (!field) return undefined;
  return Object.values(field)[0];
}

function fields(values) {
  return Object.fromEntries(
    Object.entries(values).map(([key, value]) => {
      if (value instanceof Date) return [key, { timestampValue: value.toISOString() }];
      if (typeof value === "boolean") return [key, { booleanValue: value }];
      if (typeof value === "number") return [key, { integerValue: String(value) }];
      if (Array.isArray(value)) {
        return [key, { arrayValue: { values: value.map((item) => ({ stringValue: item })) } }];
      }
      if (value && typeof value === "object") {
        return [key, { mapValue: { fields: fields(value) } }];
      }
      return [key, { stringValue: value ?? "" }];
    }),
  );
}

async function request(url, token, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
      ...(options.headers ?? {}),
    },
  });
  if (!response.ok) {
    throw new Error(`${response.status} ${await response.text()}`);
  }
  return response.status === 204 ? null : response.json();
}

async function patchDocument(token, path, values, masks) {
  const query = masks
    .map((mask) => `updateMask.fieldPaths=${encodeURIComponent(mask)}`)
    .join("&");
  return request(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${path}?${query}`,
    token,
    {
      method: "PATCH",
      body: JSON.stringify({ fields: fields(values) }),
    },
  );
}

async function main() {
  const refreshToken = configstore.get("tokens")?.refresh_token;
  if (!refreshToken) throw new Error("Firebase CLI is not signed in.");
  const token = (await auth.getAccessToken(refreshToken, [])).access_token;
  const lookup = await request(
    `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:lookup`,
    token,
    { method: "POST", body: JSON.stringify({ email: [email] }) },
  );
  const user = lookup.users?.[0];
  if (!user) throw new Error(`No Firebase Auth user exists for ${email}.`);

  const accountUrl =
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/accounts/${user.localId}`;
  let account;
  try {
    account = await request(accountUrl, token);
  } catch (error) {
    if (!String(error.message).startsWith("404 ")) throw error;
  }
  const currentRole = valueOf(account?.fields?.role) ?? "missing";
  const organizationName =
    valueOf(account?.fields?.organizationName) ||
    valueOf(account?.fields?.schoolName) ||
    user.displayName ||
    email.split("@")[0];

  if (!apply) {
    console.log(
      JSON.stringify({
        email,
        uid: user.localId,
        currentRole,
        organizationName,
      }),
    );
    return;
  }

  const now = new Date();
  await patchDocument(
    token,
    `accounts/${user.localId}`,
    {
      role: "organization",
      schemaVersion: 3,
      organizationId: user.localId,
      organizationName,
      updatedAt: now,
    },
    ["role", "schemaVersion", "organizationId", "organizationName", "updatedAt"],
  );
  await patchDocument(
    token,
    `accounts/${user.localId}/data/app-state`,
    { value: { accountType: "organization" }, updatedAt: now },
    ["value.accountType", "updatedAt"],
  );
  await patchDocument(
    token,
    `organizations/${user.localId}`,
    {
      id: user.localId,
      name: organizationName,
      country: "Nigeria",
      ownerUid: user.localId,
      status: "active",
      createdAt: now,
      updatedAt: now,
    },
    ["id", "name", "country", "ownerUid", "status", "createdAt", "updatedAt"],
  );
  await patchDocument(
    token,
    `organizations/${user.localId}/members/${user.localId}`,
    {
      uid: user.localId,
      email,
      displayName: user.displayName || organizationName,
      role: "owner",
      permissions: {
        manageLearners: true,
        manageTeams: true,
        manageCompetitions: true,
        manageMembers: true,
        manageOrganization: true,
      },
      status: "active",
      createdAt: now,
      updatedAt: now,
    },
    [
      "uid",
      "email",
      "displayName",
      "role",
      "permissions",
      "status",
      "createdAt",
      "updatedAt",
    ],
  );
  console.log(
    JSON.stringify({
      email,
      uid: user.localId,
      previousRole: currentRole,
      role: "organization",
      organizationId: user.localId,
    }),
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
