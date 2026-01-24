# RedwoodSDK Database Reference (rwsdk/db)

## Overview

RedwoodSDK includes a built-in database solution using SQLite Durable Objects and Kysely for type-safe SQL queries. Create isolated databases at runtime with minimal setup.

**Status**: Experimental

## Key Features

- **SQLite Durable Objects** - Each database runs in isolated Durable Object
- **Kysely** - Lightweight, type-safe SQL query builder
- **Type Inference** - Schema types inferred directly from migrations
- **Zero Setup** - No code generation required
- **Natural Isolation** - Each database instance is completely separate

## Setup

### 1. Define Migrations

```ts
// src/db/migrations.ts
import { type Migrations } from "rwsdk/db";

export const migrations = {
  "001_initial_schema": {
    async up(db) {
      return [
        await db.schema
          .createTable("todos")
          .addColumn("id", "text", (col) => col.primaryKey())
          .addColumn("text", "text", (col) => col.notNull())
          .addColumn("completed", "integer", (col) =>
            col.notNull().defaultTo(0)
          )
          .addColumn("createdAt", "text", (col) => col.notNull())
          .execute(),
      ];
    },

    async down(db) {
      await db.schema.dropTable("todos").ifExists().execute();
    },
  },
} satisfies Migrations;
```

### 2. Create Database Instance

```ts
// src/db/index.ts
import { env } from "cloudflare:workers";
import { type Database, createDb } from "rwsdk/db";
import { type migrations } from "@/db/migrations";

export type AppDatabase = Database<typeof migrations>;
export type Todo = AppDatabase["todos"];

export const db = createDb<AppDatabase>(
  env.DATABASE,
  "todo-database" // unique key for this database instance
);
```

### 3. Create Durable Object Class

```ts
// src/db/durableObject.ts
import { SqliteDurableObject } from "rwsdk/db";
import { migrations } from "@/db/migrations";

export class Database extends SqliteDurableObject {
  migrations = migrations;
}
```

### 4. Export from Worker

```ts
// src/worker.tsx
export { Database } from "@/db/durableObject";

// ... rest of worker code
```

### 5. Configure Wrangler

```jsonc
// wrangler.jsonc
{
  "durable_objects": {
    "bindings": [
      {
        "name": "DATABASE",
        "class_name": "Database",
      },
    ],
  },
  "migrations": [
    {
      "tag": "v1",
      "new_sqlite_classes": ["Database"],
    },
  ],
}
```

Run `pnpm generate` after updating wrangler.jsonc.

## Basic CRUD Operations

### Create

```ts
import { db } from "@/db";

const todo = {
  id: crypto.randomUUID(),
  text: "Finish documentation",
  completed: 0,
  createdAt: new Date().toISOString(),
};

await db.insertInto("todos").values(todo).execute();
```

### Read

```ts
// Find one
const todo = await db
  .selectFrom("todos")
  .selectAll()
  .where("id", "=", todoId)
  .executeTakeFirst();

// Find many
const todos = await db
  .selectFrom("todos")
  .selectAll()
  .where("completed", "=", 0)
  .execute();

// Find with limit
const recentTodos = await db
  .selectFrom("todos")
  .selectAll()
  .orderBy("createdAt", "desc")
  .limit(10)
  .execute();
```

### Update

```ts
await db
  .updateTable("todos")
  .set({ completed: 1 })
  .where("id", "=", todoId)
  .execute();
```

### Delete

```ts
await db
  .deleteFrom("todos")
  .where("id", "=", todoId)
  .execute();
```

## Complex Queries

### Joins

```ts
// Migrations with foreign keys
await db.schema
  .createTable("users")
  .addColumn("id", "text", (col) => col.primaryKey())
  .addColumn("username", "text", (col) => col.notNull().unique())
  .execute();

await db.schema
  .createTable("posts")
  .addColumn("id", "text", (col) => col.primaryKey())
  .addColumn("title", "text", (col) => col.notNull())
  .addColumn("userId", "text", (col) =>
    col.notNull().references("users.id")
  )
  .execute();
```

### Nested Data with jsonObjectFrom

```ts
import { jsonObjectFrom } from "kysely/helpers/sqlite";

export async function getAllPostsWithAuthors() {
  return await db
    .selectFrom("posts")
    .selectAll("posts")
    .select((eb) => [
      jsonObjectFrom(
        eb
          .selectFrom("users")
          .select(["id", "username"])
          .whereRef("users.id", "=", "posts.userId")
      ).as("author"),
    ])
    .execute();
}

// Result:
// [
//   {
//     id: "post-123",
//     title: "My First Post",
//     author: { id: "user-abc", username: "Alice" }
//   }
// ]
```

### Array of Related Data

```ts
import { jsonArrayFrom } from "kysely/helpers/sqlite";

export async function getUserWithPosts(userId: string) {
  return await db
    .selectFrom("users")
    .selectAll("users")
    .select((eb) => [
      jsonArrayFrom(
        eb
          .selectFrom("posts")
          .select(["id", "title"])
          .whereRef("posts.userId", "=", "users.id")
      ).as("posts"),
    ])
    .where("users.id", "=", userId)
    .executeTakeFirst();
}
```

