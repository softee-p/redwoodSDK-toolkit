# RedwoodSDK Storage Reference (R2)

## Overview

Cloudflare R2 is an S3-compatible object storage solution that integrates natively with Cloudflare Workers and RedwoodSDK. It's global, scalable, and ideal for storing files, images, videos, and more.

## Key Features

- **S3 Compatible** - Use familiar S3 APIs
- **Global** - Available worldwide
- **Scalable** - Handle any amount of data
- **Zero Egress Fees** - No charges for data transfer
- **Local Development** - Works locally during development
- **Streaming** - Memory-efficient file handling

## Setup

### 1. Create R2 Bucket

```bash
npx wrangler r2 bucket create my-bucket
```

Output:
```
Creating bucket 'my-bucket'...
✅ Created bucket 'my-bucket' with default storage class of Standard.
```

### 2. Configure Wrangler

Add the bucket binding to `wrangler.jsonc`:

```jsonc
// wrangler.jsonc
{
  "r2_buckets": [
    {
      "bucket_name": "my-bucket",
      "binding": "R2",
    },
  ],
}
```

Run `pnpm generate` after updating.

### 3. Bucket Naming Rules

Bucket names must:
- Begin and end with alphanumeric characters
- Contain only letters (a-z), numbers (0-9), and hyphens (-)

Valid examples:
- `my-bucket`
- `user-uploads-2024`
- `app-storage`

