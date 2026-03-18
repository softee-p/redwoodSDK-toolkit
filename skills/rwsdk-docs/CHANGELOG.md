# RedwoodSDK Documentation Changelog

This changelog tracks breaking changes, new patterns, and deprecations in the official RedwoodSDK docs. When working on a project that may have been built with an older version of this skill, review the entries below to identify code that needs updating.

**How to use:** Check the project's code against each entry. If the project uses an old pattern listed under "Before", update it to the "After" pattern. Entries are ordered newest-first.

---

## 2026-02-17 — Document component: remove `<div id="root">` wrapper

The Document component no longer wraps children in a `<div id="root">`. Children render directly inside `<body>`.

**Before:**
```tsx
export const Document = ({ children }) => (
  <html>
    <head>...</head>
    <body>
      <div id="root">{children}</div>
    </body>
  </html>
);
```

**After:**
```tsx
export const Document = ({ children }) => (
  <html>
    <head>...</head>
    <body>
      {children}
    </body>
  </html>
);
```

**Files to check:** Any `Document` component (commonly `src/Document.tsx` or inline in route files). Search for `id="root"` in JSX.

---

## 2026-02-16 — Query parameters: use standard Web API

RedwoodSDK now documents the standard `URL` / `searchParams` API for accessing query parameters. There is no framework-specific query param helper — use the Web API directly.

**Pattern:**
```tsx
route("/search", ({ request }) => {
  const url = new URL(request.url);
  const name = url.searchParams.get("name");
  return <div>Hello, {name}!</div>;
});
```

**Files to check:** Any route handlers that parse query strings. Replace custom parsing with `new URL(request.url).searchParams`.

---

## 2026-02-16 — Client-side navigation is now the default recommendation

`initClientNavigation()` is now the standard way to enable SPA-like navigation. RedwoodSDK uses RSC RPC to emulate client-side navigation.

**Pattern (src/client.tsx):**
```tsx
import { initClient, initClientNavigation } from "rwsdk/client";

initClient();
initClientNavigation();
```

**Files to check:** `src/client.tsx` — ensure `initClientNavigation()` is called after `initClient()`.

---

## 2026-02-16 — Branding: "Redwood" → "RedwoodSDK"

The canonical name is now **RedwoodSDK** (one word, capital R, capital SDK). Update any user-facing text, comments, or documentation that refers to "Redwood SDK" (with space) or just "Redwood" when meaning the SDK.

---

## 2026-02-16 — New guide: Building with AI

A new `guides/build-with-ai.mdx` guide documents:
- `llms.txt` and `llms-full.txt` context files at `https://docs.rwsdk.com/llms.txt`
- Tips for AI-powered development with RedwoodSDK
- Emphasis on "Zero Magic" making code predictable for AI tools

No migration action needed — this is additive.

---

## 2026-02-10 — Dark mode playground moved to community

The dark mode playground example moved from `playground/dark-mode` to `community/playground/dark-mode` in the official repo.

**Files to check:** Any references or links to the dark mode playground path.

---

## 2026-01-27 — Initial skill version

Baseline version of the rwsdk-docs skill covering RedwoodSDK 1.x documentation. Includes all core concepts, guides, experimental features, legacy docs, and API reference.