## Migration Management

### When Migrations Run

- **Development**: When you start dev server
- **Production**: During deployment (initial request triggers migration)

### Migration Failures and Rollback

If a migration's `up()` fails, `down()` is automatically called to rollback changes.

**Important**: SQLite doesn't support transactional DDL, so write defensive `down()` functions:

```ts
async down(db) {
  // Use ifExists for safety
  await db.schema.dropTable("posts").ifExists().execute();
  await db.schema.dropTable("users").ifExists().execute();
}
```

### Adding Migrations

Add new migrations with sequential names:

```ts
export const migrations = {
  "001_initial_schema": {
    async up(db) { /* ... */ },
    async down(db) { /* ... */ },
  },
  "002_add_user_email": {
    async up(db) {
      return [
        await db.schema
          .alterTable("users")
          .addColumn("email", "text", (col) => col.notNull())
          .execute(),
      ];
    },
    async down(db) {
      await db.schema
        .alterTable("users")
        .dropColumn("email")
        .execute();
    },
  },
} satisfies Migrations;
```

## Seeding Database

### 1. Create Seed Script

```ts
// src/scripts/seed.ts
import { db } from "@/db";

export default async () => {
  console.log("… Seeding todos");

  // Clear existing data
  await db.deleteFrom("todos").execute();

  // Insert seed data
  await db
    .insertInto("todos")
    .values([
      {
        id: crypto.randomUUID(),
        text: "Write seed script",
        completed: 1,
        createdAt: new Date().toISOString(),
      },
      {
        id: crypto.randomUUID(),
        text: "Update documentation",
        completed: 0,
        createdAt: new Date().toISOString(),
      },
    ])
    .execute();

  console.log("✔ Finished seeding todos");
};
```

### 2. Add Script to package.json

```json
{
  "scripts": {
    "seed": "rwsdk worker-run ./src/scripts/seed.ts"
  }
}
```

### 3. Run Seed

```bash
npm run seed
```

## API Reference

### createDb()

```ts
createDb<T>(
  durableObjectNamespace: DurableObjectNamespace,
  key: string
): Database<T>
```

Creates a database instance connected to a Durable Object.

### Database<T> Type

```ts
type AppDatabase = Database<typeof migrations>;
type Todo = AppDatabase["todos"]; // Inferred table type
```

### Migrations Type

```ts
export const migrations = {
  "001_name": {
    async up(db) {
      // Schema changes
    },
    async down(db) {
      // Rollback changes
    },
  },
} satisfies Migrations;
```

### SqliteDurableObject

```ts
class YourDurableObject extends SqliteDurableObject {
  migrations = yourMigrations;
}
```

## Common Patterns

### Typed Database Functions

```ts
// src/db/queries.ts
import { db, type AppDatabase } from "@/db";

export async function createTodo(
  text: string,
  userId: string
): Promise<AppDatabase["todos"]> {
  const todo = {
    id: crypto.randomUUID(),
    text,
    userId,
    completed: 0,
    createdAt: new Date().toISOString(),
  };

  await db.insertInto("todos").values(todo).execute();
  return todo;
}

export async function getUserTodos(
  userId: string
): Promise<AppDatabase["todos"][]> {
  return await db
    .selectFrom("todos")
    .selectAll()
    .where("userId", "=", userId)
    .execute();
}
```

### Transaction-like Operations

```ts
// Multiple operations
async function createUserWithProfile(username: string, email: string) {
  const userId = crypto.randomUUID();

  await db
    .insertInto("users")
    .values({ id: userId, username })
    .execute();

  await db
    .insertInto("profiles")
    .values({ userId, email })
    .execute();

  return userId;
}
```

### Conditional Queries

```ts
let query = db.selectFrom("todos").selectAll();

if (filter === "completed") {
  query = query.where("completed", "=", 1);
}

if (search) {
  query = query.where("text", "like", `%${search}%`);
}

const results = await query.execute();
```

## Best Practices

1. **Defensive Rollbacks** - Use `ifExists()` in down() functions
2. **Sequential Naming** - Use numbered prefixes for migrations (001_, 002_)
3. **Type Inference** - Let TypeScript infer types from migrations
4. **Separate Concerns** - Keep queries in dedicated files
5. **Unique Keys** - Use meaningful database instance keys
6. **Error Handling** - Handle migration failures gracefully
7. **Seeding** - Use seed scripts for consistent dev data

## FAQ

**Q: Why SQL instead of ORM?**
A: SQL-based approach is lightweight and transferable knowledge. Works alongside ORMs.

**Q: What about latency?**
A: Durable Objects run in single location. Trade-off between simplicity and latency. Can create multiple instances for geographic distribution.

**Q: Production ready?**
A: Preview feature. Underlying technologies are production-ready, but API may evolve.

**Q: Database backups?**
A: Implement additional backup strategies for critical applications. No built-in backups like D1.

**Q: Why auto-rollback?**
A: SQLite doesn't support DDL transactions. Auto-rollback ensures database integrity after failed migrations.

## Further Reading

- [Kysely Documentation](https://kysely.dev/docs)
- [Cloudflare Durable Objects](https://developers.cloudflare.com/durable-objects/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
