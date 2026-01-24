# RedwoodSDK Frontend Features Reference

This reference covers frontend-specific features in RedwoodSDK including client-side navigation, styling, layouts, metadata, error handling, and static assets.

## Table of Contents
- [Client-Side Navigation](#client-side-navigation)
- [Dark/Light Mode](#darklight-mode)
- [Documents](#documents)
- [Error Handling](#error-handling)
- [Layouts](#layouts)
- [Metadata & SEO](#metadata--seo)
- [Open Graph Images](#open-graph-images)
- [Public Assets](#public-assets)
- [Styling with Tailwind CSS](#styling-with-tailwind-css)
- [shadcn/ui Components](#shadcnui-components)

---

## Client-Side Navigation

Client-side navigation enables Single Page App (SPA) behavior - users move between pages without full-page reloads.

### Basic Setup

```tsx title="src/client.tsx"
import { initClient, initClientNavigation } from "rwsdk/client";

const { handleResponse, onHydrated } = initClientNavigation();
initClient({ handleResponse, onHydrated });
```

**How it works:**
1. Intercepts `<a href="...">` link clicks
2. Pushes new URL to browser history
3. Fetches RSC payload from server with `?__rsc` query parameter
4. Hydrates content on the client

**Important notes:**
- `onHydrated` callback is optional but recommended for prefetching
- Only same-origin links are intercepted
- Middleware still runs on every navigation
- External links and `target="_blank"` behave normally

### Scroll Behavior

```tsx title="Smooth scrolling"
initClientNavigation({
  scrollBehavior: "smooth", // "instant" (default), "smooth", or "auto"
});
```

```tsx title="Disable automatic scrolling"
initClientNavigation({
  scrollToTop: false,
});
```

```tsx title="Manual scroll restoration (for chat/feeds)"
history.scrollRestoration = "manual";
```

### Navigation Callback

```tsx title="Track analytics on navigation"
initClientNavigation({
  scrollBehavior: "auto",
  onNavigate: async () => {
    await analytics.track("page_view", { path: window.location.pathname });
  },
});
```

### Programmatic Navigation

```tsx title="Navigate after form submission"
import { navigate } from "rwsdk/client";

function handleFormSubmit(event: FormEvent) {
  event.preventDefault();
  navigate("/dashboard");
}
```

```tsx title="Replace history entry"
navigate("/account", { history: "replace" });
```

```tsx title="Custom scroll behavior"
navigate("/results", {
  info: {
    scrollBehavior: "smooth",
    scrollToTop: true,
  },
});
```

### Prefetching Routes

Prefetch routes users are likely to visit next for instant navigation.

```tsx title="Prefetch links from a page"
import { link } from "@/shared/links";

export function HomePage() {
  const aboutHref = link("/about");
  const contactHref = link("/contact");

  return (
    <>
      {/* React 19 hoists these <link> tags into <head> */}
      <link rel="x-prefetch" href={aboutHref} />
      <link rel="x-prefetch" href={contactHref} />

      <nav>
        <a href={aboutHref}>About</a>
        <a href={contactHref}>Contact</a>
      </nav>
    </>
  );
}
```

```tsx title="Prefetch dynamic routes"
export function BlogListPage({ posts }) {
  return (
    <>
      {posts.map((post) => {
        const postHref = link("/blog/:slug", { slug: post.slug });
        return (
          <article key={post.id}>
            <link rel="x-prefetch" href={postHref} />
            <a href={postHref}>
              <h2>{post.title}</h2>
            </a>
          </article>
        );
      })}
    </>
  );
}
```

**Cache Management:**
- Automatic cleanup after each navigation
- Each browser tab maintains its own cache
- Uses browser's Cache API

### API Reference

**`initClientNavigation(options?)`**

Returns: `{ handleResponse, onHydrated }`

Options:
- `scrollToTop` (boolean, default: `true`): Scroll to top after navigation
- `scrollBehavior` (`'instant' | 'smooth' | 'auto'`, default: `'instant'`): How scrolling happens
- `onNavigate` (function, optional): Callback after history push but before RSC fetch

**`navigate(href, options?)`**

Options:
- `history`: `'push'` (default) or `'replace'`
- `info.scrollToTop`: Whether to scroll to top (default: `true`)
- `info.scrollBehavior`: `'instant'` (default), `'smooth'`, or `'auto'`

---

## Dark/Light Mode

Implement dark/light mode themes using cookies and direct DOM manipulation.

### Overview

Three supported modes:
- **`dark`**: Always dark mode
- **`light`**: Always light mode
- **`system`**: Follow system preference

### Implementation Steps

**1. Read theme from cookie in worker**

```tsx title="src/worker.tsx"
import { render, route } from "rwsdk/router";
import { defineApp } from "rwsdk/worker";

export interface AppContext {
  theme?: "dark" | "light" | "system";
}

export default defineApp([
  ({ ctx, request }) => {
    const cookie = request.headers.get("Cookie");
    const match = cookie?.match(/theme=([^;]+)/);
    ctx.theme = (match?.[1] as "dark" | "light" | "system") || "system";
  },
  render(Document, [route("/", Home)]),
]);
```

**2. Create server action to set theme**

```tsx title="src/app/actions/setTheme.ts"
"use server";

import { requestInfo } from "rwsdk/worker";

export async function setTheme(theme: "dark" | "light" | "system") {
  requestInfo.response.headers.set(
    "Set-Cookie",
    `theme=${theme}; Path=/; Max-Age=31536000; SameSite=Lax`
  );
}
```

**3. Set theme class before render to prevent FOUC**

```tsx title="src/app/Document.tsx"
import React from "react";
import { requestInfo } from "rwsdk/worker";

export const Document: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const theme = requestInfo?.ctx?.theme || "system";

  return (
    <html lang="en">
      <head>
        {/* ... meta tags ... */}
      </head>
      <body>
        {/* Script to set theme class before React hydrates */}
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                const theme = ${JSON.stringify(theme)};
                const isSystemDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
                const shouldBeDark = theme === 'dark' || (theme === 'system' && isSystemDark);
                if (shouldBeDark) {
                  document.documentElement.classList.add('dark');
                } else {
                  document.documentElement.classList.remove('dark');
                }
                document.documentElement.setAttribute('data-theme', theme);
              })();
            `,
          }}
        />
        <div id="root">{children}</div>
        <script>import("/src/client.tsx")</script>
      </body>
    </html>
  );
};
```

**4. Create theme toggle component**

```tsx title="src/app/components/ThemeToggle.tsx"
"use client";

import { useEffect, useRef, useState } from "react";
import { setTheme } from "../actions/setTheme";

type Theme = "dark" | "light" | "system";

export function ThemeToggle({ initialTheme }: { initialTheme: Theme }) {
  const [theme, setThemeState] = useState<Theme>(initialTheme);
  const isInitialMount = useRef(true);

  // Update DOM when theme changes
  useEffect(() => {
    const root = document.documentElement;
    const shouldBeDark =
      theme === "dark" ||
      (theme === "system" &&
        window.matchMedia("(prefers-color-scheme: dark)").matches);

    if (shouldBeDark) {
      root.classList.add("dark");
    } else {
      root.classList.remove("dark");
    }

    root.setAttribute("data-theme", theme);

    // Persist to cookie (skip on initial mount)
    if (!isInitialMount.current) {
      setTheme(theme).catch((error) => {
        console.error("Failed to set theme:", error);
      });
    } else {
      isInitialMount.current = false;
    }
  }, [theme]);

  // Listen for system theme changes
  useEffect(() => {
    if (theme !== "system") return;

    const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    const handleChange = () => {
      const root = document.documentElement;
      if (mediaQuery.matches) {
        root.classList.add("dark");
      } else {
        root.classList.remove("dark");
      }
    };

    mediaQuery.addEventListener("change", handleChange);
    return () => mediaQuery.removeEventListener("change", handleChange);
  }, [theme]);

  const toggleTheme = () => {
    // Cycle: system -> light -> dark -> system
    if (theme === "system") {
      setThemeState("light");
    } else if (theme === "light") {
      setThemeState("dark");
    } else {
      setThemeState("system");
    }
  };

  return (
    <button
      onClick={toggleTheme}
      className="px-4 py-2 rounded bg-gray-200 dark:bg-gray-800"
    >
      {theme === "dark" ? "☀️" : theme === "light" ? "🌙" : "💻"}
    </button>
  );
}
```

### CSS Styling

```css title="With Tailwind CSS"
@import "tailwindcss";

@custom-variant dark (&:is(.dark *));

/* Or use utility classes */
.my-component {
  @apply bg-white dark:bg-gray-900 text-black dark:text-white;
}
```

---

## Documents

Document components give complete control over HTML structure for each route.

### Basic Document

```tsx title="src/app/Document.tsx"
export const Document: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => (
  <html lang="en">
    <head>
      <meta charSet="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>RedwoodSDK App</title>
      <link rel="modulepreload" href="/src/client.tsx" />
    </head>
    <body>
      <div id="root">{children}</div>
      <script>import("/src/client.tsx")</script>
    </body>
  </html>
);
```

### Using Documents in Routes

```tsx title="src/worker.tsx"
import { defineApp } from "rwsdk/worker";
import { render, route } from "rwsdk/router";
import { Document } from "@/app/Document.tsx";
import { HomePage } from "@/app/pages/HomePage.tsx";

export default defineApp([
  render(Document, [
    route("/", HomePage),
  ])
]);
```

### Multiple Document Types

Use different Document components for different route groups:

```tsx title="src/worker.tsx"
import { StaticDocument } from "@/app/StaticDocument.tsx";
import { ApplicationDocument } from "@/app/ApplicationDocument.tsx";
import { RealtimeDocument } from "@/app/RealtimeDocument.tsx";

export default defineApp([
  // Static pages (no JS for marketing pages)
  render(StaticDocument, [
    route("/", HomePage),
    prefix("/blog", blogRoutes),
  ]),

  // Interactive application pages
  render(ApplicationDocument, [
    prefix("/app/user", userRoutes),
  ]),

  // Real-time features (WebSockets)
  render(RealtimeDocument, [
    prefix("/app/dashboard", dashboardRoutes),
  ])
]);
```

**Performance tip:** Only include JavaScript when needed. Use StaticDocument for marketing pages and blog posts.

---

## Error Handling

RedwoodSDK supports React 19's error handling APIs for production-ready error monitoring.

### Error Handler Types

**`onUncaughtError`**: Handles errors that escape error boundaries
- Errors during hydration or rendering
- Errors in `useEffect` or lifecycle hooks
- Errors during React transitions

**`onCaughtError`**: Handles errors caught by error boundaries
- Component rendering errors
- Errors in lifecycle methods
- Errors caught by `<ErrorBoundary>` components

### Basic Setup

```tsx title="src/client.tsx"
import { initClient } from "rwsdk/client";

initClient({
  hydrateRootOptions: {
    onUncaughtError: (error, errorInfo) => {
      console.error("Uncaught error:", error);
      console.error("Component stack:", errorInfo.componentStack);
    },
    onCaughtError: (error, errorInfo) => {
      console.error("Caught error:", error);
      console.error("Component stack:", errorInfo.componentStack);
    },
  },
});
```

### Universal Error Handling

Catch all client-side errors including event handlers and promise rejections:

```tsx title="src/client.tsx"
import { initClient } from "rwsdk/client";

const redirectToError = () => {
  window.location.replace("/error");
};

// 1. Catch imperative errors (event handlers, timeouts)
window.addEventListener("error", (event) => {
  console.error("Global error caught:", event.message);
  redirectToError();
});

// 2. Catch unhandled promise rejections
window.addEventListener("unhandledrejection", (event) => {
  console.error("Unhandled promise rejection:", event.reason);
  redirectToError();
});

initClient({
  hydrateRootOptions: {
    // 3. Catch React uncaught errors
    onUncaughtError: (error, errorInfo) => {
      console.error("React uncaught error:", error, errorInfo);
      redirectToError();
    },
    // 4. Catch error boundary errors
    onCaughtError: (error, errorInfo) => {
      console.error("React caught error:", error, errorInfo);
      redirectToError();
    },
  },
});
```

### Integration with Sentry

```tsx title="src/client.tsx"
import { initClient } from "rwsdk/client";
import * as Sentry from "@sentry/browser";

initClient({
  hydrateRootOptions: {
    onUncaughtError: (error, errorInfo) => {
      Sentry.captureException(error, {
        contexts: {
          react: {
            componentStack: errorInfo.componentStack,
            errorBoundary: errorInfo.errorBoundary?.constructor.name,
          },
        },
        tags: { errorType: "uncaught" },
      });
    },
    onCaughtError: (error, errorInfo) => {
      Sentry.captureException(error, {
        contexts: {
          react: {
            componentStack: errorInfo.componentStack,
          },
        },
        tags: { errorType: "caught" },
      });
    },
  },
});
```

### Server-Side Error Handling

Use `except` function for server-side errors:

```tsx title="src/worker.tsx"
import { except, route } from "rwsdk/router";
import { defineApp } from "rwsdk/worker";

export default defineApp([
  except((error) => {
    console.error("Server error:", error);
    return <ErrorPage error={error} />;
  }),

  route("/", () => <HomePage />),
]);
```

### Nested Error Handling

```tsx title="src/worker.tsx"
export default defineApp([
  // Global error handler
  except((error) => {
    return <GlobalErrorPage error={error} />;
  }),

  prefix("/api", [
    // API-specific error handler
    except((error) => {
      return Response.json(
        { error: error instanceof Error ? error.message : "API Error" },
        { status: 500 }
      );
    }),

    route("/users", async () => {
      throw new Error("Database error");
    }),
  ]),

  route("/", () => <HomePage />),
]);
```

### Best Practices

1. **Always log errors** even when sending to monitoring
2. **Include component stack** in error reports
3. **Distinguish error types** with tags
4. **Keep handlers lightweight** - don't block UI

---

## Layouts

Create shared UI layouts across routes using the `layout()` function.

### Basic Layout

```tsx title="src/app/layouts/AppLayout.tsx"
import type { LayoutProps } from "rwsdk/router";

export function AppLayout({ children, requestInfo }: LayoutProps) {
  return (
    <div className="app">
      <header>
        <nav>
          <a href="/">Home</a>
          <a href="/about">About</a>
        </nav>
      </header>
      <main>{children}</main>
      <footer>&copy; {new Date().getFullYear()}</footer>
    </div>
  );
}
```

### Using Layouts

```tsx title="src/worker.tsx"
import { layout, route, render } from "rwsdk/router";
import { AppLayout } from "./layouts/AppLayout";

export default defineApp([
  render(Document, [
    layout(AppLayout, [
      route("/", HomePage),
      route("/about", AboutPage),
    ])
  ])
]);
```

### Nested Layouts

```tsx title="src/worker.tsx"
export default defineApp([
  render(Document, [
    layout(AppLayout, [
      route("/", HomePage),
      prefix("/admin", [
        layout(AdminLayout, [
          route("/", AdminDashboard),
          route("/users", UserManagement),
        ])
      ])
    ])
  ])
]);

// Results in: <AppLayout><AdminLayout><Page /></AdminLayout></AppLayout>
```

### Layout Props

```tsx
import type { LayoutProps } from "rwsdk/router";

export function MyLayout({ children, requestInfo }: LayoutProps) {
  // children: The wrapped route content
  // requestInfo: Request context (only for server components)
}
```

**Note:** `requestInfo` is automatically omitted for client components to prevent serialization errors.

---

## Metadata & SEO

React 19 allows `<title>` and `<meta>` tags directly in components.

### Basic Meta Tags

```tsx title="src/app/pages/ProductPage.tsx"
export default function ProductPage() {
  return (
    <>
      <title>Product Name</title>
      <meta name="description" content="This is a description of our product" />
      <meta name="keywords" content="product, redwood, react" />

      <h1>Product Name</h1>
      {/* Page content */}
    </>
  );
}
```

### Complete SEO Setup

```tsx title="src/app/pages/BlogPostPage.tsx"
export default function BlogPostPage({ post }) {
  const { title, description, image, publishDate, author } = post;

  return (
    <>
      {/* Basic Meta Tags */}
      <title>{title} | My Blog</title>
      <meta name="description" content={description} />

      {/* Open Graph / Facebook */}
      <meta property="og:type" content="article" />
      <meta property="og:title" content={title} />
      <meta property="og:description" content={description} />
      <meta property="og:image" content={image.url} />
      <meta property="article:published_time" content={publishDate} />
      <meta property="article:author" content={author.name} />

      {/* Twitter */}
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content={title} />
      <meta name="twitter:description" content={description} />
      <meta name="twitter:image" content={image.url} />

      {/* Canonical URL */}
      <link rel="canonical" href={`https://mysite.com/blog/${post.slug}`} />

      <article>
        <h1>{title}</h1>
        {/* Blog post content */}
      </article>
    </>
  );
}
```

---

## Open Graph Images

Create dynamic Open Graph images for social media previews.

### Install workers-og

```bash
pnpm install workers-og
```

### Using HTML and CSS

```tsx title="src/worker.tsx"
render(Document, [
  route("/og", () => {
    const title = "Hello, World!";

    const html = `
      <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; width: 100vw; font-family: sans-serif; background: #160f29">
        <div style="display: flex; width: 100vw; padding: 40px; color: white;">
          <h1 style="font-size: 60px; font-weight: 600; margin: 0; font-family: 'Bitter'; font-weight: 500">${title}</h1>
        </div>
      </div>
    `;

    return new ImageResponse(html, {
      width: 1200,
      height: 630,
    });
  }),
]);
```

### Using React Components

```tsx title="src/app/components/Og.tsx"
const Og = ({ title }: { title: string }) => {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        height: "100vh",
        width: "100vw",
        fontFamily: "sans-serif",
        background: "#160f29",
      }}
    >
      <div style={{ display: "flex", width: "100vw", padding: 40, color: "white" }}>
        <h1 style={{ fontSize: 60, fontWeight: 600, margin: 0 }}>{title}</h1>
      </div>
    </div>
  );
};

export default Og;
```

```tsx title="src/worker.tsx"
import Og from "@/app/components/Og";

route("/og-react", () => {
  const title = "Hello, Amy!";
  const og = <Og title={title} />;

  return new ImageResponse(og, {
    width: 1200,
    height: 630,
  });
});
```

### Using OG Images

```tsx title="In your page component"
<meta property="og:image" content="/og" />
```

Test with: [Open Graph Image Tester](https://www.opengraph.xyz/)

---

## Public Assets

Serve static files like images, fonts, and documents through the public directory.

### Setup

```bash
mkdir public
```

### Directory Structure

```
public/
  images/
    logo.png
    background.jpg
  fonts/
    custom-font.woff2
  documents/
    sample.pdf
  favicon.ico
```

### Using Static Assets

```tsx title="In components"
function Header() {
  return (
    <header>
      <img src="/images/logo.png" alt="Logo" />
    </header>
  );
}
```

```css title="In CSS"
@font-face {
  font-family: "CustomFont";
  src: url("/fonts/custom-font.woff2") format("woff2");
}
```

### Favicon and Icons

```tsx title="src/app/Document.tsx"
<head>
  <link rel="icon" href="/favicon.ico" />
  <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
  <link rel="manifest" href="/manifest.json" />
</head>
```

**Security note:** All files in public directory are accessible to anyone. Don't store sensitive information.

---

## Styling with Tailwind CSS

### Installation

```bash
pnpm install tailwindcss @tailwindcss/vite
```

### Configuration

```ts title="vite.config.mts"
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";
import { redwood } from "rwsdk/vite";
import { cloudflare } from "@cloudflare/vite-plugin";

export default defineConfig({
  environments: {
    ssr: {}, // Required for Tailwind resolver
  },
  plugins: [
    cloudflare({
      viteEnvironment: { name: "worker" },
    }),
    redwood(),
    tailwindcss(),
  ],
});
```

### Create Styles

```css title="src/app/styles.css"
@import "tailwindcss";
```

### Import in Document

```tsx title="src/app/Document.tsx"
import styles from "./styles.css?url";

<head>
  <link rel="stylesheet" href={styles} />
</head>
```

### Customization

```css title="src/app/styles.css"
@import "tailwindcss";

@theme {
  --color-bg: #e4e3d4;
  --font-brand: "CustomFont", sans-serif;
}
```

### Usage

```tsx
<div className="bg-bg">
  <h1 className="text-brand">Hello World</h1>
</div>
```

---

## shadcn/ui Components

### Installation

```bash
pnpx shadcn@latest init
```

### Configuration

Update `components.json` for RedwoodSDK conventions:

```json title="components.json"
{
  "aliases": {
    "components": "@/app/components",
    "utils": "@/app/lib/utils",
    "ui": "@/app/components/ui",
    "lib": "@/app/lib",
    "hooks": "@/app/hooks"
  }
}
```

### Adding Components

```bash
# Add all components
pnpx shadcn@latest add

# Add specific component
pnpx shadcn@latest add button
```

Components are added to `src/app/components/ui/`.

### Important Notes

- Most shadcn components require `"use client"` directive
- Move `lib` directory to `app` if CLI creates it in wrong location
- Update import paths when copying from shadcn docs

### Example Usage

```tsx title="src/app/pages/HomePage.tsx"
"use client";

import { Button } from "@/app/components/ui/button";

export function HomePage() {
  return (
    <div>
      <Button onClick={() => alert("Clicked!")}>
        Click me
      </Button>
    </div>
  );
}
```

---

## Summary

This reference covers:
- **Client-side navigation** for SPA behavior with RSC
- **Dark/light mode** implementation with cookies
- **Custom documents** for different route groups
- **Error handling** with React 19 APIs and monitoring
- **Layouts** for shared UI structure
- **Metadata & SEO** using React 19 conventions
- **Open Graph images** with workers-og
- **Public assets** for static files
- **Tailwind CSS** setup and customization
- **shadcn/ui** component integration

All features work seamlessly with React Server Components and Cloudflare Workers.
