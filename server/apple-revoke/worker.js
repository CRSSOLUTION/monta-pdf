// Monta PDF · Sign in with Apple token revocation
//
// Cloudflare Worker called by the app when the user deletes their account.
// The app sends a fresh authorization code; the worker exchanges it for a
// token and revokes it at Apple, as App Store guideline 5.1.1(v) requires.
// Nothing is stored. The private key never leaves Cloudflare.
//
// Secrets / variables (Worker > Settings > Variables and Secrets):
//   APPLE_PRIVATE_KEY  (secret)  contents of the .p8 file, including the BEGIN/END lines
//   APPLE_KEY_ID       (text)    10-character Key ID of the .p8
//   APPLE_TEAM_ID      (text)    9796AVNA2V
//   APPLE_CLIENT_ID    (text)    com.crlsribeiro.MontaPDF

const APPLE = "https://appleid.apple.com";

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "invalid_json" }, 400);
    }

    const code = body && body.authorizationCode;
    if (typeof code !== "string" || code.length < 10 || code.length > 2048) {
      return json({ error: "missing_authorization_code" }, 400);
    }

    try {
      const clientSecret = await makeClientSecret(env);

      const tokenResponse = await postForm(`${APPLE}/auth/token`, {
        client_id: env.APPLE_CLIENT_ID,
        client_secret: clientSecret,
        code,
        grant_type: "authorization_code",
      });
      if (!tokenResponse.ok) {
        return json({ error: "token_exchange_failed", status: tokenResponse.status }, 502);
      }

      const tokens = await tokenResponse.json();
      const token = tokens.refresh_token || tokens.access_token;
      const hint = tokens.refresh_token ? "refresh_token" : "access_token";
      if (!token) {
        return json({ error: "no_token_returned" }, 502);
      }

      const revokeResponse = await postForm(`${APPLE}/auth/revoke`, {
        client_id: env.APPLE_CLIENT_ID,
        client_secret: clientSecret,
        token,
        token_type_hint: hint,
      });
      if (!revokeResponse.ok) {
        return json({ error: "revoke_failed", status: revokeResponse.status }, 502);
      }

      return json({ revoked: true });
    } catch (error) {
      return json({ error: "internal_error" }, 500);
    }
  },
};

// Apple's client secret: a short-lived JWT signed with the .p8 key (ES256).
async function makeClientSecret(env) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "ES256", kid: env.APPLE_KEY_ID };
  const payload = {
    iss: env.APPLE_TEAM_ID,
    iat: now,
    exp: now + 300,
    aud: APPLE,
    sub: env.APPLE_CLIENT_ID,
  };

  const signingInput = `${base64url(JSON.stringify(header))}.${base64url(JSON.stringify(payload))}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(env.APPLE_PRIVATE_KEY),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  // Web Crypto returns the raw r||s signature, which is the format JWT expects.
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64url(signature)}`;
}

function pemToDer(pem) {
  const base64 = pem
    .replace(/-----BEGIN [^-]+-----/, "")
    .replace(/-----END [^-]+-----/, "")
    .replace(/\s+/g, "");
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

function base64url(input) {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : new Uint8Array(input);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function postForm(url, fields) {
  return fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams(fields),
  });
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
