# RedwoodSDK Authentication Reference

## Overview

RedwoodSDK provides two approaches for authentication and sessions:
1. **Passkey Addon** - High-level, standards-based passwordless authentication
2. **Session Management API** - Low-level API for custom solutions

## Request/Response Foundations

RedwoodSDK follows standard HTTP flow:
- Middleware/routes receive platform `Request`
- Return `Response` instances
- Headers/cookies read from `request.headers`
- Headers set with `requestInfo.response.headers`
- Persistent data lives on `ctx` (populated in middleware)
- Route interruptors can mutate `ctx` and short-circuit requests

## Passkey Authentication (Experimental)

Passkeys provide passwordless authentication using WebAuthn standard and biometric data (fingerprint, face scan) or PIN.

### Adding Passkey Addon

```bash
# Run this command to download addon
npx rwsdk addon passkey
```

This downloads addon files to a temporary directory and provides instructions for integration.

### Benefits

- Passwordless login
- WebAuthn standard
- Biometric authentication
- Phishing-resistant
- Bundled server and client logic

## Session Management API

### Core Concepts

The Session Management API uses Cloudflare Durable Objects for persistence. Use it for:
- User sessions
- Shopping carts
- User preferences
- Anonymous analytics
- Any session state

### Setup Steps

#### 1. Define Session Durable Object

```typescript
// src/sessions/UserSession.ts
interface SessionData {
  userId: string | null;
}

export class UserSession implements DurableObject {
  private storage: DurableObjectStorage;
  private session: SessionData | undefined = undefined;

  constructor(state: DurableObjectState) {
    this.storage = state.storage;
  }

  async getSession() {
    if (!this.session) {
      this.session = (await this.storage.get<SessionData>("session")) ?? {
        userId: null,
      };
    }
    return { value: this.session };
  }

  async saveSession(data: Partial<SessionData>) {
    this.session = { userId: data.userId ?? null };
    await this.storage.put("session", this.session);
    return this.session;
  }

  async revokeSession() {
    await this.storage.delete("session");
    this.session = undefined;
  }
}
```

#### 2. Configure Wrangler

```jsonc
// wrangler.jsonc
{
  "durable_objects": {
    "bindings": [
      { "name": "USER_SESSION_DO", "class_name": "UserSession" }
    ]
  }
}
```

Run `pnpm generate` after updating.

#### 3. Setup Session Store in Worker

```typescript
// src/worker.tsx
import { defineDurableSession } from "rwsdk/auth";
import { UserSession } from "./sessions/UserSession.js";

export const sessionStore = defineDurableSession({
  sessionDurableObject: env.USER_SESSION_DO,
});

export { UserSession };
```

### Session Store Methods

#### load(request)
Load session data from request cookie:

```typescript
const session = await sessionStore.load(request);
```

#### save(responseHeaders, data)
Save session data and set cookie:

```typescript
await sessionStore.save(requestInfo.response.headers, { userId });
```

#### remove(request, responseHeaders)
Destroy session and remove cookie:

```typescript
await sessionStore.remove(request, requestInfo.response.headers);
```

### Server Actions Pattern

#### Create Server Actions

```typescript
// src/app/actions/auth.ts
"use server";

import { sessionStore } from "../../worker.js";
import { requestInfo } from "rwsdk/worker";

export async function getCurrentUser() {
  const session = await sessionStore.load(requestInfo.request);
  return session?.userId ?? null;
}

export async function loginAction(userId: string) {
  await sessionStore.save(requestInfo.response.headers, { userId });
}

export async function logoutAction() {
  await sessionStore.remove(
    requestInfo.request,
    requestInfo.response.headers
  );
}
```

#### Create Client Component

```tsx
// src/app/components/AuthComponent.tsx
"use client";

import { useState, useEffect, useTransition } from "react";
import { loginAction, logoutAction, getCurrentUser } from "../actions/auth.js";

export function AuthComponent() {
  const [userId, setUserId] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    getCurrentUser().then(setUserId);
  }, []);

  const handleLogin = () => {
    startTransition(async () => {
      const mockUserId = "user-123";
      await loginAction(mockUserId);
      setUserId(mockUserId);
    });
  };

  const handleLogout = () => {
    startTransition(async () => {
      await logoutAction();
      setUserId(null);
    });
  };

  return (
    <div>
      {userId ? <p>Logged in as: {userId}</p> : <p>Not logged in</p>}
      <button onClick={handleLogin} disabled={isPending}>
        Login
      </button>
      <button onClick={handleLogout} disabled={isPending}>
        Logout
      </button>
    </div>
  );
}
```

## Middleware Integration

### Populate Context with Session

