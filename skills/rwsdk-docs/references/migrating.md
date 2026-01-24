# Migrating from 0.x to 1.x

This guide helps upgrade existing RedwoodSDK projects from version `0.x` to `1.x`.

## Overview

RedwoodSDK 1.x introduces breaking changes that require updates to your project. The most significant changes are:

1. Core packages moved to `peerDependencies`
2. RSC actions now run through middleware pipeline
3. Updated response header usage
4. Removed `resolveSSRValue` wrapper
5. New passkey addon replaces old `standard` starter

**Important:** Your existing code will continue to work with these required migration steps. The passkey addon is optional and recommended for new projects only.

---

## Required Migration Steps

Follow these steps in order to upgrade your project.

### 1. Upgrade rwsdk

Update to the latest version of `rwsdk`:

```sh
pnpm add rwsdk@latest
# or
npm install rwsdk@latest
# or
yarn add rwsdk@latest
```

### 2. Update Dependencies

In version 1.x, core packages like `react` and `wrangler` moved to `peerDependencies`. You must explicitly add them to your `package.json`.

**Add runtime dependencies:**

```sh
pnpm add react@latest react-dom@latest react-server-dom-webpack@latest
```

**Add development dependencies:**

```sh
pnpm add -D @cloudflare/vite-plugin@latest wrangler@latest @cloudflare/workers-types@latest
```

**Install all dependencies:**

```sh
pnpm install
```

### 3. Update Compatibility Date

The Cloudflare Workers runtime requires a newer compatibility date for modern React features.

Update your `wrangler.jsonc`:

```jsonc title="wrangler.jsonc"
{
  "compatibility_date": "2025-08-21"
  // ... rest of config
}
```

**Important:** Set `compatibility_date` to `2025-08-21` or later.

After updating, regenerate type definitions:

```sh
pnpm generate
```

### 4. Review Middleware for RSC Actions

**Breaking Change:** RSC actions now run through the global middleware pipeline.

Previously, action requests bypassed all middleware. Now, your middleware will execute for RSC actions, which may cause unintended side effects.

**What changed:**
- Authentication and session handling now apply consistently
- All global middleware runs for RSC actions
- New `isAction` flag helps conditionally apply logic

**Review your middleware:**

Check each middleware function to ensure it handles RSC actions appropriately.

**Example - Logging middleware:**

```typescript title="src/worker.tsx (BEFORE)"
const loggingMiddleware = ({ request }) => {
  const url = new URL(request.url);
  console.log('Request:', url.pathname); // Logs for EVERYTHING including actions
};
```

```typescript title="src/worker.tsx (AFTER)"
const loggingMiddleware = ({ isAction, request }) => {
  // Skip logging for RSC actions
  if (isAction) {
    return;
  }

  // Only log page requests
  const url = new URL(request.url);
  console.log('Page requested:', url.pathname);
};
```

**Example - Session middleware:**

```typescript title="Session middleware (usually works fine)"
const sessionMiddleware = async ({ ctx, request }) => {
  // This should run for both pages AND actions
  ctx.session = await sessions.load(request);

  if (!ctx.session) {
    throw new ErrorResponse(401, "Unauthorized");
  }
};

// No changes needed - actions need sessions too!
```

**When to use `isAction`:**

