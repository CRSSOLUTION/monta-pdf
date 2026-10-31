# apple-revoke (Cloudflare Worker)

Revokes the user's Sign in with Apple token when they delete their account
(App Store guideline 5.1.1(v)). Stateless: nothing is stored.

`POST /` with `{"authorizationCode": "<fresh code from Sign in with Apple>"}`
→ `200 {"revoked": true}` or an error JSON.

## Deploy (dashboard)
1. Cloudflare → Compute → Workers & Pages → Create → Start with Hello World.
2. Name: `montapdf-apple-revoke` → Deploy → Edit code → paste `worker.js` → Deploy.
3. Settings → Variables and Secrets → add:
   - `APPLE_PRIVATE_KEY` (Secret): contents of the `.p8` file, with BEGIN/END lines
   - `APPLE_KEY_ID` (Text): Key ID of the `.p8`
   - `APPLE_TEAM_ID` (Text): `9796AVNA2V`
   - `APPLE_CLIENT_ID` (Text): `com.crlsribeiro.MontaPDF`
4. The `.p8` key must have **Sign in with Apple** enabled and include the
   `com.crlsribeiro.MontaPDF` App ID (directly or grouped with its primary App ID).
