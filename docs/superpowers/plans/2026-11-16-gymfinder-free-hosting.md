# GymFinder Free Hosting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish the existing GymFinder Next.js app from GitHub on free Render hosting with a durable free Neon PostgreSQL database.

**Architecture:** Render runs the Node.js Next.js server and automatically deploys the public GitHub `main` branch; the free web service may sleep while idle. Neon provides PostgreSQL separately so Render's expiring free database is not used. Existing SQL migrations and seed files initialize the new database once using a migration ledger.

**Tech Stack:** Next.js 16, Node.js 24, PostgreSQL, `pg`, Render Blueprint (`render.yaml`), Neon Postgres.

**Spec:** `docs/superpowers/specs/2026-11-16-gymfinder-free-hosting-design.md`

## Global Constraints

- Keep the deployment on free tiers; do not create paid resources.
- Keep `.env.local`, `.local-db/`, `.next/`, `node_modules/`, passwords, database URLs, and Gemini keys out of GitHub.
- The selected GitHub repository is public; committed app code and SQL seed data will be public.
- Preserve the Next.js API, authentication, gym catalog, map, reviews, favorites, and Gemini fallback.
- Use the existing SQL migrations/seeds in their current dependency order; do not copy local accounts, sessions, favorites, or chat history.
- Do not print or place any secrets in a command, commit, artifact, report, or chat message.

## Review Focus

1. Missing or malformed `PORT` must not prevent Render from binding the public web port; test valid and fallback values in Task 1.
2. The Render HTTPS origin must pass API Origin checks and set secure auth cookies; test explicit `APP_ORIGIN`, hosted origin fallback, and local default in Task 1.
3. Repeated or concurrent migration runs must not duplicate seed rows or generated terms; test two successive runs against a fresh local QA database in Task 2.
4. A database connection failure must stop before publishing a broken app and must not leak the URL; test missing/invalid `DATABASE_URL` and verify an intentionally failed connection reports only a safe message in Task 2.
5. The public app must use the Neon connection string at runtime, while local `npm run site:start` remains bound to loopback; verify both launch modes and production HTTP/API behavior in Tasks 1 and 5.

## File Map

- `scripts/start-render.mjs`: launch Next.js on Render's public interface and assigned port.
- `src/lib/runtime-origin.ts`: derive the expected site origin from explicit configuration, Render's public URL, or local default.
- `src/app/api/[...path]/route.ts`: use the derived origin for Origin validation and cookie security.
- `scripts/migrate-hosted-db.mjs`: apply the existing migrations and seed files exactly once per target database.
- `render.yaml`: configure the free Node service, build, start, health check, and required runtime variables.
- `package.json`: expose hosted start and database migration commands.
- `tests/runtime-origin.test.ts`, `tests/start-render.test.ts`, `tests/hosted-db.test.ts`: pin runtime and migration behavior.
- `README.md`: explain one-time Render/Neon setup, required secrets, and free-tier cold starts.

---

### Task 1: Hosted process and origin configuration

**Files:**
- Create: `src/lib/runtime-origin.ts`
- Create: `scripts/start-render.mjs`
- Modify: `src/app/api/[...path]/route.ts`
- Modify: `package.json`
- Test: `tests/runtime-origin.test.ts`, `tests/start-render.test.ts`

**Interfaces:**
- `getSiteOrigin(env)` returns `APP_ORIGIN`, then `RENDER_EXTERNAL_URL`, then `http://127.0.0.1:3000`.
- `getRenderPort(value)` returns a valid integer port in `1..65535`, otherwise `3000`.
- Render start launches `next start -H 0.0.0.0 -p <port>`; local `start` and `site:start` commands retain loopback behavior.

- [ ] Write tests for explicit/Render/local origin selection, secure-cookie origin, valid Render port, and invalid-port fallback.
- [ ] Run the two new test files and confirm the cases fail before implementation.
- [ ] Implement the origin helper and Render launcher; use the origin helper in the API route and add `start:render` to `package.json`.
- [ ] Run the focused tests, all unit tests, lint, and typecheck; expected: all pass and local launch behavior is unchanged.
- [ ] Commit as `feat: add hosted Render runtime configuration`.

### Task 2: Idempotent hosted PostgreSQL initialization

