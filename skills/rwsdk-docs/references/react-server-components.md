# RedwoodSDK React Server Components Reference

## Core Concepts

RedwoodSDK uses React Server Components (RSC) for building UIs. By default, all components are server components that render on the server as HTML and stream to the client.

## Server Components (Default)

All components are server components unless marked with `"use client"`:

```tsx
export default function MyServerComponent() {
  return <div>Hello, from the server!</div>;
}
```

Server components:
- Render on the server as HTML
- Stream to the client
- Cannot include client-side interactivity (state, effects, event handlers)
- Can directly fetch data
- Can be async
- Can be wrapped in Suspense boundaries

## Client Components

Mark with `"use client"` directive for interactivity:

```tsx
"use client";

export default function MyClientComponent() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}
```

Use client components when you need:
- Interactivity (click handlers, state)
- Browser APIs
- Event listeners
- Client-side effects
- Client-side routing

## Data Fetching in Server Components

Server components can directly fetch data:

```tsx
export async function Todos({ ctx }) {
  const todos = await db.todo.findMany({
    where: { userId: ctx.user.id }
  });

  return (
    <ol>
      {todos.map((todo) => (
        <li key={todo.id}>{todo.title}</li>
      ))}
    </ol>
  );
}

export async function TodoPage({ ctx }) {
  return (
    <div>
      <h1>Todos</h1>
      <Suspense fallback={<div>Loading...</div>}>
        <Todos ctx={ctx} />
      </Suspense>
    </div>
  );
}
```

Key points:
- Use async/await directly in components
- Wrap async components in Suspense for loading states
- Pass `ctx` through props to child components

## Server Functions

Execute server code from client components with `"use server"`:

```tsx
"use server";

import { requestInfo } from "rwsdk/worker";

export async function addTodo(formData: FormData) {
  const { ctx } = requestInfo;
  const title = formData.get("title");

  await db.todo.create({
    data: {
      title,
      userId: ctx.user.id
    }
  });
}
```

Use in client components:

```tsx
"use client";

import { addTodo } from "./functions";

export default function AddTodo() {
  return (
    <form action={addTodo}>
      <input type="text" name="title" />
      <button type="submit">Add</button>
    </form>
  );
}
```

## Context in Server Functions

Access request context via `requestInfo`:

```tsx
"use server";

import { requestInfo } from "rwsdk/worker";

export async function myServerFunction() {
  const { request, response, ctx } = requestInfo;

  // Use ctx populated by middleware
  const userId = ctx.user.id;

  // ... server logic
}
```

## Returning Responses from Server Functions

Server functions can return `Response` objects for redirects:

```tsx
"use server";

export async function addTodo(formData: FormData) {
  // ... logic to add todo

  // Redirect after success
  return Response.redirect("/todos", 303);
}
```

### Intercepting Action Responses

Handle responses on the client:

```tsx
// src/entry.client.tsx
import { initClient } from "rwsdk/client";

initClient({
  onActionResponse: (response) => {
    console.log("Action returned status:", response.status);

    // Return true to prevent default redirect behavior
    // return true;
  },
});
```

## Manual Rendering (Experimental)

### renderToStream()

Render components to a ReadableStream:

```tsx
import { renderToStream } from "rwsdk/router";

const stream = await renderToStream(<NotFound />, {
  Document,
  injectRSCPayload: false,
  onError: (error) => console.error(error)
});

const response = new Response(stream, {
  status: 404,
});
```

Options:
- `Document` - Wrap component in document
- `injectRSCPayload` - Include RSC payload for hydration (default: false)
- `onError` - Error callback

**Note**: `renderToStream` is for generating HTML streams only. It doesn't handle Server Actions or client-side transitions. For interactive routes, use the standard `render()` function.

### renderToString()

Render components to an HTML string:

```tsx
import { renderToString } from "rwsdk/router";

const html = await renderToString(<NotFound />, {
  Document,
  injectRSCPayload: false
});

const response = new Response(html, {
  status: 404,
});
```

## Component Patterns

### Server Component with Data Fetching

```tsx
export async function UserProfile({ userId }) {
  const user = await db.user.findUnique({
    where: { id: userId }
  });

  if (!user) {
    return <div>User not found</div>;
  }

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}
```

### Client Component with Server Function

```tsx
// actions.ts
"use server";

import { requestInfo } from "rwsdk/worker";

export async function updateProfile(formData: FormData) {
  const { ctx } = requestInfo;
  const name = formData.get("name");

  await db.user.update({
    where: { id: ctx.user.id },
    data: { name }
  });
}
```

```tsx
// ProfileForm.tsx
"use client";

import { useState } from "react";
import { updateProfile } from "./actions";

export function ProfileForm({ initialName }) {
  const [name, setName] = useState(initialName);

  return (
    <form action={updateProfile}>
      <input
        type="text"
        name="name"
        value={name}
        onChange={(e) => setName(e.target.value)}
      />
      <button type="submit">Save</button>
    </form>
  );
}
```

### Mixed Server and Client Components

```tsx
// Server component (parent)
export async function TodoPage({ ctx }) {
  const todos = await db.todo.findMany({
    where: { userId: ctx.user.id }
  });

  return (
    <div>
      <h1>Todos</h1>
      <TodoList todos={todos} />
    </div>
  );
}

// Client component (child)
"use client";

export function TodoList({ todos }) {
  const [filter, setFilter] = useState("all");

  const filteredTodos = todos.filter(todo => {
    if (filter === "completed") return todo.completed;
    if (filter === "active") return !todo.completed;
    return true;
  });

  return (
    <>
      <select value={filter} onChange={(e) => setFilter(e.target.value)}>
        <option value="all">All</option>
        <option value="active">Active</option>
        <option value="completed">Completed</option>
      </select>
      <ul>
        {filteredTodos.map(todo => (
          <li key={todo.id}>{todo.title}</li>
        ))}
      </ul>
    </>
  );
}
```

## Best Practices

1. **Default to Server Components** - Use client components only when needed
2. **Keep Client Components Small** - Move server logic to server components/functions
3. **Use Suspense** - Wrap async components in Suspense boundaries
4. **Pass Context Through Props** - Don't try to access ctx directly in children
5. **Server Functions for Mutations** - Use "use server" for data mutations
6. **Streaming** - Leverage streaming for progressive rendering
7. **Type Safety** - Use TypeScript for props and return types
8. **Error Boundaries** - Handle errors appropriately in components

## Common Patterns

### Loading States with Suspense

```tsx
export async function DataPage() {
  return (
    <div>
      <h1>My Data</h1>
      <Suspense fallback={<LoadingSpinner />}>
        <AsyncDataComponent />
      </Suspense>
    </div>
  );
}
```

### Nested Suspense Boundaries

```tsx
export async function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<LoadingProfile />}>
        <UserProfile />
      </Suspense>
      <Suspense fallback={<LoadingStats />}>
        <StatsWidget />
      </Suspense>
    </div>
  );
}
```

### Form with Server Action

```tsx
"use server";

export async function submitForm(formData: FormData) {
  const { ctx } = requestInfo;

  // Validate
  const email = formData.get("email");
  if (!email) {
    return { error: "Email required" };
  }

  // Process
  await db.contact.create({
    data: { email, userId: ctx.user.id }
  });

  // Redirect
  return Response.redirect("/success", 303);
}
```

## Limitations

- Server components cannot use state, effects, or browser APIs
- Client components cannot be async
- `renderToStream` and `renderToString` don't support Server Actions
- Context must be passed through props to child components
