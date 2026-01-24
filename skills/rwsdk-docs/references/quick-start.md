# RedwoodSDK Quick Start Guide

This guide walks through creating, developing, and deploying your first RedwoodSDK application.

## System Requirements

- [Node.js](https://nodejs.org/en/download)

## Create a New Project

Create a new RedwoodSDK project using the CLI:

```bash
# Using npm
npx create-rwsdk my-project-name

# Using pnpm
pnpm dlx create-rwsdk my-project-name

# Using yarn
yarn dlx create-rwsdk my-project-name
```

## Installation and Setup

### Install Dependencies

```bash
cd my-project-name
pnpm install  # or npm install, yarn install
```

### Run the Development Server

RedwoodSDK uses Vite as its build tool:

```bash
pnpm run dev  # or npm run dev, yarn dev
```

Expected output:

```bash
VITE v6.2.0  ready in 500 ms

➜  Local:   http://localhost:5173/
➜  Network: use --host to expose
➜  press h + enter to show help
```

### View Your Application

Open [http://localhost:5173](http://localhost:5173) in your browser to see the RedwoodSDK welcome page.

## Create Your First Route

### Understanding the Entry Point

The entry point is `src/worker.tsx`, which contains the `defineApp` function:

```tsx title="src/worker.tsx"
import { defineApp } from "rwsdk/worker";
import { route, render } from "rwsdk/router";

import { Document } from "@/app/Document";
import { Home } from "@/app/pages/Home";

export default defineApp([
  render(Document, [
    route("/", () => new Response("Hello, World!"))
  ]),
]);
```

### Add a New Route

Add a `/ping` route that returns JSX:

```tsx title="src/worker.tsx"
import { defineApp } from "rwsdk/worker";
import { route, render } from "rwsdk/router";

export default defineApp([
  render(Document, [
    route("/", () => new Response("Hello, World!")),
    route("/ping", function () {
      return <h1>Pong!</h1>;
    }),
  ]),
]);
```

Navigate to [http://localhost:5173/ping](http://localhost:5173/ping) to see "Pong!" displayed.

### JSX in Routes

RedwoodSDK has built-in support for React Server Components (RSC). You can:
- Return JSX directly from routes
- JSX is rendered on the server
- HTML is sent to the client
- No client-side JavaScript required for static content

**Example:**

```tsx
// Plain Response
route("/api/status", () => new Response("OK"));

// JSX Response (rendered on server)
route("/about", () => <h1>About Us</h1>);

// Full component
route("/profile", () => <UserProfile />);
```

## Deploy to Production

RedwoodSDK deploys to Cloudflare Workers:

```bash
pnpm run release  # or npm run release, yarn release
```

### First-Time Deployment

On first deployment, you may be asked to create a workers.dev subdomain:
1. Go to your Cloudflare dashboard
2. Open the Workers menu
3. Opening the Workers landing page automatically creates a workers.dev subdomain

### Deployment Process

The `release` command:
1. Builds your application for production
2. Optimizes assets and code
3. Deploys to Cloudflare's global network
4. Provides a URL for your deployed application

## Project Structure

After creation, your project has this structure:

```
my-project-name/
├── src/
│   ├── app/
│   │   ├── Document.tsx      # HTML document template
│   │   ├── pages/
│   │   │   └── Home.tsx       # Home page component
│   │   └── styles.css         # Global styles
│   ├── client.tsx             # Client-side entry point
│   └── worker.tsx             # Worker entry point (routes)
├── public/                    # Static assets
├── package.json
├── tsconfig.json
├── vite.config.mts
└── wrangler.toml              # Cloudflare configuration
```

## Key Concepts

### defineApp

The main function that defines your web application:

```tsx
export default defineApp([
  /* middleware */,
  /* routes */
]);
```

### Routes

Define URL patterns and their handlers:

```tsx
route("/path", handler)
```

### React Server Components

Return JSX that renders on the server:

```tsx
route("/page", () => <Component />)
```

### Document Component

Controls the HTML structure:

```tsx
<html>
  <head>{/* meta tags, links */}</head>
  <body>
    <div id="root">{children}</div>
  </body>
</html>
```

## Development Workflow

### Hot Module Replacement (HMR)

RedwoodSDK supports Vite's HMR:
- Edit files and see changes instantly
- No manual page refresh needed
- Fast feedback loop

### TypeScript Support

Full TypeScript support out of the box:
- Type checking during development
- Autocomplete in your editor
- Compile-time error catching

### Development Tools

- **Vite DevTools**: Press `h + enter` in terminal for help
- **React DevTools**: Use browser extension for React components
- **Cloudflare Dashboard**: Monitor deployments and usage

## Next Steps

After completing this quick start, explore:

1. **Core Features**
   - Routing and middleware
   - React Server Components
   - Server functions
   - Data fetching patterns

2. **Cloudflare Integration**
   - Durable Objects for state
   - R2 for object storage
   - D1 for SQL databases
   - KV for key-value storage
   - Queues for background jobs

3. **Frontend Features**
   - Client-side navigation
   - Styling with Tailwind CSS
   - Metadata and SEO
   - Error handling

4. **Authentication**
   - Passkey authentication
   - Session management
   - Protected routes

5. **Real-time Features**
   - WebSockets
   - Durable Objects
   - Bidirectional state sync

## Common Commands

```bash
# Development
pnpm run dev              # Start dev server
pnpm run build            # Build for production
pnpm run preview          # Preview production build locally

# Deployment
pnpm run release          # Deploy to Cloudflare

# Type Checking
pnpm run typecheck        # Run TypeScript type checking
```

## Troubleshooting

### Port Already in Use

If port 5173 is busy:

```bash
# Specify a different port
pnpm run dev -- --port 3000
```

### Build Errors

If you encounter build errors:

```bash
# Clear cache and rebuild
rm -rf node_modules .vite
pnpm install
pnpm run build
```

### Deployment Issues

If deployment fails:

```bash
# Check Cloudflare authentication
npx wrangler whoami

# Login if needed
npx wrangler login
```

## Resources

- **Documentation**: Full guides and API references
- **GitHub**: Example projects and playground apps
- **Community**: Discord server for help and discussions
- **Cloudflare Docs**: Platform-specific features and limits

## Summary

You've learned how to:
- ✅ Create a new RedwoodSDK project
- ✅ Run the development server
- ✅ Add routes and return responses
- ✅ Use React Server Components
- ✅ Deploy to Cloudflare Workers

RedwoodSDK combines:
- **React Server Components** for modern UI development
- **Cloudflare Workers** for global edge deployment
- **Vite** for fast development experience
- **TypeScript** for type safety

Start building full-stack applications that run at the edge!