**Files:**
- Create: `scripts/migrate-hosted-db.mjs`
- Modify: `package.json`
- Test: `tests/hosted-db.test.ts`

**Interfaces:**
- `npm run db:migrate` reads only `DATABASE_URL`, exits with a safe error if it is absent/invalid, and never prints it.
- A migration ledger in `public` records the ordered files: `001_schema.sql`, `002_views_indexes.sql`, `10_real_gyms.sql`, `20_demo_activity.sql`, then `003_web.sql` through `006_verified_venues.sql`.
- All outstanding files and ledger entries apply in one transaction guarded by `pg_advisory_xact_lock`; this also works with Neon's transaction-mode pooler and prevents overlapping builds from interleaving migrations.

- [ ] Write tests proving ordered application, already-applied migration skipping, safe missing-URL failure, and safe connection failure.
- [ ] Run the focused tests and confirm they fail before implementation.
- [ ] Implement the ledger, transaction-scoped advisory lock, one atomic migration transaction, and safe error handling without editing seed files.
- [ ] Run `npm run db:migrate` twice against a fresh throwaway local PostgreSQL database; assert 70 gyms, 1060 plans, 14 published prices, then identical counts after the second run.
- [ ] Run all unit tests, lint, typecheck, and production build; expected: all pass and the existing local database remains unchanged.
- [ ] Commit as `feat: add idempotent hosted database migrations`.

### Task 3: Render Blueprint and deployment instructions

**Files:**
- Create: `render.yaml`
- Modify: `README.md`

- [ ] Add a Render free Node web service with `npm ci && npm run db:migrate && npm run build`, `npm run start:render`, `/api/gyms` health check, and `DATABASE_URL`/`GEMINI_API_KEY` marked as dashboard-supplied secrets.
- [ ] Document Neon project setup, use of its pooled Postgres URL, Render environment values, GitHub auto-deploy, first-request delay, free quota behavior, and verification steps.
- [ ] Review the Blueprint and README for paid resources, secrets, local-only paths, and incorrect claims; expected: no paid plan or credential is included.
- [ ] Run `npm test`, `npm run lint`, `npm run typecheck`, `npm run build`, and the local API checks; expected: all pass.
- [ ] Commit as `docs: configure free Render and Neon deployment`.

### Task 4: Publish source to the empty GitHub repository

**Files:**
- Publish project root to: `https://github.com/diasbelaev-ship-it/sql-.git` on `main`.

- [ ] Initialize Git inside `gymfinder-almaty-sql` only; do not change the parent workspace repository.
- [ ] Make a local baseline import commit after checking the exact tracked files; use it as the task/branch base, but do not push it separately.
- [ ] Inspect the exact staged file list and verify `.env.local`, `.local-db/`, `.next/`, `node_modules/`, credentials, logs, and generated archives are absent.
- [ ] Commit and push the verified source to the empty public repository without force-pushing or rewriting any existing ref.
- [ ] Verify GitHub `main` points to the pushed commit and the `render.yaml`, migrations, seeds, and application source are present.

### Task 5: Provision free services and verify the live site

**Services:** Render Free web service; Neon Free PostgreSQL project; public GitHub `main` source.

- [ ] Connect the repository to Render and provision Neon in the closest shared Asia region available.
- [ ] Enter the Neon pooled `DATABASE_URL` and Gemini key directly into Render's secret fields; set `AI_PROVIDER=gemini` and `GEMINI_MODEL=gemini-3.5-flash-lite`. Do not put values in GitHub or this chat.
- [ ] Deploy the Blueprint and wait for successful database initialization and production deployment.
- [ ] Verify the public home page, `/api/gyms` returns 70 gyms, registration/login, one favorite operation, map results, and one Gemini response; verify `APP_ORIGIN` and HTTPS auth cookies.
- [ ] Record the production URL and clearly report any provider/account step that requires the user to sign in or complete manually.

## Self-Review

- The design's constraints map to Tasks 1–5; the hosting provider and data provider are separate because Render's free Postgres expires.
- Each failure mode in Review Focus has explicit tests or production verification in its owning task.
- The local launcher remains separate from the hosted launcher, so the current Windows startup flow is preserved.
- This is an implementation plan only. No source or deployment resource is created until the user approves it.

