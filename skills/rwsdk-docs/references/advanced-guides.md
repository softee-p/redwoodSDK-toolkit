# RedwoodSDK Advanced Guides

Advanced topics including debugging, streaming responses, and troubleshooting common issues.

## Table of Contents
- [Debugging](#debugging)
- [React Server Function Streams](#react-server-function-streams)
- [Troubleshooting](#troubleshooting)

---

## Debugging

Set up VS Code or Cursor to debug both client-side and server-side code.

### Setup

Create `.vscode/launch.json` in your project root:

```json title=".vscode/launch.json"
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Vite App (Client)",
      "type": "chrome",
      "request": "launch",
      "url": "http://localhost:5173",
      "webRoot": "${workspaceFolder}",
      "sourceMaps": true,
      "skipFiles": ["<node_internals>/**"]
    },
    {
      "name": "Attach to Worker",
      "type": "node",
      "request": "attach",
      "port": 9229,
      "address": "localhost",
      "restart": false,
      "protocol": "inspector",
      "skipFiles": ["<node_internals>/**"],
      "localRoot": "${workspaceFolder}",
      "remoteRoot": "${workspaceFolder}",
      "sourceMaps": true
    },
    {
      "name": "Attach to Worker (Port 9299)",
      "type": "node",
      "request": "attach",
      "port": 9299,
      "address": "localhost",
      "restart": false,
      "protocol": "inspector",
      "skipFiles": ["<node_internals>/**"],
      "localRoot": "${workspaceFolder}",
      "remoteRoot": "${workspaceFolder}",
      "sourceMaps": true
    }
  ]
}
```

**Note:** This file is included by default in projects created with `create-rwsdk`.

### Debug Server-Side Code (Worker)

Debug server components, server functions, and middleware:

1. **Start dev server:**
   ```bash
   npm run dev
   ```

2. **Attach debugger:**
   - Open "Run and Debug" panel (Cmd+Shift+D / Ctrl+Shift+D)
   - Select "Attach to Worker" and press F5
   - If port 9229 is unavailable, use "Attach to Worker (Port 9299)"

3. **Set breakpoints:**
   - Place breakpoints in server-side code
   - Breakpoints hit when code executes

**Where you can debug:**
- `src/worker.tsx` - Routes and middleware
- Server components - Components without "use client"
- Server functions - Files with "use server"
- Route handlers - Functions passed to `route()`

### Debug Client-Side Code

Debug client components and browser-side logic:

1. **Ensure dev server is running**

2. **Launch debugger:**
   - Open "Run and Debug" panel
   - Select "Debug Vite App (Client)" and press F5
   - Opens new Chrome window

3. **Set breakpoints:**
   - Place breakpoints in client-side code
   - Components with "use client" directive
   - Browser event handlers

### Limitations

- **SSR debugging not fully supported**: Can't debug initial server-side rendering of components
- **Can debug:** Server components, server functions, client components after hydration
- **Alternative:** Use `console.log()` for SSR debugging

### Debugging Tips

**Server-side:**
```tsx
// Add breakpoints or console.log
route("/users/:id", ({ params }) => {
  console.log("User ID:", params.id); // Logs in terminal
  debugger; // Breaks if debugger attached
  return <UserPage userId={params.id} />;
});
```

**Client-side:**
```tsx
"use client";

export function Component() {
  console.log("Rendering"); // Logs in browser console
  debugger; // Breaks if debugger attached
  return <div>Component</div>;
}
```

**Server functions:**
```tsx
"use server";

export async function saveData(formData: FormData) {
  console.log("Form data:", formData); // Logs in terminal
  debugger; // Breaks if debugger attached
  // ... save logic
}
```

---

## React Server Function Streams

Stream partial responses from server functions to the client - useful for AI responses, large data sets, or real-time updates.

### Example: Streaming AI Responses

**Server function (returns stream):**

```tsx title="app/pages/Chat/functions.ts"
"use server";

export async function sendMessage(prompt: string) {
  console.log("Running AI with Prompt:", prompt);

  const response = await env.AI.run(
    "@cf/meta/llama-4-scout-17b-16e-instruct",
    {
      prompt,
      stream: true, // Enable streaming
    }
  );

  return response as unknown as ReadableStream;
}
```

**Client component (consumes stream):**

```tsx title="app/pages/Chat/Chat.tsx"
"use client";

import { sendMessage } from "./functions";
import { useState } from "react";
import { consumeEventStream } from "rwsdk/client";

export function Chat() {
  const [message, setMessage] = useState("");
  const [reply, setReply] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const onSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsLoading(true);
    setReply("");

    // Get stream from server function
    (await sendMessage(message)).pipeTo(
      consumeEventStream({
        onChunk: (event) => {
          setReply((prev) => {
            // Check for end of stream
            if (event.data === "[DONE]") {
              setIsLoading(false);
              return prev;
            }

            // Append new chunk to reply
            return prev + JSON.parse(event.data).response;
          });
        },
      })
    );
  };

  return (
    <div>
      <div>{reply}</div>

      <form onSubmit={onSubmit}>
        <input
          type="text"
          value={message}
          placeholder="Type a message..."
          onChange={(e) => setMessage(e.target.value)}
        />
        <button type="submit" disabled={message.length === 0 || isLoading}>
          {isLoading ? "Sending..." : "Send"}
        </button>
      </form>
    </div>
  );
}
```

### How It Works

1. **Server function returns ReadableStream**
   - Works with any streaming API (AI, databases, file processing)
   - Must return `ReadableStream`

2. **Client uses consumeEventStream**
   - Imported from `rwsdk/client`
   - Pipes stream to consumer
   - Calls `onChunk` for each chunk

3. **Update UI progressively**
   - Use React state to accumulate chunks
   - Display updates as they arrive
   - Handle completion signal

### Use Cases

**AI/LLM responses:**
```tsx
// Stream AI completions token by token
const stream = await env.AI.run(model, { prompt, stream: true });
return stream;
```

**Large data processing:**
```tsx
// Stream search results as they're found
export async function searchLargeDataset(query: string) {
  const stream = new ReadableStream({
    async start(controller) {
      for await (const result of database.search(query)) {
        controller.enqueue(JSON.stringify(result) + "\n");
      }
      controller.close();
    },
  });
  return stream;
}
```

**Progress updates:**
```tsx
// Stream progress of long-running operation
export async function processFile(fileId: string) {
  const stream = new ReadableStream({
    async start(controller) {
      for (let i = 0; i <= 100; i += 10) {
        controller.enqueue(`data: ${i}%\n\n`);
        await processChunk(fileId, i);
        await new Promise(r => setTimeout(r, 100));
      }
      controller.enqueue("data: [DONE]\n\n");
      controller.close();
    },
  });
  return stream;
}
```

### consumeEventStream API

```tsx
consumeEventStream({
  onChunk: (event: { data: string }) => void;
  onError?: (error: Error) => void;
  onComplete?: () => void;
})
```

**Parameters:**
- `onChunk`: Called for each chunk received
- `onError`: Called if stream encounters error (optional)
- `onComplete`: Called when stream finishes (optional)

**Example with error handling:**

```tsx
(await sendMessage(message)).pipeTo(
  consumeEventStream({
    onChunk: (event) => {
      setReply((prev) => prev + event.data);
    },
    onError: (error) => {
      console.error("Stream error:", error);
      setError("Failed to get response");
      setIsLoading(false);
    },
    onComplete: () => {
      console.log("Stream complete");
      setIsLoading(false);
    },
  })
);
```

### Working Example

See the [streaming AI chat example](https://github.com/redwoodjs/example-streaming-ai-chat) for a complete implementation.

---

## Troubleshooting

Common issues and solutions when building RedwoodSDK applications.

### RSC Configuration Errors

**Error:** "A client-only module was incorrectly resolved with the 'react-server' condition"

**What it means:**
Client-only modules (`rwsdk/client`, `rwsdk/__ssr`, `rwsdk/__ssr_bridge`) are being resolved with the `react-server` condition, which is incorrect.

**Why it happens:**
RedwoodSDK uses Node.js export conditions to route imports correctly:
- **Worker environment (RSC)**: Uses `react-server` condition
- **SSR environment**: Does NOT use `react-server` condition
- **Client environment**: Uses `browser` condition

**How to fix:**

1. **Check Vite configuration:**

   Let RedwoodSDK handle resolve conditions:

   ```ts title="vite.config.mts"
   // ✅ Correct - let RedwoodSDK configure
   import { redwood } from "rwsdk/vite";

   export default defineConfig({
     plugins: [redwood()],
   });
   ```

   ```ts title="vite.config.mts"
   // ❌ Wrong - overriding conditions
   export default defineConfig({
     environments: {
       ssr: {
         resolve: {
           conditions: ["react-server", "workerd"], // Incorrect!
         },
       },
     },
   });
   ```

2. **Check for incorrect imports:**

   ```tsx
   // ❌ Don't import client-only modules in server components
   import { initClient } from "rwsdk/client";

   export default function ServerComponent() {
     // This causes the error
     return <div>Server Component</div>;
   }
   ```

   ```tsx
   // ✅ Client-only imports in client components
   "use client";
   import { initClient } from "rwsdk/client";

   export default function ClientComponent() {
     return <div>Client Component</div>;
   }
   ```

3. **Try clearing cache:**

   ```bash
   rm -rf node_modules/.vite
   pnpm dev
   ```

### Directive Scan Errors

**Error:** "Directive scan failed. This often happens due to syntax errors in files using 'use client' or 'use server'"

**What it means:**
RedwoodSDK's scan of your codebase failed. The scan identifies which files are client components and server functions.

**Why it happens:**
- Syntax errors in files with directives
- MDX compilation errors
- Circular dependencies
- Import resolution issues

**How to fix:**

1. **Check for syntax errors:**

   ```tsx
   // ❌ Missing closing brace
   "use client";
   export function Component() {
     return <div>Hello
   }

   // ✅ Correct syntax
   "use client";
   export function Component() {
     return <div>Hello</div>;
   }
   ```

2. **Check MDX files:**

   ```bash
   # Test MDX compilation
   npx @mdx-js/mdx compile src/pages/page.mdx
   ```

3. **Check for circular dependencies:**

   ```tsx
   // ❌ Circular dependency
   // FileA.tsx
   import { ComponentB } from "./FileB";

   // FileB.tsx
   import { ComponentA } from "./FileA"; // Circular!
   ```

4. **Enable verbose logging:**

   ```bash
   VERBOSE=1 pnpm dev
   ```

5. **Run TypeScript check:**

   ```bash
   npx tsc --noEmit
   ```

### Request Context Errors

**Error:** "Request context not found. getRequestInfo() can only be called within the request lifecycle"

**What it means:**
You're trying to access request context outside of a request. Request context is only available during HTTP request handling.

**Not available in:**
- Module-level code (top of files)
- Queue handlers (background tasks)
- Cron triggers (scheduled tasks)
- Client components
- Delayed callbacks (`setTimeout`, etc.)

**How to fix:**

1. **Use requestInfo as props in server components:**

   ```tsx
   // ❌ Don't call getRequestInfo()
   import { getRequestInfo } from "rwsdk/worker";

   export default function MyPage() {
     const requestInfo = getRequestInfo(); // Error!
     return <div>{requestInfo.request.url}</div>;
   }
   ```

   ```tsx
   // ✅ Use props
   import type { RequestInfo } from "rwsdk/worker";

   export default function MyPage({ request }: RequestInfo) {
     const url = new URL(request.url);
     return <div>{url.pathname}</div>;
   }
   ```

2. **In route handlers - use parameter:**

   ```tsx
   // ✅ requestInfo is the parameter
   import { route } from "rwsdk/router";

   route("/users/:id", ({ params, request, ctx }) => {
     // Use params, request, ctx directly
     return <UserPage userId={params.id} />;
   });
   ```

3. **In server functions - use requestInfo import:**

   ```tsx
   // ✅ Use requestInfo import (not getRequestInfo())
   "use server";
   import { requestInfo } from "rwsdk/worker";

   export async function myAction() {
     const { ctx, params } = requestInfo;
     // ... your code
   }
   ```

4. **Capture values before callbacks:**

   ```tsx
   // ❌ Context lost in callback
   "use server";
   import { getRequestInfo } from "rwsdk/worker";

   export async function myAction() {
     setTimeout(() => {
       const info = getRequestInfo(); // Error!
     }, 1000);
   }
   ```

   ```tsx
   // ✅ Capture value first
   "use server";
   import { requestInfo } from "rwsdk/worker";

   export async function myAction() {
     const userId = requestInfo.ctx.user.id; // Capture
     setTimeout(() => {
       console.log(userId); // Use captured value
     }, 1000);
   }
   ```

5. **Pass data to queue handlers:**

   ```tsx
   // ❌ No request context in queue handler
   export default {
     fetch: app.fetch,
     async queue(batch) {
       const info = getRequestInfo(); // Error!
     },
   };
   ```

   ```tsx
   // ✅ Pass data through message
   const app = defineApp([
     route("/send-email", ({ ctx }) => {
       env.QUEUE.send({
         userId: ctx.user.id,
         email: ctx.user.email,
       });
       return new Response("Queued");
     }),
   ]);

   export default {
     fetch: app.fetch,
     async queue(batch) {
       for (const message of batch.messages) {
         const { userId, email } = message.body;
         await sendEmail(email);
       }
     },
   };
   ```

### General Troubleshooting Steps

**Build errors:**
```bash
# Clear cache and rebuild
rm -rf node_modules .vite
pnpm install
pnpm run build
```

**Type errors:**
```bash
# Regenerate types
pnpm generate

# Restart TypeScript server in editor
# VS Code: Cmd+Shift+P -> "TypeScript: Restart TS Server"
```

**Development server issues:**
```bash
# Kill all node processes
killall node

# Restart dev server
pnpm dev
```

**Port already in use:**
```bash
# Use different port
pnpm dev -- --port 3000
```

### Getting Help

1. **Check documentation**: [https://docs.rwsdk.com](https://docs.rwsdk.com)
2. **Browse examples**: [GitHub playground apps](https://github.com/redwoodjs/sdk/tree/main/playground)
3. **Search issues**: [GitHub Issues](https://github.com/redwoodjs/sdk/issues)
4. **Join Discord**: Get community help
5. **File bug report**: Create detailed issue with reproduction

---

## Summary

This guide covered:

- **Debugging**: VS Code setup for client and server-side debugging
- **Streaming**: Stream responses from server functions using `consumeEventStream`
- **Troubleshooting**: Solutions for RSC config errors, directive scan failures, and request context issues

These advanced topics help you debug effectively, implement real-time features, and solve common problems when building RedwoodSDK applications.