Invalid examples:
- `My_Bucket` (no uppercase or underscores)
- `-bucket-` (can't start/end with hyphen)

## Uploading Files

### Basic Upload

```tsx
import { defineApp } from "rwsdk/worker";
import { route } from "rwsdk/router";
import { env } from "cloudflare:workers";

defineApp([
  route("/upload/", async ({ request }) => {
    const formData = await request.formData();
    const file = formData.get("file") as File;

    // Stream file directly to R2
    const r2ObjectKey = `/storage/${file.name}`;
    await env.R2.put(r2ObjectKey, file.stream(), {
      httpMetadata: {
        contentType: file.type,
      },
    });

    return Response.json({ key: r2ObjectKey });
  }),
]);
```

### Upload with Metadata

```tsx
await env.R2.put(r2ObjectKey, file.stream(), {
  httpMetadata: {
    contentType: file.type,
    contentLanguage: "en-US",
    contentDisposition: `attachment; filename="${file.name}"`,
    cacheControl: "public, max-age=31536000",
  },
  customMetadata: {
    userId: ctx.user.id,
    uploadedAt: new Date().toISOString(),
  },
});
```

### Upload with Custom Key

```tsx
const fileExtension = file.name.split(".").pop();
const customKey = `uploads/${ctx.user.id}/${crypto.randomUUID()}.${fileExtension}`;

await env.R2.put(customKey, file.stream(), {
  httpMetadata: {
    contentType: file.type,
  },
});
```

## Downloading Files

### Basic Download

```tsx
defineApp([
  route("/download/*", async ({ params }) => {
    const object = await env.R2.get("/storage/" + params.$0);

    if (object === null) {
      return new Response("Object Not Found", { status: 404 });
    }

    return new Response(object.body, {
      headers: {
        "Content-Type": object.httpMetadata?.contentType as string,
      },
    });
  }),
]);
```

### Download with Headers

```tsx
route("/download/:id", async ({ params }) => {
  const object = await env.R2.get(`files/${params.id}`);

  if (!object) {
    return new Response("File not found", { status: 404 });
  }

  return new Response(object.body, {
    headers: {
      "Content-Type": object.httpMetadata?.contentType || "application/octet-stream",
      "Content-Disposition": `attachment; filename="${object.key}"`,
      "Cache-Control": "public, max-age=3600",
    },
  });
});
```

## Listing Objects

### List All Objects

```tsx
const list = await env.R2.list();

for (const object of list.objects) {
  console.log(object.key);
}
```

### List with Prefix

```tsx
const list = await env.R2.list({
  prefix: "uploads/user-123/",
});
```

### List with Pagination

```tsx
let cursor: string | undefined;
const allObjects = [];

do {
  const list = await env.R2.list({
    cursor,
    limit: 1000,
  });

  allObjects.push(...list.objects);
  cursor = list.truncated ? list.cursor : undefined;
} while (cursor);
```

## Deleting Objects

### Delete Single Object

```tsx
await env.R2.delete("files/old-file.txt");
```

### Delete Multiple Objects

```tsx
await env.R2.delete([
  "files/file1.txt",
  "files/file2.txt",
  "files/file3.txt",
]);
```

## Getting Object Metadata

```tsx
const object = await env.R2.head("files/document.pdf");

if (object) {
  console.log({
    key: object.key,
    size: object.size,
    uploaded: object.uploaded,
    contentType: object.httpMetadata?.contentType,
    customMetadata: object.customMetadata,
  });
}
```

## Common Patterns

### File Upload Form

```tsx
// Server action
"use server";

import { requestInfo } from "rwsdk/worker";
import { env } from "cloudflare:workers";

export async function uploadFile(formData: FormData) {
  const { ctx } = requestInfo;
  const file = formData.get("file") as File;

  if (!file) {
    return { error: "No file provided" };
  }

  const key = `uploads/${ctx.user.id}/${crypto.randomUUID()}-${file.name}`;

  await env.R2.put(key, file.stream(), {
    httpMetadata: {
      contentType: file.type,
    },
    customMetadata: {
      userId: ctx.user.id,
      originalName: file.name,
      uploadedAt: new Date().toISOString(),
    },
  });

  return { key, url: `/download/${key}` };
}
```

```tsx
// Client component
"use client";

import { uploadFile } from "./actions";

export function UploadForm() {
  return (
    <form action={uploadFile}>
      <input type="file" name="file" required />
      <button type="submit">Upload</button>
    </form>
  );
}
```

### Image Upload with Validation

```tsx
"use server";

export async function uploadImage(formData: FormData) {
  const file = formData.get("image") as File;

  // Validate file type
  if (!file.type.startsWith("image/")) {
    return { error: "File must be an image" };
  }

  // Validate file size (5MB max)
  if (file.size > 5 * 1024 * 1024) {
    return { error: "File must be smaller than 5MB" };
  }

  const key = `images/${crypto.randomUUID()}.${file.type.split("/")[1]}`;

  await env.R2.put(key, file.stream(), {
    httpMetadata: {
      contentType: file.type,
      cacheControl: "public, max-age=31536000",
    },
  });

  return { key, url: `/images/${key}` };
}
```

### User File Management

```tsx
// List user's files
export async function getUserFiles(userId: string) {
  const list = await env.R2.list({
    prefix: `uploads/${userId}/`,
  });

  return list.objects.map(obj => ({
    key: obj.key,
    name: obj.customMetadata?.originalName || obj.key,
    size: obj.size,
    uploaded: obj.uploaded,
  }));
}

// Delete user's file
export async function deleteUserFile(userId: string, key: string) {
  // Verify file belongs to user
  if (!key.startsWith(`uploads/${userId}/`)) {
    throw new Error("Unauthorized");
  }

  await env.R2.delete(key);
}
```

### Pre-signed URLs (Alternative Pattern)

For direct client uploads without going through worker:

```tsx
export async function createUploadUrl(fileName: string) {
  const key = `uploads/${ctx.user.id}/${crypto.randomUUID()}-${fileName}`;

  // Generate presigned URL
  // Note: R2 presigned URLs require additional setup
  // See Cloudflare R2 docs for details

  return { key, uploadUrl: "..." };
}
```

### Backup Pattern

```tsx
export async function backupToR2(data: any, backupId: string) {
  const key = `backups/${new Date().toISOString()}/${backupId}.json`;

  await env.R2.put(
    key,
    JSON.stringify(data),
    {
      httpMetadata: {
        contentType: "application/json",
      },
      customMetadata: {
        backupId,
        createdAt: new Date().toISOString(),
      },
    }
  );

  return key;
}
```

### Public vs Private Files

```tsx
// Public file (served via worker)
route("/public/files/*", async ({ params }) => {
  const object = await env.R2.get(`public/${params.$0}`);

  if (!object) {
    return new Response("Not found", { status: 404 });
  }

  return new Response(object.body, {
    headers: {
      "Content-Type": object.httpMetadata?.contentType || "application/octet-stream",
      "Cache-Control": "public, max-age=31536000",
    },
  });
});

// Private file (requires auth)
route("/private/files/*", [
  requireAuth,
  async ({ params, ctx }) => {
    const key = `private/${ctx.user.id}/${params.$0}`;
    const object = await env.R2.get(key);

    if (!object) {
      return new Response("Not found", { status: 404 });
    }

    return new Response(object.body, {
      headers: {
        "Content-Type": object.httpMetadata?.contentType || "application/octet-stream",
        "Cache-Control": "private, max-age=3600",
      },
    });
  }
]);
```

## Streaming Considerations

RedwoodSDK uses Request/Response streaming:
- Files stream from client to R2 (no full buffering)
- Files stream from R2 to client (memory efficient)
- Handles large files without memory issues
- Chunks processed as they arrive/depart

## Best Practices

1. **Unique Keys** - Use UUIDs or timestamps to avoid conflicts
2. **Content Types** - Always set correct content type
3. **Metadata** - Use custom metadata for tracking
4. **Access Control** - Validate user permissions before operations
5. **Error Handling** - Handle missing files gracefully
6. **Cache Headers** - Set appropriate cache headers
7. **File Validation** - Validate file types and sizes
8. **Key Structure** - Use organized key patterns (e.g., `type/user/file`)

## Security Considerations

1. **Authorization** - Check user permissions before allowing access
2. **File Validation** - Validate file types and sizes
3. **Path Traversal** - Sanitize file paths and keys
4. **Content Scanning** - Consider scanning uploads for malware
5. **Rate Limiting** - Limit upload frequency
6. **CORS** - Configure CORS policies if needed

## Cost Considerations

R2 Pricing:
- **Storage** - ~$0.015/GB/month
- **Class A Operations** (write, list) - $4.50/million
- **Class B Operations** (read) - $0.36/million
- **Egress** - Free (no egress charges)

## Further Reading

- [Cloudflare R2 Documentation](https://developers.cloudflare.com/r2/)
- [R2 API Reference](https://developers.cloudflare.com/r2/api/workers/workers-api-reference/)
- [R2 Pricing](https://developers.cloudflare.com/r2/pricing/)