✅ **Use `isAction` to skip middleware when:**
- Logging page views (actions aren't page views)
- Setting page-specific headers (CSP, cache headers)
- Page-level redirects (auth redirects should use route handlers)
- Analytics tracking (track page views, not actions)

❌ **Don't skip middleware for:**
- Authentication/session loading (actions need auth too!)
- Security headers (actions need security)
- Database connection setup (actions use database)
- Error handling (actions can have errors)

**Complete example:**

```typescript title="src/worker.tsx"
import { defineApp } from "rwsdk/worker";

export default defineApp([
  // Session middleware - runs for everything
  async ({ ctx, request }) => {
    ctx.session = await sessions.load(request);
  },

  // Page logging - skips actions
  ({ isAction, request }) => {
    if (isAction) return;
    console.log('Page view:', new URL(request.url).pathname);
  },

  // Analytics - skips actions
  ({ isAction, request }) => {
    if (isAction) return;
    analytics.trackPageView(request);
  },

  // Routes...
]);
```

### 5. Update Response Header Usage

**Breaking Change:** The `headers` property was removed from request context.

Use `response.headers` instead of `headers` to set response headers.

**Before (0.x):**

```typescript
const myMiddleware = (requestInfo) => {
  requestInfo.headers.set('X-Custom-Header', 'my-value');
};
```

**After (1.x):**

```typescript
const myMiddleware = (requestInfo) => {
  requestInfo.response.headers.set('X-Custom-Header', 'my-value');
};
```

**Common patterns:**

```typescript
// Setting security headers
const securityMiddleware = ({ response }) => {
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
};

// Setting cookies
const cookieMiddleware = ({ response }) => {
  response.headers.set(
    'Set-Cookie',
    'session=abc123; Path=/; HttpOnly; Secure; SameSite=Strict'
  );
};

// Setting CORS headers
const corsMiddleware = ({ response }) => {
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
};
```

### 6. Remove resolveSSRValue Wrapper

**Breaking Change:** The `resolveSSRValue` helper was removed.

Call SSR-only functions directly from worker code.

**Before (0.x):**

```typescript
import { env } from 'cloudflare:workers';
import { resolveSSRValue } from 'rwsdk/worker';
import { ssrSendWelcomeEmail } from '@/app/email/ssrSendWelcomeEmail';

export async function sendWelcomeEmail(formData: FormData) {
  // Had to use resolveSSRValue wrapper
  const doSendWelcomeEmail = await resolveSSRValue(ssrSendWelcomeEmail);
  const email = formData.get('email') as string;
  const { data, error } = await doSendWelcomeEmail(env.RESEND_API, email);
}
```

**After (1.x):**

```typescript
import { env } from 'cloudflare:workers';
import { ssrSendWelcomeEmail } from '@/app/email/ssrSendWelcomeEmail';

export async function sendWelcomeEmail(formData: FormData) {
  // Call directly without wrapper
  const email = formData.get('email') as string;
  const { data, error } = await ssrSendWelcomeEmail(env.RESEND_API, email);
}
```

**Why this changed:**

The wrapper was needed in 0.x to bridge client/server boundaries. React 19 and modern bundling eliminated this requirement, making the API simpler and more direct.

**Find and replace:**

Search your codebase for `resolveSSRValue` and remove all instances:

```bash
# Find all uses
grep -r "resolveSSRValue" src/

# Remove the import
# Remove the await resolveSSRValue() wrapper
# Call functions directly
```

---

## Migration Checklist

Use this checklist to ensure you've completed all required steps:

- [ ] Upgrade `rwsdk` to latest version
- [ ] Add `react`, `react-dom`, `react-server-dom-webpack` dependencies
- [ ] Add `@cloudflare/vite-plugin`, `wrangler`, `@cloudflare/workers-types` dev dependencies
- [ ] Run `pnpm install`
- [ ] Update `compatibility_date` to `2025-08-21` or later
- [ ] Run `pnpm generate` to update types
- [ ] Review all middleware functions for `isAction` compatibility
- [ ] Replace `requestInfo.headers` with `requestInfo.response.headers`
- [ ] Remove all `resolveSSRValue` wrappers
- [ ] Test authentication flows (both pages and actions)
- [ ] Test all RSC server actions
- [ ] Test middleware logic with actions
- [ ] Verify builds with `pnpm run build`
- [ ] Test locally with `pnpm run dev`
- [ ] Deploy and test in production

---

## Optional: Adopting the Passkey Addon

**Note:** This is an optional refactoring for new projects or pre-production projects.

### What Changed?

RedwoodSDK 1.x removes the `standard` starter in favor of:
- Single unified `starter` project
- Official passkey addon for authentication
- SQLite-based Durable Objects instead of D1 + Prisma

**Your existing authentication code will continue to work.** You don't need to migrate unless you want to.

### Should You Migrate?

**Migrate to passkey addon if:**
- ✅ New project
- ✅ Pre-production project with no user data
- ✅ Want to use WebAuthn/passkeys
- ✅ Want to simplify authentication stack

**Keep existing authentication if:**
- ❌ Production application with live users
- ❌ Using D1 database with Prisma
- ❌ Custom authentication requirements
- ❌ Migration complexity outweighs benefits

### Why It's Complex

The passkey addon uses:
- **SQLite-based Durable Objects** for session and user storage
- **WebAuthn** for authentication

The old `standard` starter used:
- **D1 database** with **Prisma** ORM
- **Traditional username/password** or custom auth

Migrating requires:
1. Manually moving user data from D1 to Durable Objects
2. Migrating authentication flows
3. Updating all database queries
4. Testing authentication end-to-end

This is a **significant refactoring**, not a simple upgrade.

### Migration Path (For Those Who Choose To)

If you decide to adopt the passkey addon:

1. **Read the Authentication Guide**
   - Follow the official [Authentication Guide](https://docs.rwsdk.com/core/authentication/)
   - Understand the new architecture

2. **Install the Passkey Addon**
   - Download the addon
   - Review the code (you own it)
   - Integrate into your project

3. **Migrate User Data**
   - Export users from D1 database
   - Transform to new schema
   - Import into Durable Objects
   - Test authentication

4. **Update Application Code**
   - Replace Prisma queries with Durable Object calls
   - Update authentication flows
   - Update session management
   - Test thoroughly

5. **Test Everything**
   - Authentication flows
   - Session management
   - User registration
   - Password reset (if applicable)
   - Edge cases

**Recommendation:** For production applications, keep your existing authentication. The migration effort outweighs the benefits unless you specifically want passkey authentication.

---

## Troubleshooting

### Build Errors After Upgrade

```bash
# Clear cache and rebuild
rm -rf node_modules .vite
pnpm install
pnpm run build
```

### Type Errors

```bash
# Regenerate types
pnpm generate

# Restart TypeScript server in your editor
# VS Code: Cmd+Shift+P -> "TypeScript: Restart TS Server"
```

### Middleware Not Working

Check that:
- [ ] You're using `response.headers` not `headers`
- [ ] You've added `isAction` checks where needed
- [ ] Middleware is in correct position in `defineApp` array

### Actions Failing

Check that:
- [ ] Actions have access to session/auth middleware
- [ ] You removed `resolveSSRValue` wrappers
- [ ] `compatibility_date` is set to `2025-08-21` or later

### Deployment Errors

Check that:
- [ ] All dependencies are installed
- [ ] `wrangler.jsonc` has correct `compatibility_date`
- [ ] Build succeeds locally: `pnpm run build`
- [ ] Wrangler is up to date: `pnpm add -D wrangler@latest`

---

## Getting Help

If you encounter issues during migration:

1. **Check the docs**: [https://docs.rwsdk.com](https://docs.rwsdk.com)
2. **Review examples**: [GitHub playground apps](https://github.com/redwoodjs/sdk/tree/main/playground)
3. **Join Discord**: Get help from the community
4. **File an issue**: [GitHub Issues](https://github.com/redwoodjs/sdk/issues)

---

## Summary

RedwoodSDK 1.x brings important architectural improvements:

**Required changes:**
- Update dependencies
- Set compatibility date
- Review middleware for RSC actions
- Update header usage
- Remove `resolveSSRValue` wrappers

**Optional changes:**
- Adopt passkey addon (recommended for new projects only)

After migration, you'll have:
- ✅ Better RSC action handling
- ✅ More consistent middleware behavior
- ✅ Simplified API surface
- ✅ Modern React 19 support
- ✅ Full backwards compatibility

Follow the checklist, test thoroughly, and you'll be running on 1.x in no time!