```tsx
// src/worker.tsx
import { defineApp, ErrorResponse } from "rwsdk/worker";
import { route } from "rwsdk/router";

export default defineApp([
  // Session middleware
  async function sessionMiddleware({ request, ctx }) {
    const session = await sessionStore.load(request);
    ctx.session = session ?? { userId: null };
  },

  // User middleware
  async function getUserMiddleware({ request, ctx }) {
    if (ctx.session?.userId) {
      ctx.user = await db.user.findUnique({
        where: { id: ctx.session.userId }
      });
    }
  },

  // Routes
  route("/dashboard", ({ ctx }) => {
    if (!ctx.session?.userId) {
      throw new ErrorResponse(401, "Unauthorized");
    }
    return new Response(`User: ${ctx.session.userId}`);
  }),
]);
```

### Route Interruptors (Per-Route Auth)

```tsx
async function requireUser({ ctx }) {
  if (!ctx.session?.userId) {
    throw new ErrorResponse(401, "Unauthorized");
  }
}

route("/dashboard", [
  requireUser,
  ({ ctx }) => {
    return new Response(`User: ${ctx.session.userId}`);
  }
]);
```

## Error Handling

### ErrorResponse

```tsx
import { ErrorResponse } from "rwsdk/worker";

// Throw to stop pipeline and return error
throw new ErrorResponse(401, "Unauthorized");
```

### Throwing Responses

```tsx
// Also stops pipeline
throw new Response("Unauthorized", { status: 401 });
```

### Redirects

```tsx
return new Response(null, {
  status: 302,
  headers: { Location: "/login" },
});
```

## Common Patterns

### Protected Route Middleware

```tsx
export async function requireAuth({ request, ctx }) {
  const session = await sessionStore.load(request);

  if (!session) {
    return Response.redirect("/login");
  }

  ctx.session = session;
}
```

### Role-Based Access

```tsx
export function hasRole(allowedRoles: string[]) {
  return async function ({ ctx }) {
    if (!ctx.session) {
      return Response.redirect("/login");
    }

    if (!allowedRoles.includes(ctx.user.role)) {
      throw new ErrorResponse(403, "Forbidden");
    }
  };
}

export const isAdmin = hasRole(["ADMIN"]);
export const isEditor = hasRole(["ADMIN", "EDITOR"]);
```

### Session with Expiry

```typescript
interface SessionData {
  userId: string | null;
  expiresAt: string;
}

export class UserSession implements DurableObject {
  async getSession() {
    if (!this.session) {
      this.session = await this.storage.get<SessionData>("session");

      // Check expiry
      if (this.session?.expiresAt) {
        const expiresAt = new Date(this.session.expiresAt);
        if (expiresAt < new Date()) {
          await this.revokeSession();
          return { value: null };
        }
      }
    }
    return { value: this.session };
  }

  async saveSession(data: Partial<SessionData>) {
    // Set expiry (e.g., 7 days)
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    this.session = {
      userId: data.userId ?? null,
      expiresAt: expiresAt.toISOString(),
    };

    await this.storage.put("session", this.session);
    return this.session;
  }
}
```

### Multi-Factor Auth Pattern

```tsx
interface SessionData {
  userId: string | null;
  mfaVerified: boolean;
}

export async function requireMFA({ ctx }) {
  if (!ctx.session?.userId) {
    return Response.redirect("/login");
  }

  if (!ctx.session.mfaVerified) {
    return Response.redirect("/mfa-verify");
  }
}

route("/sensitive-data", [requireMFA, SensitiveDataPage]);
```

### Remember Me Pattern

```typescript
async saveSession(data: Partial<SessionData>, rememberMe: boolean) {
  const expiresAt = new Date();

  if (rememberMe) {
    expiresAt.setDate(expiresAt.getDate() + 30); // 30 days
  } else {
    expiresAt.setHours(expiresAt.getHours() + 24); // 24 hours
  }

  this.session = {
    userId: data.userId ?? null,
    expiresAt: expiresAt.toISOString(),
  };

  await this.storage.put("session", this.session);
  return this.session;
}
```

## Best Practices

1. **Use Middleware** - Populate ctx in middleware, not in routes
2. **Type Safety** - Define SessionData interface
3. **Error Handling** - Use ErrorResponse for consistent errors
4. **Secure Cookies** - Session cookies are signed by default
5. **Session Expiry** - Implement expiration logic
6. **Logout Cleanup** - Always call revokeSession on logout
7. **HTTPS Only** - Always use HTTPS in production
8. **CSRF Protection** - Implement CSRF tokens for forms

## Security Considerations

1. **Cookie Security**
   - Cookies are httpOnly by default
   - Use secure flag in production
   - Set appropriate SameSite policy

2. **Session Storage**
   - Data persists in Durable Objects
   - Implement session expiry
   - Clear sensitive data on logout

3. **Authentication**
   - Use Passkeys for passwordless auth
   - Implement rate limiting
   - Use MFA for sensitive operations

4. **Authorization**
   - Check permissions in middleware
   - Use role-based access control
   - Validate user actions server-side

## Further Reading

- [Cloudflare Durable Objects](https://developers.cloudflare.com/durable-objects/)
- [WebAuthn Standard](https://webauthn.guide/)
- [Passkey Resources](https://passkeys.dev/)
